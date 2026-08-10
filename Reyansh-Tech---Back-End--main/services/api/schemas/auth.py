from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds

    class Config:
        json_schema_extra = {
            "example": {
                "access_token": "eyJ...",
                "refresh_token": "opaque...",
                "token_type": "bearer",
                "expires_in": 900,
            }
        }


class UserInfo(BaseModel):
    user_id: str
    email: str
    name: str | None
    org_id: str
    org_type: str
    org_name: str | None
    role: str


class LoginResponse(TokenResponse):
    user: UserInfo
