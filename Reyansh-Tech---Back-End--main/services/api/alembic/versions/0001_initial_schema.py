"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-05-21
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Extensions
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"')

    # Updated-at trigger function
    op.execute("""
        CREATE OR REPLACE FUNCTION set_updated_at()
        RETURNS TRIGGER LANGUAGE plpgsql AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$
    """)

    # organizations
    op.create_table(
        "organizations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("name", sa.String, nullable=False),
        sa.Column("slug", sa.String, nullable=False, unique=True),
        sa.Column("org_type", sa.String, nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("metadata", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.CheckConstraint("org_type IN ('PLATFORM','POLICE','AMBULANCE','FIRE_DEPARTMENT')", name="ck_organizations_org_type"),
    )
    op.execute("""
        CREATE TRIGGER trg_organizations_updated_at
            BEFORE UPDATE ON organizations
            FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    """)
    op.create_index("idx_organizations_org_type", "organizations", ["org_type"])
    op.create_index("idx_organizations_is_active", "organizations", ["is_active"], postgresql_where=sa.text("is_active = true"))

    # users
    op.create_table(
        "users",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("organization_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("username", sa.String, nullable=False, unique=True),
        sa.Column("email", sa.String, nullable=False, unique=True),
        sa.Column("password_hash", sa.String, nullable=False),
        sa.Column("refresh_token_hash", sa.String, nullable=True),
        sa.Column("refresh_token_prefix", sa.String(10), nullable=True),
        sa.Column("refresh_token_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("role", sa.String, nullable=False),
        sa.Column("first_name", sa.String, nullable=True),
        sa.Column("last_name", sa.String, nullable=True),
        sa.Column("phone_number", sa.String, nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("must_change_password", sa.Boolean, nullable=False, server_default=sa.text("false")),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("failed_login_count", sa.Integer, nullable=False, server_default=sa.text("0")),
        sa.Column("locked_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.CheckConstraint(
            "role IN ('super_admin','support_user','data_analyst','org_admin','operator','dispatcher','viewer')",
            name="ck_users_role",
        ),
    )
    op.execute("""
        CREATE TRIGGER trg_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION set_updated_at()
    """)
    op.create_index("idx_users_organization_id", "users", ["organization_id"])
    op.create_index("idx_users_email", "users", ["email"])
    op.create_index("idx_users_refresh_token_prefix", "users", ["refresh_token_prefix"],
                    postgresql_where=sa.text("refresh_token_prefix IS NOT NULL"))

    # vehicles
    op.create_table(
        "vehicles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("organization_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("vehicle_category", sa.String, nullable=False),
        sa.Column("vin", sa.String, nullable=True, unique=True),
        sa.Column("registration_number", sa.String, nullable=True),
        sa.Column("make", sa.String, nullable=True),
        sa.Column("model", sa.String, nullable=True),
        sa.Column("year", sa.Integer, nullable=True),
        sa.Column("vehicle_type", sa.String, nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("metadata", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.CheckConstraint("vehicle_category IN ('USER_VEHICLE','EMERGENCY_VEHICLE')", name="ck_vehicles_category"),
    )
    op.execute("CREATE TRIGGER trg_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION set_updated_at()")
    op.create_index("idx_vehicles_organization_id", "vehicles", ["organization_id"])
    op.create_index("idx_vehicles_vehicle_category", "vehicles", ["vehicle_category"])
    op.create_index("idx_vehicles_org_category", "vehicles", ["organization_id", "vehicle_category"])
    op.create_index("idx_vehicles_is_active", "vehicles", ["is_active"], postgresql_where=sa.text("is_active = true"))

    # devices
    op.create_table(
        "devices",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("device_id", sa.String, nullable=False, unique=True),
        sa.Column("device_secret_hash", sa.String, nullable=False),
        sa.Column("vehicle_id", UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="SET NULL"), nullable=True),
        sa.Column("organization_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("firmware_version", sa.String, nullable=True),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("metadata", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
    )
    op.execute("CREATE TRIGGER trg_devices_updated_at BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION set_updated_at()")
    op.create_index("idx_devices_vehicle_id", "devices", ["vehicle_id"])
    op.create_index("idx_devices_organization_id", "devices", ["organization_id"])
    op.create_index("idx_devices_is_active", "devices", ["is_active"], postgresql_where=sa.text("is_active = true"))

    # trips
    op.create_table(
        "trips",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("vehicle_id", UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("driver_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("start_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("start_location", JSONB, nullable=True),
        sa.Column("end_location", JSONB, nullable=True),
        sa.Column("distance_meters", sa.Integer, nullable=True),
        sa.Column("duration_seconds", sa.Integer, nullable=True),
        sa.Column("status", sa.String, nullable=False, server_default=sa.text("'ACTIVE'")),
        sa.Column("summary", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.CheckConstraint("status IN ('ACTIVE','COMPLETED','ABORTED')", name="ck_trips_status"),
    )
    op.execute("CREATE TRIGGER trg_trips_updated_at BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION set_updated_at()")
    op.create_index("idx_trips_vehicle_id", "trips", ["vehicle_id"])
    op.create_index("idx_trips_status", "trips", ["status"])
    op.create_index("idx_trips_vehicle_start", "trips", ["vehicle_id", sa.text("start_time DESC")])

    # incidents
    op.create_table(
        "incidents",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("incident_type", sa.String, nullable=False),
        sa.Column("severity", sa.String, nullable=False),
        sa.Column("status", sa.String, nullable=False, server_default=sa.text("'OPEN'")),
        sa.Column("event_time", sa.DateTime(timezone=True), nullable=False),
        sa.Column("location", JSONB, nullable=False),
        sa.Column("created_by_org_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id"), nullable=False),
        sa.Column("created_by_user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("trip_id", UUID(as_uuid=True), sa.ForeignKey("trips.id"), nullable=True),
        sa.Column("metadata", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.CheckConstraint("severity IN ('LOW','MEDIUM','HIGH','CRITICAL')", name="ck_incidents_severity"),
        sa.CheckConstraint(
            "status IN ('OPEN','ACKNOWLEDGED','RESPONDING','RESOLVED','CLOSED','FALSE_POSITIVE')",
            name="ck_incidents_status",
        ),
    )
    op.execute("CREATE TRIGGER trg_incidents_updated_at BEFORE UPDATE ON incidents FOR EACH ROW EXECUTE FUNCTION set_updated_at()")
    op.create_index("idx_incidents_event_time", "incidents", [sa.text("event_time DESC")])
    op.create_index("idx_incidents_status", "incidents", ["status"])
    op.create_index("idx_incidents_incident_type", "incidents", ["incident_type"])
    op.create_index("idx_incidents_created_by_org", "incidents", ["created_by_org_id"])

    # incident_vehicles
    op.create_table(
        "incident_vehicles",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("incident_id", UUID(as_uuid=True), sa.ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("vehicle_id", UUID(as_uuid=True), sa.ForeignKey("vehicles.id", ondelete="RESTRICT"), nullable=False),
        sa.Column("role", sa.String, nullable=False, server_default=sa.text("'PRIMARY'")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.UniqueConstraint("incident_id", "vehicle_id", name="uq_incident_vehicles"),
    )
    op.create_index("idx_inc_veh_incident_id", "incident_vehicles", ["incident_id"])
    op.create_index("idx_inc_veh_vehicle_id", "incident_vehicles", ["vehicle_id"])

    # incident_organization_access
    op.create_table(
        "incident_organization_access",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("incident_id", UUID(as_uuid=True), sa.ForeignKey("incidents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("organization_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False),
        sa.Column("access_reason", sa.String, nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("incident_id", "organization_id", name="uq_ioa"),
    )
    op.create_index("idx_ioa_incident_id", "incident_organization_access", ["incident_id"])
    op.create_index("idx_ioa_organization_id", "incident_organization_access", ["organization_id"])
    op.create_index(
        "idx_ioa_active_grants",
        "incident_organization_access",
        ["organization_id", "incident_id"],
        postgresql_where=sa.text("revoked_at IS NULL"),
    )

    # telemetry_raw (partitioned parent — partitions created separately)
    op.execute("""
        CREATE TABLE telemetry_raw (
            id              UUID            NOT NULL DEFAULT gen_random_uuid(),
            device_id       TEXT            NOT NULL,
            event_timestamp TIMESTAMPTZ     NOT NULL,
            lat             DOUBLE PRECISION,
            lng             DOUBLE PRECISION,
            speed           FLOAT,
            rpm             INTEGER,
            temperature     FLOAT,
            battery         FLOAT,
            passenger_count INTEGER,
            raw_payload     JSONB           NOT NULL,
            received_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
            PRIMARY KEY (id, event_timestamp),
            UNIQUE (device_id, event_timestamp)
        ) PARTITION BY RANGE (event_timestamp)
    """)
    op.execute("CREATE INDEX idx_telemetry_device_time ON telemetry_raw(device_id, event_timestamp DESC)")

    # Create initial partitions for current and next month
    op.execute("""
        CREATE TABLE telemetry_raw_2026_05 PARTITION OF telemetry_raw
            FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00')
    """)
    op.execute("""
        CREATE TABLE telemetry_raw_2026_06 PARTITION OF telemetry_raw
            FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00')
    """)

    # audit_logs
    op.create_table(
        "audit_logs",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("event_name", sa.String(100), nullable=False),
        sa.Column("severity", sa.String(10), nullable=False, server_default=sa.text("'INFO'")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("org_id", UUID(as_uuid=True), sa.ForeignKey("organizations.id", ondelete="SET NULL"), nullable=True),
        sa.Column("device_id", sa.String(50), nullable=True),
        sa.Column("target_id", sa.String(100), nullable=True),
        sa.Column("target_type", sa.String(50), nullable=True),
        sa.Column("ip_address", sa.String(45), nullable=True),
        sa.Column("user_agent", sa.Text, nullable=True),
        sa.Column("metadata", JSONB, nullable=False, server_default=sa.text("'{}'")),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("NOW()")),
    )
    op.create_index("idx_audit_logs_event_name", "audit_logs", ["event_name"])
    op.create_index("idx_audit_logs_user_id", "audit_logs", ["user_id"])
    op.create_index("idx_audit_logs_org_id", "audit_logs", ["org_id"])
    op.create_index("idx_audit_logs_occurred_at", "audit_logs", [sa.text("occurred_at DESC")])


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS audit_logs CASCADE")
    op.execute("DROP TABLE IF EXISTS telemetry_raw CASCADE")
    op.execute("DROP TABLE IF EXISTS incident_organization_access CASCADE")
    op.execute("DROP TABLE IF EXISTS incident_vehicles CASCADE")
    op.execute("DROP TABLE IF EXISTS incidents CASCADE")
    op.execute("DROP TABLE IF EXISTS trips CASCADE")
    op.execute("DROP TABLE IF EXISTS devices CASCADE")
    op.execute("DROP TABLE IF EXISTS vehicles CASCADE")
    op.execute("DROP TABLE IF EXISTS users CASCADE")
    op.execute("DROP TABLE IF EXISTS organizations CASCADE")
    op.execute("DROP FUNCTION IF EXISTS set_updated_at() CASCADE")
