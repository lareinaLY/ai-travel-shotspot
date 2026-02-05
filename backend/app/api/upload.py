"""
API endpoints for photo upload and user-generated content.
Handles image upload, EXIF extraction, and PhotoSpot creation.
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request
from sqlalchemy.orm import Session
from PIL import Image
from PIL.ExifTags import TAGS, GPSTAGS
from typing import Optional
import os
import uuid
import socket
from datetime import datetime

from app.database import get_db
from app.models.photo_spot import PhotoSpot
from app.schemas.photo_spot import PhotoSpotResponse
from app.services.aesthetic_scorer import calculate_aesthetic_score
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

# Upload directory
UPLOAD_DIR = "uploads/photos"
THUMBNAIL_DIR = "uploads/thumbnails"
os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(THUMBNAIL_DIR, exist_ok=True)


def get_server_host() -> str:
    """
    Get the server's actual IP address on the local network.
    This is more reliable than using .local hostnames for iOS.
    """
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        print(f"Detected server IP: {local_ip}")
        return local_ip
    except Exception as e:
        print(f"Warning: Could not determine local IP: {e}")
        return "localhost"


def extract_gps_from_exif(exif_data):
    """Extract GPS coordinates from EXIF data"""
    gps_info = {}
    
    if not exif_data:
        return None, None
    
    for tag, value in exif_data.items():
        tag_name = TAGS.get(tag, tag)
        if tag_name == "GPSInfo":
            for key in value.keys():
                gps_tag = GPSTAGS.get(key, key)
                gps_info[gps_tag] = value[key]
    
    if not gps_info:
        return None, None
    
    def convert_to_degrees(value):
        d, m, s = value
        return d + (m / 60.0) + (s / 3600.0)
    
    try:
        lat = convert_to_degrees(gps_info.get("GPSLatitude", [0, 0, 0]))
        lon = convert_to_degrees(gps_info.get("GPSLongitude", [0, 0, 0]))
        
        if gps_info.get("GPSLatitudeRef") == "S":
            lat = -lat
        if gps_info.get("GPSLongitudeRef") == "W":
            lon = -lon
        
        return lat, lon
    except:
        return None, None


def extract_camera_params(exif_data):
    """Extract camera parameters from EXIF"""
    params = {}
    
    if not exif_data:
        return params
    
    for tag, value in exif_data.items():
        tag_name = TAGS.get(tag, tag)
        
        if tag_name == "ISOSpeedRatings":
            params["iso"] = value
        elif tag_name == "FNumber":
            params["aperture"] = f"f/{value}"
        elif tag_name == "ExposureTime":
            params["shutter_speed"] = f"1/{int(1/value)}" if value < 1 else f"{value}s"
        elif tag_name == "FocalLength":
            params["focal_length"] = f"{value}mm"
        elif tag_name == "Make":
            params["camera_make"] = value
        elif tag_name == "Model":
            params["camera_model"] = value
    
    return params


def create_thumbnail(source_path: str, thumbnail_path: str, size: tuple = (300, 300)):
    """
    Create a thumbnail from the source image.
    Maintains aspect ratio and uses high-quality resampling.
    """
    try:
        with Image.open(source_path) as img:
            # Convert RGBA to RGB if necessary
            if img.mode == 'RGBA':
                img = img.convert('RGB')
            
            # Create thumbnail maintaining aspect ratio
            img.thumbnail(size, Image.Resampling.LANCZOS)
            
            # Save thumbnail with good quality
            img.save(thumbnail_path, 'JPEG', quality=85, optimize=True)
            
            print(f"Thumbnail created: {thumbnail_path} ({img.size[0]}x{img.size[1]})")
            return True
    except Exception as e:
        print(f"Error creating thumbnail: {e}")
        return False


@router.post("/upload", response_model=PhotoSpotResponse, status_code=201)
async def upload_photo_spot(
    request: Request,
    name: str = Form(..., description="Name of the photo spot"),
    description: Optional[str] = Form(None),
    category: str = Form(...),
    latitude: float = Form(..., description="Latitude"),
    longitude: float = Form(..., description="Longitude"),
    difficulty_level: str = Form("moderate"),
    best_time: Optional[str] = Form(None),
    equipment_needed: Optional[str] = Form(None),
    tags: Optional[str] = Form(None, description="Comma-separated tags"),
    photo: UploadFile = File(..., description="Photo file"),
    db: Session = Depends(get_db)
):
    """
    Upload a photo and create a new PhotoSpot.
    Automatically generates thumbnail for better performance.
    """
    
    # Validate file type
    if not photo.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Generate unique filenames
    file_ext = os.path.splitext(photo.filename)[1]
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    thumbnail_filename = f"thumb_{unique_filename}"
    
    file_path = os.path.join(UPLOAD_DIR, unique_filename)
    thumbnail_path = os.path.join(THUMBNAIL_DIR, thumbnail_filename)
    
    # Save original file
    try:
        with open(file_path, "wb") as f:
            content = await photo.read()
            f.write(content)
        
        file_size = os.path.getsize(file_path)
        print(f"Photo saved: {file_path} ({file_size:,} bytes)")
        
        # Verify image and get dimensions
        with Image.open(file_path) as img:
            width, height = img.size
            print(f"Image dimensions: {width}x{height}")
            
            if width == 0 or height == 0:
                raise ValueError("Invalid image dimensions")
        
        # Create thumbnail
        thumbnail_created = create_thumbnail(file_path, thumbnail_path)
        
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=400, detail=f"Invalid image file: {str(e)}")
    
    # Extract EXIF camera params
    camera_params = {}
    equipment_from_exif = ""
    try:
        image = Image.open(file_path)
        exif_data = image._getexif()
        
        if exif_data:
            camera_params = extract_camera_params(exif_data)
            equipment_info = f"{camera_params.get('camera_make', '')} {camera_params.get('camera_model', '')}".strip()
            
            equipment_parts = []
            if camera_params.get('focal_length'):
                equipment_parts.append(f"Focal length: {camera_params['focal_length']}")
            if camera_params.get('aperture'):
                equipment_parts.append(f"Aperture: {camera_params['aperture']}")
            if camera_params.get('iso'):
                equipment_parts.append(f"ISO: {camera_params['iso']}")
            if camera_params.get('shutter_speed'):
                equipment_parts.append(f"Shutter: {camera_params['shutter_speed']}")
            
            equipment_from_exif = ", ".join(equipment_parts) if equipment_parts else equipment_info
            if equipment_from_exif:
                print(f"EXIF camera params: {equipment_from_exif}")
    except Exception as e:
        print(f"Warning: Could not extract EXIF: {e}")
    
    final_equipment = equipment_needed if equipment_needed else equipment_from_exif
    tag_list = [tag.strip() for tag in tags.split(",")] if tags else []

    # Calculate aesthetic score
    logger.info("Calculating aesthetic score...")
    try:
        aesthetic_score, score_breakdown = calculate_aesthetic_score(file_path, category)
        logger.info(f"CLIP aesthetic score: {aesthetic_score:.2f}")
        logger.info(f"Score breakdown: {score_breakdown}")
    except Exception as e:
        logger.warning(f"CLIP scoring failed, using default: {e}")
        aesthetic_score = 70.0
        score_breakdown = {"error": str(e)}
    
    # Construct URLs
    host = request.headers.get("host")
    
    if host and ".local" in host.lower():
        server_ip = get_server_host()
        if ":" in host:
            port = host.split(":")[1]
            host = f"{server_ip}:{port}"
        else:
            host = f"{server_ip}:8002"
        print(f"Converted .local hostname to IP: {host}")
    
    scheme = request.url.scheme
    base_url = f"{scheme}://{host}"
    image_url = f"{base_url}/uploads/photos/{unique_filename}"
    thumbnail_url = f"{base_url}/uploads/thumbnails/{thumbnail_filename}" if thumbnail_created else None
    
    print(f"Generated image URL: {image_url}")
    if thumbnail_url:
        print(f"Generated thumbnail URL: {thumbnail_url}")
    
    # Create PhotoSpot
    db_spot = PhotoSpot(
        name=name,
        description=description,
        latitude=latitude,
        longitude=longitude,
        city=None,
        country=None,
        category=category.lower(),
        image_url=image_url,
        thumbnail_url=thumbnail_url,
        aesthetic_score=aesthetic_score,  # Use CLIP score instead of 70.0
        popularity_score=50.0,
        difficulty_level=difficulty_level.lower(),
        best_time=best_time,
        equipment_needed=final_equipment,
        tags=tag_list,
        is_active=True
    )
    
    try:
        db.add(db_spot)
        db.commit()
        db.refresh(db_spot)
        print(f"PhotoSpot created successfully:")
        print(f"  ID: {db_spot.id}")
        print(f"  Name: {db_spot.name}")
        print(f"  Image URL: {db_spot.image_url}")
        print(f"  Thumbnail URL: {db_spot.thumbnail_url}")
        print(f"  Location: ({db_spot.latitude}, {db_spot.longitude})")
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        if os.path.exists(thumbnail_path):
            os.remove(thumbnail_path)
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    
    return db_spot