import cloudinary
import cloudinary.uploader

from config import settings


def configure_cloudinary() -> None:
    cloudinary.config(
        cloud_name=settings.cloud_name,
        api_key=settings.cloud_api_key,
        api_secret=settings.cloud_api_secret,
        secure=True,
    )


def cloudinary_is_configured() -> bool:
    return bool(settings.cloud_name and settings.cloud_api_key and settings.cloud_api_secret)
