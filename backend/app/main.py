"""
FastAPI application entry point for AI Travel ShotSpot Finder.
Provides REST API endpoints for photo spot recommendations and AR guidance.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
import logging
import os

from app.database import engine, Base

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    Creates database tables on startup.
    """
    logger.info("Starting up application...")

    # Create database tables
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created successfully")

    yield

    logger.info("Shutting down application...")


# Initialize FastAPI application
app = FastAPI(
    title="AI Travel ShotSpot Finder API",
    description="Backend API for AR-based photography location recommendations",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """
    Root endpoint providing API information.
    """
    return {
        "message": "AI Travel ShotSpot Finder API",
        "version": "1.0.0",
        "status": "healthy",
        "documentation": "/docs"
    }


@app.get("/health")
async def health_check():
    """
    Health check endpoint for monitoring and load balancers.
    """
    return {
        "status": "healthy",
        "service": "ai-travel-shotspot-api"
    }


# API route imports
from app.api import spots, upload

# Register routers - IMPORTANT: Keep /api/spots for spots router
app.include_router(spots.router, prefix="/api/spots", tags=["Photo Spots"])
app.include_router(upload.router, prefix="/api", tags=["Upload"])

# Mount static files for uploaded photos
if os.path.exists("uploads/photos"):
    app.mount("/uploads/photos", StaticFiles(directory="uploads/photos"), name="photos")
    logger.info("Static files mounted at /uploads/photos")
else:
    logger.warning("uploads/photos directory does not exist, creating it...")
    os.makedirs("uploads/photos", exist_ok=True)
    app.mount("/uploads/photos", StaticFiles(directory="uploads/photos"), name="photos")

# Mount thumbnails directory
if os.path.exists("uploads/thumbnails"):
    app.mount("/uploads/thumbnails", StaticFiles(directory="uploads/thumbnails"), name="thumbnails")
    logger.info("Static files mounted at /uploads/thumbnails")
else:
    logger.warning("uploads/thumbnails directory does not exist, creating it...")
    os.makedirs("uploads/thumbnails", exist_ok=True)
    app.mount("/uploads/thumbnails", StaticFiles(directory="uploads/thumbnails"), name="thumbnails")

# Additional routers will be added in future phases:
# app.include_router(recommendations.router, prefix="/api/recommendations", tags=["Recommendations"])
# app.include_router(itinerary.router, prefix="/api/itinerary", tags=["Itinerary"])
# app.include_router(users.router, prefix="/api/users", tags=["Users"])


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8002,
        reload=True
    )