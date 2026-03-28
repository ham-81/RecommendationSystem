"""
Reel CRUD & feed endpoints.

Key optimizations vs. original:
- All synchronous PyMongo calls wrapped in run_in_threadpool to avoid blocking
  the async event loop.
- Single shared REEL_PROJECTION constant (defined in db.py) instead of 3
  duplicated inline dicts.
- Consistent error handling around every DB operation.
"""

import logging
from pathlib import Path
from tempfile import NamedTemporaryFile

from bson import ObjectId
from cloudinary import uploader
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.concurrency import run_in_threadpool
from pymongo.errors import PyMongoError

from cloudinary_client import cloudinary_is_configured
from config import settings
from db import REEL_PROJECTION, now_utc, recommendations_collection, reels_collection

router = APIRouter(prefix="", tags=["reels"])
logger = logging.getLogger("reels_api")

ALLOWED_EXTENSIONS = {".mp4", ".mov", ".avi"}


def _validate_video(upload: UploadFile, file_size: int) -> None:
    ext = Path(upload.filename or "").suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Invalid file format. Allowed: mp4, mov, avi",
        )

    max_bytes = settings.max_video_size_mb * 1024 * 1024
    if file_size > max_bytes:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Max {settings.max_video_size_mb} MB",
        )


@router.post("/upload-reel")
async def upload_reel(
    video: UploadFile = File(...),
    user_id: str = Form(...),
    caption: str = Form(""),
) -> dict:
    if not cloudinary_is_configured():
        raise HTTPException(status_code=500, detail="Cloudinary configuration missing")

    data = await video.read()
    _validate_video(video, len(data))

    suffix = Path(video.filename or "").suffix.lower() or ".mp4"

    with NamedTemporaryFile(delete=True, suffix=suffix) as temp_file:
        temp_file.write(data)
        temp_file.flush()

        try:
            result = await run_in_threadpool(
                uploader.upload,
                temp_file.name,
                resource_type="video",
                folder=settings.cloud_folder,
            )
        except Exception as exc:
            logger.exception("Cloudinary upload failed")
            raise HTTPException(status_code=502, detail=f"Cloudinary upload failed: {exc}") from exc

    reel_doc = {
        "user_id": user_id,
        "video_url": result.get("secure_url", ""),
        "public_id": result.get("public_id", ""),
        "caption": caption,
        "duration": result.get("duration"),
        "created_at": now_utc(),
    }

    if not reel_doc["video_url"] or not reel_doc["public_id"]:
        raise HTTPException(status_code=502, detail="Cloudinary response missing required fields")

    try:
        # run_in_threadpool prevents blocking the event loop on sync I/O
        insert_result = await run_in_threadpool(reels_collection.insert_one, reel_doc)
    except PyMongoError as exc:
        logger.exception("MongoDB insert failed")
        raise HTTPException(status_code=500, detail=f"MongoDB insert failed: {exc}") from exc

    logger.info("Reel uploaded for user_id=%s reel_id=%s", user_id, insert_result.inserted_id)
    return {
        "message": "Upload successful",
        "video_url": reel_doc["video_url"],
        "public_id": reel_doc["public_id"],
        "duration": reel_doc.get("duration"),
        "reel_id": str(insert_result.inserted_id),
    }


@router.delete("/reels/{public_id}")
async def delete_reel(public_id: str) -> dict:
    try:
        doc = await run_in_threadpool(reels_collection.find_one, {"public_id": public_id})
    except PyMongoError as exc:
        logger.exception("MongoDB find failed")
        raise HTTPException(status_code=500, detail=f"MongoDB query failed: {exc}") from exc

    if not doc:
        raise HTTPException(status_code=404, detail="Reel not found")

    try:
        destroy_result = await run_in_threadpool(
            uploader.destroy,
            public_id,
            resource_type="video",
        )
    except Exception as exc:
        logger.exception("Cloudinary delete failed")
        raise HTTPException(status_code=502, detail=f"Cloudinary delete failed: {exc}") from exc

    if destroy_result.get("result") not in {"ok", "not found"}:
        raise HTTPException(status_code=502, detail=f"Unexpected Cloudinary delete response: {destroy_result}")

    try:
        await run_in_threadpool(reels_collection.delete_one, {"_id": ObjectId(doc["_id"])})
    except PyMongoError as exc:
        logger.exception("MongoDB delete failed")
        raise HTTPException(status_code=500, detail=f"MongoDB delete failed: {exc}") from exc

    logger.info("Reel deleted public_id=%s", public_id)
    return {"message": "Reel deleted", "public_id": public_id}


@router.get("/reels")
async def list_reels(limit: int = 50) -> dict:
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 200")

    try:
        items = await run_in_threadpool(
            lambda: list(
                reels_collection.find({}, REEL_PROJECTION)
                .sort("reel_id", 1)
                .limit(limit)
            )
        )
    except PyMongoError as exc:
        logger.exception("MongoDB query failed")
        raise HTTPException(status_code=500, detail=f"MongoDB query failed: {exc}") from exc

    return {"items": items}


@router.get("/feed/{user_id}")
async def get_feed(user_id: int, limit: int = 20) -> dict:
    if limit < 1 or limit > 100:
        raise HTTPException(status_code=400, detail="limit must be between 1 and 100")

    try:
        # Fetch only the reel_ids field we need — avoid transferring full doc
        rec = await run_in_threadpool(
            reels_collection.database["recommendations"].find_one,
            {"user_id": user_id},
            {"_id": 0, "reel_ids": 1},
        )
    except PyMongoError as exc:
        logger.exception("MongoDB query failed")
        raise HTTPException(status_code=500, detail=f"MongoDB query failed: {exc}") from exc

    if rec:
        ordered_reel_ids = rec.get("reel_ids", [])[:limit]

        try:
            reels = await run_in_threadpool(
                lambda: list(
                    reels_collection.find(
                        {"reel_id": {"$in": ordered_reel_ids}},
                        REEL_PROJECTION,
                    )
                )
            )
        except PyMongoError as exc:
            logger.exception("MongoDB query failed")
            raise HTTPException(status_code=500, detail=f"MongoDB query failed: {exc}") from exc

        # Preserve ML-ranked order by re-mapping
        reel_by_id = {item["reel_id"]: item for item in reels}
        ordered = [reel_by_id[rid] for rid in ordered_reel_ids if rid in reel_by_id]
        return {"user_id": user_id, "source": "recommendations", "items": ordered}

    # Fallback: popular reels — now backed by ix_like_count_desc index
    try:
        popular = await run_in_threadpool(
            lambda: list(
                reels_collection.find({}, REEL_PROJECTION)
                .sort("like_count", -1)
                .limit(limit)
            )
        )
    except PyMongoError as exc:
        logger.exception("MongoDB query failed")
        raise HTTPException(status_code=500, detail=f"MongoDB query failed: {exc}") from exc

    return {"user_id": user_id, "source": "popular-fallback", "items": popular}
