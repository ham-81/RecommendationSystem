"""
Seed script — populates MongoDB with demo reels, interactions, and embeddings.

Key optimizations vs. original:
- Reuses the shared MongoClient + collections from db.py (single connection pool)
- Reuses ensure_indexes() from db.py (no duplicate index creation)
- Uses bulk_write with UpdateOne operations instead of per-document update_one
  loops — reduces 36 round-trips to 3 batched calls.
- Adds error handling around all DB operations.
"""

import logging
import random
from datetime import datetime, timedelta, timezone

from pymongo import UpdateOne
from pymongo.errors import BulkWriteError, PyMongoError

from db import (
    ensure_indexes,
    interactions_collection,
    now_utc,
    reel_embeddings_collection,
    reels_collection,
    users_collection,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("seed_reels")

import os
from dotenv import load_dotenv

load_dotenv()

MODEL_NAME = os.getenv("EMBEDDING_MODEL_NAME", "multimodal_dssm")
MODEL_VERSION = os.getenv("EMBEDDING_MODEL_VERSION", "v1_seed")
EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "8"))
SAMPLES_PER_USER = int(os.getenv("INTERACTIONS_PER_USER", "4"))
SEED_RANDOM = int(os.getenv("SEED_RANDOM", "42"))

seed_docs = [
    {
        "reel_id": 1,
        "creator": "user_1",
        "caption": "Amazing reel content #reels #flutter",
        "asset_path": "assets/videos/reel1.mp4",
        "like_count": 1200,
        "comment_count": 324,
    },
    {
        "reel_id": 2,
        "creator": "user_2",
        "caption": "Street vibes and transitions #cinematic",
        "asset_path": "assets/videos/reel2.mp4",
        "like_count": 980,
        "comment_count": 211,
    },
    {
        "reel_id": 3,
        "creator": "user_3",
        "caption": "Travel edit from last weekend #travel",
        "asset_path": "assets/videos/reel3.mp4",
        "like_count": 1450,
        "comment_count": 407,
    },
    {
        "reel_id": 4,
        "creator": "user_4",
        "caption": "Quick food reel #foodie",
        "asset_path": "assets/videos/reel4.mp4",
        "like_count": 860,
        "comment_count": 155,
    },
    {
        "reel_id": 5,
        "creator": "user_5",
        "caption": "Workout motivation #fitness",
        "asset_path": "assets/videos/reel5.mp4",
        "like_count": 1090,
        "comment_count": 289,
    },
    {
        "reel_id": 6,
        "creator": "user_6",
        "caption": "Nature slow motion #nature",
        "asset_path": "assets/videos/reel6.mp4",
        "like_count": 760,
        "comment_count": 143,
    },
]


def _generate_interaction_samples(reel_docs: list[dict]) -> list[dict]:
    rng = random.Random(SEED_RANDOM)
    event_types = ["view", "view", "view", "like", "save", "share"]
    devices = ["android", "ios", "web"]
    sample_docs: list[dict] = []
    base_time = datetime(2026, 3, 24, 9, 0, tzinfo=timezone.utc)

    for user_id in range(1, len(reel_docs) + 1):
        session_id = f"session_u{user_id}_seed"
        for idx in range(1, SAMPLES_PER_USER + 1):
            reel = rng.choice(reel_docs)
            event_type = rng.choice(event_types)
            watch_time = round(rng.uniform(4.0, 26.0), 2)
            completion_ratio = round(min(1.0, watch_time / 24.0), 2)
            timestamp = base_time + timedelta(minutes=(user_id - 1) * 30 + idx * 3)

            sample_docs.append(
                {
                    "interaction_id": f"u{user_id}-r{reel['reel_id']}-{event_type}-{idx:03d}",
                    "user_id": user_id,
                    "reel_id": reel["reel_id"],
                    "event": event_type,
                    "event_type": event_type,
                    "watch_time_sec": watch_time,
                    "completion_ratio": completion_ratio,
                    "timestamp": timestamp,
                    "event_timestamp": timestamp,
                    "session_id": session_id,
                    "context": {"source": "seed-generator", "device": rng.choice(devices)},
                }
            )

    return sample_docs


def _generate_embedding_samples(reel_docs: list[dict]) -> list[dict]:
    rng = random.Random(SEED_RANDOM + 100)
    generated_at = now_utc()
    docs: list[dict] = []

    for reel in reel_docs:
        vector = [round(rng.uniform(-1.0, 1.0), 6) for _ in range(EMBEDDING_DIM)]
        norm = round(sum(value * value for value in vector) ** 0.5, 6)
        docs.append(
            {
                "reel_id": reel["reel_id"],
                "model_name": MODEL_NAME,
                "model_version": MODEL_VERSION,
                "embedding_dim": EMBEDDING_DIM,
                "embedding": vector,
                "norm": norm,
                "is_active": True,
                "updated_at": generated_at,
            }
        )

    return docs


def main() -> None:
    logger.info("Starting seed …")

    # Reuse shared indexes — no duplicate definitions
    ensure_indexes()

    # Seed default user
    try:
        users_collection.update_one(
            {"user_id": 1},
            {
                "$setOnInsert": {
                    "username": "user_1",
                    "created_at": now_utc(),
                }
            },
            upsert=True,
        )
    except PyMongoError as exc:
        logger.error("Failed to seed default user: %s", exc)
        raise

    # Generate seed data
    interaction_seed_docs = _generate_interaction_samples(seed_docs)
    embedding_seed_docs = _generate_embedding_samples(seed_docs)

    # --- Bulk upsert reels (replaces 6 individual update_one calls) ---
    reel_ops = [
        UpdateOne({"reel_id": doc["reel_id"]}, {"$set": doc}, upsert=True)
        for doc in seed_docs
    ]
    try:
        result = reels_collection.bulk_write(reel_ops, ordered=False)
        logger.info(
            "Reels: matched=%d, upserted=%d, modified=%d",
            result.matched_count, result.upserted_count, result.modified_count,
        )
    except BulkWriteError as exc:
        logger.error("Bulk write error (reels): %s", exc.details)
        raise

    # --- Bulk upsert interactions (replaces 24 individual update_one calls) ---
    interaction_ops = [
        UpdateOne({"interaction_id": doc["interaction_id"]}, {"$set": doc}, upsert=True)
        for doc in interaction_seed_docs
    ]
    try:
        result = interactions_collection.bulk_write(interaction_ops, ordered=False)
        logger.info(
            "Interactions: matched=%d, upserted=%d, modified=%d",
            result.matched_count, result.upserted_count, result.modified_count,
        )
    except BulkWriteError as exc:
        logger.error("Bulk write error (interactions): %s", exc.details)
        raise

    # --- Bulk upsert embeddings (replaces 6 individual update_one calls) ---
    embedding_ops = [
        UpdateOne(
            {
                "reel_id": doc["reel_id"],
                "model_name": doc["model_name"],
                "model_version": doc["model_version"],
            },
            {"$set": doc},
            upsert=True,
        )
        for doc in embedding_seed_docs
    ]
    try:
        result = reel_embeddings_collection.bulk_write(embedding_ops, ordered=False)
        logger.info(
            "Embeddings: matched=%d, upserted=%d, modified=%d",
            result.matched_count, result.upserted_count, result.modified_count,
        )
    except BulkWriteError as exc:
        logger.error("Bulk write error (embeddings): %s", exc.details)
        raise

    logger.info("Seed complete: %d reels, %d interactions, %d embeddings",
                len(seed_docs), len(interaction_seed_docs), len(embedding_seed_docs))


if __name__ == "__main__":
    main()
