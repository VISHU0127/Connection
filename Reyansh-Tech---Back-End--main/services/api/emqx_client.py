"""
EMQX Management API client.

Handles device credential lifecycle in EMQX's built-in password database.
All device credentials are deterministic: username=mac_address, password=sha256(mac:vehicle_id:salt).
No secrets are stored in Postgres — the platform salt is the only secret.
"""
import hashlib
import logging
from typing import Optional

import httpx

logger = logging.getLogger("api.emqx_client")

# EMQX v5 built-in database authenticator ID
_AUTHN_ID = "password_based:built_in_database"


def derive_device_password(mac: str, vehicle_id: str, salt: str) -> str:
    """
    Deterministic password derivation shared with firmware.
    Input format must be agreed with the hardware team and never changed after devices are flashed.
    """
    raw = f"{mac}:{vehicle_id}:{salt}"
    return hashlib.sha256(raw.encode()).hexdigest()


class EmqxClient:
    def __init__(self, base_url: str, api_key: str, api_secret: str):
        self._base_url = base_url.rstrip("/")
        self._auth = (api_key, api_secret)

    def _client(self) -> httpx.AsyncClient:
        return httpx.AsyncClient(
            base_url=self._base_url,
            auth=self._auth,
            timeout=10.0,
        )

    async def create_credential(self, mac: str, password_hash: str) -> None:
        """Register device authentication + ACL rules in EMQX built-in database."""
        async with self._client() as c:
            # Authentication
            resp = await c.post(
                f"/api/v5/authentication/{_AUTHN_ID}/users",
                json={"user_id": mac, "password": password_hash, "is_superuser": False},
            )
            if resp.status_code == 409:
                await self._update_credential(c, mac, password_hash)
            else:
                resp.raise_for_status()

            # Authorization — per-device topic ACL rules
            acl_rules = [
                {"topic": f"vehicle/{mac}/telemetry", "action": "publish",   "permission": "allow"},
                {"topic": f"vehicle/{mac}/event",     "action": "publish",   "permission": "allow"},
                {"topic": f"vehicle/{mac}/status",    "action": "publish",   "permission": "allow"},
                {"topic": f"vehicle/{mac}/commands",  "action": "subscribe", "permission": "allow"},
            ]
            # EMQX 5.x bulk-create expects an array; fall back to per-user PUT for
            # EMQX deployments where POST isn't available or the user already exists.
            acl_resp = await c.post(
                "/api/v5/authorization/sources/built_in_database/rules/users",
                json=[{"username": mac, "rules": acl_rules}],
            )

            if acl_resp.status_code not in (200, 201, 204, 409):
                # POST failed — try per-user PUT which creates-or-replaces
                logger.warning(
                    "emqx_acl_post_failed_trying_put",
                    extra={"mac": mac, "status": acl_resp.status_code, "detail": acl_resp.text},
                )
                acl_resp = await c.put(
                    f"/api/v5/authorization/sources/built_in_database/rules/users/{mac}",
                    json={"rules": acl_rules},
                )

            if acl_resp.status_code not in (200, 201, 204, 409):
                # ACL failure is non-fatal — device can still connect, topic isolation
                # is enforced by emqx.conf no_match=deny at the broker level.
                # Log clearly so it can be investigated without blocking onboarding.
                logger.warning(
                    "emqx_acl_creation_failed",
                    extra={"mac": mac, "status": acl_resp.status_code, "detail": acl_resp.text},
                )

        logger.info("emqx_credential_created", extra={"mac": mac})

    async def _update_credential(self, c: httpx.AsyncClient, mac: str, password_hash: str) -> None:
        resp = await c.put(
            f"/api/v5/authentication/{_AUTHN_ID}/users/{mac}",
            json={"password": password_hash},
        )
        resp.raise_for_status()
        logger.info("emqx_credential_updated", extra={"mac": mac})

    async def delete_credential(self, mac: str) -> None:
        """Remove device authentication + ACL rules from EMQX (called on deactivation)."""
        async with self._client() as c:
            auth_resp = await c.delete(f"/api/v5/authentication/{_AUTHN_ID}/users/{mac}")
            if auth_resp.status_code not in (200, 204, 404):
                auth_resp.raise_for_status()

            acl_resp = await c.delete(f"/api/v5/authorization/sources/built_in_database/rules/users/{mac}")
            if acl_resp.status_code not in (200, 204, 404):
                acl_resp.raise_for_status()

        logger.info("emqx_credential_deleted", extra={"mac": mac})

    async def list_credentials(self) -> list[str]:
        """Return list of all registered usernames (MACs) from EMQX."""
        macs: list[str] = []
        page = 1
        async with self._client() as c:
            while True:
                resp = await c.get(
                    f"/api/v5/authentication/{_AUTHN_ID}/users",
                    params={"page": page, "limit": 500},
                )
                resp.raise_for_status()
                data = resp.json()
                users = data.get("data", [])
                macs.extend(u["user_id"] for u in users)
                if len(users) < 500:
                    break
                page += 1
        return macs

    async def sync(self, active_devices: list[dict], salt: str) -> dict:
        """
        Reconcile EMQX credentials against the active devices list from Postgres.
        Each entry in active_devices must have: mac_address, vehicle_id.
        Returns a summary dict with created/deleted counts.
        """
        emqx_macs = set(await self.list_credentials())
        db_macs = {d["mac_address"] for d in active_devices if d.get("mac_address")}

        to_create = db_macs - emqx_macs
        to_delete = emqx_macs - db_macs

        created = deleted = errors = 0

        for device in active_devices:
            mac = device.get("mac_address")
            if mac not in to_create:
                continue
            vehicle_id = str(device.get("vehicle_id", ""))
            try:
                pw = derive_device_password(mac, vehicle_id, salt)
                await self.create_credential(mac, pw)
                created += 1
            except Exception as exc:
                errors += 1
                logger.error("emqx_sync_create_failed", extra={"mac": mac, "error": str(exc)})

        for mac in to_delete:
            try:
                await self.delete_credential(mac)
                deleted += 1
            except Exception as exc:
                errors += 1
                logger.error("emqx_sync_delete_failed", extra={"mac": mac, "error": str(exc)})

        logger.info("emqx_sync_complete", extra={"created": created, "deleted": deleted, "errors": errors})
        return {"created": created, "deleted": deleted, "errors": errors}
