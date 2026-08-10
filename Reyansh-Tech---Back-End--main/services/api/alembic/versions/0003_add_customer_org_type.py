"""add CUSTOMER org_type and owner role

Revision ID: 0003
Revises: 0002
Create Date: 2026-06-05
"""
from alembic import op

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add CUSTOMER to org_type
    op.drop_constraint("ck_organizations_org_type", "organizations")
    op.create_check_constraint(
        "ck_organizations_org_type",
        "organizations",
        "org_type IN ('PLATFORM','POLICE','AMBULANCE','FIRE_DEPARTMENT','CUSTOMER')",
    )

    # Add owner to user roles
    op.drop_constraint("ck_users_role", "users")
    op.create_check_constraint(
        "ck_users_role",
        "users",
        "role IN ('super_admin','support_user','data_analyst','org_admin','operator','dispatcher','viewer','owner')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_organizations_org_type", "organizations")
    op.create_check_constraint(
        "ck_organizations_org_type",
        "organizations",
        "org_type IN ('PLATFORM','POLICE','AMBULANCE','FIRE_DEPARTMENT')",
    )

    op.drop_constraint("ck_users_role", "users")
    op.create_check_constraint(
        "ck_users_role",
        "users",
        "role IN ('super_admin','support_user','data_analyst','org_admin','operator','dispatcher','viewer')",
    )
