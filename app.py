import os

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
from ml.inference.recommend import recommend

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── MongoDB ────────────────────────────────────────────────────────────────────
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
DB_NAME = os.getenv("MONGO_DB", "reel_recommendation")

client = AsyncIOMotorClient(MONGO_URI)
db = client[DB_NAME]
reels_col = db["reels"]
users_col = db["users"]
interact_col = db["interactions"]

# ── helpers ───────────────────────────────────────────────────────────────────
async def get_user_history(user_id: int) -> list:
    """
    Fetch watched reel_ids for a user from interactions collection.
    Expects documents like:
    { "user_id": 1, "reel_id": 5, ... }
    Returns list of reel_ids the user has watched.
    """
    docs = await interact_col.find({"user_id": user_id}).to_list(length=None)
    return [doc["reel_id"] for doc in docs if "reel_id" in doc]


async def get_reel_details(reel_ids: list) -> list:
    """
    Fetch full reel info from reels collection for given reel_ids.
    Ignores recommendations that do not exist yet in DB.
    """
    reels = []
    for reel_id in reel_ids:
        doc = await reels_col.find_one({"reel_id": reel_id})
        if doc:
            reels.append({
                "id":          doc["reel_id"],
                "video_url":   doc.get("video_url", doc.get("asset_path", f"assets/videos/reel{reel_id}.mp4")),
                "caption":     doc.get("caption", f"Reel {reel_id}"),
                "creator":     doc.get("creator", ""),
                "like_count":  doc.get("like_count", 0),
                "comment_count": doc.get("comment_count", 0),
            })
    return reels


# ── routes ────────────────────────────────────────────────────────────────────

@app.get("/api/reels/feed")
async def get_feed(user_id: int = None):
    # Get user history for personalized recs, or cold start
    user_history = []
    if user_id is not None:
        user_history = await get_user_history(user_id)
    recommended_ids = recommend(user_history)

    print("\n" + "="*50)
    print("🧠 ML Recommendation Engine Triggered!")
    print(f"👤 Target User ID:      {user_id}")
    print(f"📖 Database History:    {user_history}")
    print(f"🎯 Model Output Reel IDs: {recommended_ids}")
    print("="*50 + "\n")

    # Fetch real reel data from MongoDB (with Cloudinary video URLs)
    reels = await get_reel_details(recommended_ids)

    # If ML returned IDs not in DB, also fetch popular reels as fallback
    if not reels:
        cursor = reels_col.find({}, {"_id": 0}).sort("like_count", -1).limit(10)
        docs = await cursor.to_list(length=10)
        reels = [
            {
                "id":          doc.get("reel_id", i),
                "video_url":   doc.get("video_url", doc.get("asset_path", "")),
                "caption":     doc.get("caption", ""),
                "creator":     doc.get("creator", ""),
                "like_count":  doc.get("like_count", 0),
                "comment_count": doc.get("comment_count", 0),
            }
            for i, doc in enumerate(docs)
        ]

    return {"success": True, "data": reels}


@app.get("/api/recommend/{user_id}")
async def get_recommendations(user_id: int):
    """Returns just the recommended reel IDs for a user."""
    user_history = await get_user_history(user_id)
    recommended_ids = recommend(user_history)
    return {"user_id": user_id, "recommended_reels": recommended_ids}


@app.get("/health")
async def health():
    return {"status": "ok"}

from pydantic import BaseModel
from datetime import datetime, timezone

class InteractionEvent(BaseModel):
    user_id: int
    reel_id: int
    event_type: str
    watch_time_sec: float = 0.0

@app.post("/api/interact")
async def record_interaction(interaction: InteractionEvent):
    doc = interaction.dict()
    now_ts = datetime.now(timezone.utc)
    doc["timestamp"] = now_ts
    doc["event_timestamp"] = now_ts
    doc["event"] = doc["event_type"]
    doc["session_id"] = f"session_u{doc['user_id']}_live"
    doc["context"] = {"source": "live-app"}
    doc["interaction_id"] = f"u{doc['user_id']}-r{doc['reel_id']}-{doc['event_type']}-{int(now_ts.timestamp() * 1000)}"
    # Simple insert so the ML model history sees it instantly
    await interact_col.insert_one(doc)
    return {"success": True, "message": "Interaction saved"}