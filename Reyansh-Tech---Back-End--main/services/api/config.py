from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    service_name: str = "api"
    log_level: str = "INFO"

    # Database — required, no default
    database_url: str
    database_pool_size: int = 20
    database_max_overflow: int = 10
    database_pool_timeout: int = 30
    database_pool_recycle: int = 1800

    # Redis — required, no default
    redis_url: str
    redis_password: str = ""

    # JWT — required, validated at startup
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_kid: str = "v1"
    jwt_access_token_expire_minutes: int = 15
    jwt_refresh_token_expire_days: int = 7

    # Bcrypt
    bcrypt_rounds: int = 12

    # Platform admin bootstrap — seeded once at startup if set
    # Password is never re-seeded; use the API to change it after first run.
    admin_email: str = ""
    admin_password: str = ""

    # EMQX Management API — required
    emqx_api_url: str                  # e.g. http://emqx-host:18083
    emqx_api_key: str
    emqx_api_secret: str

    # Shared salt for deterministic device password derivation.
    # Must match the value burned into device firmware.
    emqx_device_secret_salt: str

    # CORS — comma-separated origins
    cors_origins: str = "http://localhost:3000,http://localhost:8080"

    # Feature flags
    expose_rbac_details: bool = False

    # MQTT — simulator only; empty broker disables publishing
    mqtt_broker: str = ""
    mqtt_port: int = 1883

    class Config:
        env_file = ".env"
        case_sensitive = False

    @field_validator("jwt_secret_key")
    @classmethod
    def _check_jwt_key(cls, v: str) -> str:
        if len(v) < 32:
            raise ValueError("JWT_SECRET_KEY must be at least 32 characters")
        if "changeme" in v.lower():
            raise ValueError("JWT_SECRET_KEY must not use a placeholder value")
        return v

    @field_validator("emqx_device_secret_salt")
    @classmethod
    def _check_salt(cls, v: str) -> str:
        if len(v) < 16:
            raise ValueError("EMQX_DEVICE_SECRET_SALT must be at least 16 characters")
        if "changeme" in v.lower():
            raise ValueError("EMQX_DEVICE_SECRET_SALT must not use a placeholder value")
        return v

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


settings = Settings()
