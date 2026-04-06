import os
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    mongo_uri: str = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
    mongo_db: str = os.getenv("MONGO_DB", "reel_recommendation")
    api_host: str = os.getenv("API_HOST", "0.0.0.0")
    api_port: int = int(os.getenv("API_PORT", "8000"))

    cloud_name: str = os.getenv("CLOUD_NAME", "")
    cloud_api_key: str = os.getenv("API_KEY", "")
    cloud_api_secret: str = os.getenv("API_SECRET", "")
    cloud_folder: str = os.getenv("CLOUDINARY_FOLDER", "reels_app/videos")

    max_video_size_mb: int = int(os.getenv("MAX_VIDEO_SIZE_MB", "100"))


settings = Settings()
