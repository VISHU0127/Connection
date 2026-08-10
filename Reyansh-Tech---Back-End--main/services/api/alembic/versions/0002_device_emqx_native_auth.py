"""device: replace secret hash with mac_address for EMQX native auth

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-25
"""
from alembic import op
import sqlalchemy as sa

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "devices",
        sa.Column("mac_address", sa.String(), nullable=True, unique=True),
    )
    op.create_index("idx_devices_mac_address", "devices", ["mac_address"], unique=True)
    op.drop_column("devices", "device_secret_hash")


def downgrade() -> None:
    op.add_column(
        "devices",
        sa.Column("device_secret_hash", sa.String(), nullable=False, server_default=""),
    )
    op.drop_index("idx_devices_mac_address", table_name="devices")
    op.drop_column("devices", "mac_address")
