import redis.asyncio as aioredis

from config import settings

_pool: aioredis.ConnectionPool | None = None


def get_pool() -> aioredis.ConnectionPool:
    global _pool
    if _pool is None:
        kwargs: dict = {"decode_responses": True, "max_connections": 10}
        if settings.redis_password:
            kwargs["password"] = settings.redis_password
        _pool = aioredis.ConnectionPool.from_url(settings.redis_url, **kwargs)
    return _pool


async def get_redis() -> aioredis.Redis:
    return aioredis.Redis(connection_pool=get_pool())


def make_dedicated_redis() -> aioredis.Redis:
    """
    Create a standalone Redis client with its own connection — not from the
    shared pool. Use for long-lived operations like pub/sub that would
    otherwise hold a pool connection open indefinitely.
    socket_timeout=None disables the default 5-second read timeout so the
    pub/sub listener can block indefinitely waiting for messages.
    """
    kwargs: dict = {"decode_responses": True, "socket_timeout": None}
    if settings.redis_password:
        kwargs["password"] = settings.redis_password
    return aioredis.from_url(settings.redis_url, **kwargs)
