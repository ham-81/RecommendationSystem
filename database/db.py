"""
MongoDB connection, collection references, indexes, and shared helpers.

Key optimizations:
- Connection pool tuning (maxPoolSize, timeouts) for production resilience
- Idempotent index creation (create_index is a no-op if index already exists)
- Shared projection constant to avoid duplication across routes
"""

import logging
from datetime import datetime, timezone

from pymongo import ASCENDING, DESCENDING, MongoClient
from pymongo.collection import Collection

from config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Connection — single shared client with pool tuning
# ---------------------------------------------------------------------------
client = MongoClient(
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
reels_collection: Collection = db["reels"]
recommendations_collection: Collection = db["recommendations"]
users_collection: Collection = db["users"]
interactions_collection: Collection = db["interactions"]
reel_embeddings_collection: Collection = db["reel_embeddings"]

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
def ensure_indexes() -> None:
    """Create all required indexes. Runs on every startup; create_index is a
    no-op when the index already exists with the same spec."""

    logger.info("Ensuring MongoDB indexes …")

    # --- reels ---
    reels_collection.create_index(
        [("public_id", ASCENDING)],
        unique=True,
        partialFilterExpression={"public_id": {"$exists": True, "$type": "string"}},
        name="ux_public_id",
    )
    reels_collection.create_index(
        [("reel_id", ASCENDING)],
        unique=True,
        partialFilterExpression={"reel_id": {"$exists": True, "$type": "int"}},
        name="ux_reel_id",
    )
    reels_collection.create_index(
        [("user_id", ASCENDING), ("created_at", ASCENDING)],
        name="ix_user_created",
    )
    # Supports the popular-fallback sort in GET /feed/{user_id}
    reels_collection.create_index(
        [("like_count", DESCENDING)],
        name="ix_like_count_desc",
    )

    # --- recommendations ---
    recommendations_collection.create_index(
        [("user_id", ASCENDING)], unique=True, name="ux_user_id",
    )

    # --- users ---
    users_collection.create_index(
        [("user_id", ASCENDING)], unique=True, name="ux_user_id",
    )

    # --- interactions ---
    interactions_collection.create_index(
        [("interaction_id", ASCENDING)], unique=True, name="ux_interaction_id",
    )
    interactions_collection.create_index(
        [("user_id", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_user_event_ts",
    )
    interactions_collection.create_index(
        [("reel_id", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_reel_event_ts",
    )
    interactions_collection.create_index(
        [("event_type", ASCENDING), ("event_timestamp", DESCENDING)],
        name="ix_type_event_ts",
    )
    interactions_collection.create_index(
        [("session_id", ASCENDING), ("event_timestamp", ASCENDING)],
        name="ix_session_event_ts",
    )

    # --- reel_embeddings ---
    reel_embeddings_collection.create_index(
        [("reel_id", ASCENDING), ("model_name", ASCENDING), ("model_version", ASCENDING)],
        unique=True,
        name="ux_reel_model",
    )
    reel_embeddings_collection.create_index(
        [("model_name", ASCENDING), ("is_active", ASCENDING)],
        name="ix_model_active",
    )
    reel_embeddings_collection.create_index(
        [("updated_at", DESCENDING)],
        name="ix_updated_at",
    )

    logger.info("All indexes ensured successfully")


# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------
def ping_db() -> None:
    """Lightweight admin ping to verify connectivity."""
    client.admin.command("ping")


def close_db() -> None:
    """Graceful shutdown — release connection pool."""
    client.close()
    logger.info("MongoDB connection closed")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)
