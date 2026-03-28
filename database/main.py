import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from cloudinary_client import configure_cloudinary
from db import close_db, ensure_indexes, ping_db
from logging_config import configure_logging
from routes.reels import router as reels_router

configure_logging()
logger = logging.getLogger("main")


# ---------------------------------------------------------------------------
# Lifespan — replaces deprecated @app.on_event("startup") / ("shutdown")
# ---------------------------------------------------------------------------
@asynccontextmanager
async def lifespan(application: FastAPI):
    """Startup: configure services, verify DB, create indexes.
    Shutdown: close the shared MongoClient to release the connection pool."""
    configure_cloudinary()
    ping_db()
    ensure_indexes()
    logger.info("Application startup completed")
    yield
    close_db()
    logger.info("Application shutdown completed")


app = FastAPI(title="Reels Backend API", version="1.0.0", lifespan=lifespan)
app.include_router(reels_router)


@app.get("/health")
async def health() -> dict:
    ping_db()
    return {"status": "ok"}
