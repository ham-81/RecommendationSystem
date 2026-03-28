"""
Sync demo reels to Cloudinary and update MongoDB.

Key optimizations vs. original:
- Imports collections directly from db.py instead of re-accessing db["..."]
- Uses now_utc() helper for consistent timestamps
"""

import logging
import time
from datetime import datetime, timezone
from pathlib import Path

from cloudinary import uploader

from cloudinary_client import configure_cloudinary
from config import settings
from db import (
    ensure_indexes,
    now_utc,
    recommendations_collection,
    reels_collection,
    users_collection,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("sync_demo_reels")

DEMO_REELS = [
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


def main() -> None:
    configure_cloudinary()
    ensure_indexes()

    project_root = Path(__file__).resolve().parent.parent
    videos_root = project_root / "flutter" / "reel_recommandation" / "assets" / "videos"

    uploaded_ids = []

    for item in DEMO_REELS:
        file_path = videos_root / f"reel{item['reel_id']}.mp4"
        if not file_path.exists():
            logger.warning("Missing file: %s", file_path)
            continue

        users_collection.update_one(
            {"user_id": item["reel_id"]},
            {
                "$set": {"username": item["creator"]},
                "$setOnInsert": {"created_at": now_utc()},
            },
            upsert=True,
        )

        cloud_public_id = f"{settings.cloud_folder}/demo_reel_{item['reel_id']}"

        result = None
        for attempt in range(1, 4):
            try:
                result = uploader.upload(
                    str(file_path),
                    resource_type="video",
                    public_id=cloud_public_id,
                    overwrite=True,
                    invalidate=True,
                )
                break
            except Exception as exc:
                logger.warning(
                    "Upload failed for reel %d (attempt %d/3): %s",
                    item["reel_id"], attempt, exc,
                )
                if attempt < 3:
                    time.sleep(2)

        if not result:
            logger.warning("Could not upload reel %d after retries", item["reel_id"])
            continue

        video_url = result.get("secure_url", "")
        public_id = result.get("public_id", "")
        duration = result.get("duration")

        if not video_url or not public_id:
            logger.warning("Invalid Cloudinary response for reel %d", item["reel_id"])
            continue

        reels_collection.update_one(
            {"reel_id": item["reel_id"]},
            {
                "$set": {
                    "reel_id": item["reel_id"],
                    "user_id": str(item["reel_id"]),
                    "creator": item["creator"],
                    "caption": item["caption"],
                    "asset_path": item["asset_path"],
                    "video_url": video_url,
                    "public_id": public_id,
                    "duration": duration,
                    "like_count": item["like_count"],
                    "comment_count": item["comment_count"],
                    "source": "demo_app_sync",
                    "updated_at": now_utc(),
                },
                "$setOnInsert": {
                    "created_at": now_utc(),
                },
            },
            upsert=True,
        )

        uploaded_ids.append(item["reel_id"])
        logger.info("Linked reel %d -> %s", item["reel_id"], public_id)

    if uploaded_ids:
        recommendations_collection.update_one(
            {"user_id": 1},
            {
                "$set": {
                    "reel_ids": uploaded_ids,
                    "model_version": "demo-cloudinary-bootstrap",
                    "updated_at": now_utc(),
                }
            },
            upsert=True,
        )

    logger.info("Synced %d demo reels to Cloudinary + MongoDB", len(uploaded_ids))


if __name__ == "__main__":
    main()
