"""
MongoDB connection, collection references, indexes, and shared helpers.

Key optimizations:
- Async Motor client for non-blocking database access
- Idempotent index creation (create_index is a no-op if index already exists)
- Shared projection constant to avoid duplication across routes
"""

import logging
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import ASCENDING, DESCENDING
from pymongo.errors import OperationFailure

from config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Connection — single shared async client with pool tuning
# ---------------------------------------------------------------------------
client = AsyncIOMotorClient(
    settings.mongo_uri,
    maxPoolSize=20,                  # limit concurrent connections per pool
    minPoolSize=2,                   # keep warm connections ready
    serverSelectionTimeoutMS=5000,   # fail fast if server unreachable
    connectTimeoutMS=5000,           # TCP connect timeout
    socketTimeoutMS=30000,           # per-operation socket timeout
)

db = client[settings.mongo_db]

# ---------------------------------------------------------------------------
# Collection references
# ---------------------------------------------------------------------------
reels_collection = db["reels"]
recommendations_collection = db["recommendations"]
users_collection = db["users"]
interactions_collection = db["interactions"]
reel_embeddings_collection = db["reel_embeddings"]

# ---------------------------------------------------------------------------
# Shared projection — single source of truth for reel fields returned by API
# ---------------------------------------------------------------------------
REEL_PROJECTION = {
    "_id": 0,
    "reel_id": 1,
    "user_id": 1,
    "creator": 1,
    "caption": 1,
    "asset_path": 1,
    "video_url": 1,
    "public_id": 1,
    "duration": 1,
    "like_count": 1,
    "comment_count": 1,
}


# ---------------------------------------------------------------------------
# Index creation — idempotent, logged, no fragile drop-recreate
# ---------------------------------------------------------------------------
async def _create_index_safe(collection, keys, **kwargs) -> None:
    """Create an index and tolerate legacy name conflicts from existing DBs."""
    try:
        await collection.create_index(keys, **kwargs)
    except OperationFailure as exc:
        if exc.code == 85 and "Index already exists with a different name" in str(exc):
            logger.warning("Skipping index creation due to existing name conflict: %s", exc)
            return
        raise


async def ensure_indexes() -> None:
    """Create all required indexes. Runs on every startup; create_index is a
    no-op when the index already exists with the same spec."""

    logger.info("Ensuring MongoDB indexes …")

    # --- reels ---
    await _create_index_safe(
        reels_collection,
        [("public_id", ASCENDING)],
        unique=True,
        partialFilterExpression={"public_id": {"$exists": True, "$type": "string"}},
        name="ux_public_id",
    )
    await _create_index_safe(
        reels_collection,
        [("reel_id", ASCENDING)],
        unique=True,
        partialFilterExpression={"reel_id": {"$exists": True, "$type": "int"}},
        name="ux_reel_id",
    )
    await _create_index_safe(
        reels_collection,
        [("user_id", ASCENDING), ("created_at", ASCENDING)],
        name="ix_user_created",
    )
    # Supports the popular-fallback sort in GET /feed/{user_id}
    await _create_index_safe(
        reels_collection,
        [("like_count", DESCENDING)],
        name="ix_like_count_desc",
    )

    # --- recommendations ---
    await _create_index_safe(
        recommendations_collection,
        [("user_id", ASCENDING)], unique=True, name="ux_user_id",
    )

    # --- users ---
    await _create_index_safe(
        users_collection,
        [("user_id", ASCENDING)], unique=True, name="ux_user_id",
    )

    # --- interactions ---
    await _create_index_safe(
        interactions_collection,
        [("interaction_id", ASCENDING)], unique=True, name="ux_interaction_id",
    )
    await _create_index_safe(
        interactions_collection,
        [("user_id", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_user_event_ts",
    )
    await _create_index_safe(
        interactions_collection,
        [("reel_id", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_reel_event_ts",
    )
    await _create_index_safe(
        interactions_collection,
        [("event_type", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_type_event_ts",
    )
    await _create_index_safe(
        interactions_collection,
        [("session_id", ASCENDING), ("event_timestamp", ASCENDING)],
        name="ix_session_event_ts",
    )

    # --- reel_embeddings ---
    await _create_index_safe(
        reel_embeddings_collection,
        [("reel_id", ASCENDING), ("model_name", ASCENDING), ("model_version", ASCENDING)],
        unique=True,
        name="ux_reel_model",
    )
    await _create_index_safe(
        reel_embeddings_collection,
        [("model_name", ASCENDING), ("is_active", ASCENDING)],
        name="ix_model_active",
    )
    await _create_index_safe(
        reel_embeddings_collection,
        [("updated_at", DESCENDING)],
        name="ix_updated_at",
    )

    logger.info("All indexes ensured successfully")


# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------
async def ping_db() -> None:
    """Lightweight admin ping to verify connectivity."""
    await client.admin.command("ping")


def close_db() -> None:
    """Graceful shutdown — release connection pool."""
    client.close()
    logger.info("MongoDB connection closed")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)
