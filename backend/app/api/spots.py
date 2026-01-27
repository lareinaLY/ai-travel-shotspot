"""
API endpoints for PhotoSpot CRUD operations.
Handles creation, retrieval, updating, and deletion of photo spots.
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional

from app.database import get_db
from app.models.photo_spot import PhotoSpot
from app.schemas.photo_spot import (
    PhotoSpotCreate,
    PhotoSpotUpdate,
    PhotoSpotResponse,
    PhotoSpotList
)

router = APIRouter()


@router.post("/", response_model=PhotoSpotResponse, status_code=201)
def create_photo_spot(
    spot: PhotoSpotCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new photo spot.
    
    Args:
        spot: PhotoSpot data from request body
        db: Database session
        
    Returns:
        Created PhotoSpot with ID and timestamps
    """
    db_spot = PhotoSpot(**spot.model_dump())
    db.add(db_spot)
    db.commit()
    db.refresh(db_spot)
    return db_spot


@router.get("/", response_model=PhotoSpotList)
def list_photo_spots(
    skip: int = Query(0, ge=0, description="Number of records to skip"),
    limit: int = Query(10, ge=1, le=100, description="Number of records to return"),
    search: Optional[str] = Query(None, description="Search by name, city, or country"),
    city: Optional[str] = Query(None, description="Filter by city"),
    category: Optional[str] = Query(None, description="Filter by category"),
    country: Optional[str] = Query(None, description="Filter by country"),
    is_active: bool = Query(True, description="Include only active spots"),
    db: Session = Depends(get_db)
):
    """
    List photo spots with optional filters and pagination.
    
    Args:
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
        search: General search term (searches name, city, and country)
        city: Optional city filter
        category: Optional category filter
        country: Optional country filter
        is_active: Filter by active status
        db: Database session
        
    Returns:
        Paginated list of PhotoSpots with total count
    """
    query = db.query(PhotoSpot).filter(PhotoSpot.is_active == is_active)
    
    # General search (searches across multiple fields)
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                PhotoSpot.name.ilike(search_pattern),
                PhotoSpot.city.ilike(search_pattern),
                PhotoSpot.country.ilike(search_pattern)
            )
        )
    
    # Specific filters (can combine with search)
    if city:
        query = query.filter(PhotoSpot.city.ilike(f"%{city}%"))
    if category:
        query = query.filter(PhotoSpot.category == category.lower())
    if country:
        query = query.filter(PhotoSpot.country.ilike(f"%{country}%"))
    
    # Get total count before pagination
    total = query.count()
    
    # Apply pagination
    spots = query.offset(skip).limit(limit).all()
    
    return {
        "total": total,
        "page": skip // limit + 1,
        "page_size": limit,
        "spots": spots
    }


@router.get("/{spot_id}", response_model=PhotoSpotResponse)
def get_photo_spot(
    spot_id: int,
    db: Session = Depends(get_db)
):
    """
    Get a specific photo spot by ID.
    
    Args:
        spot_id: ID of the photo spot
        db: Database session
        
    Returns:
        PhotoSpot details
        
    Raises:
        HTTPException: 404 if spot not found
    """
    spot = db.query(PhotoSpot).filter(PhotoSpot.id == spot_id).first()
    if not spot:
        raise HTTPException(status_code=404, detail="Photo spot not found")
    return spot


@router.put("/{spot_id}", response_model=PhotoSpotResponse)
def update_photo_spot(
    spot_id: int,
    spot_update: PhotoSpotUpdate,
    db: Session = Depends(get_db)
):
    """
    Update an existing photo spot.
    
    Args:
        spot_id: ID of the spot to update
        spot_update: Updated spot data (only provided fields will be updated)
        db: Database session
        
    Returns:
        Updated PhotoSpot
        
    Raises:
        HTTPException: 404 if spot not found
    """
    db_spot = db.query(PhotoSpot).filter(PhotoSpot.id == spot_id).first()
    if not db_spot:
        raise HTTPException(status_code=404, detail="Photo spot not found")
    
    # Update only provided fields
    update_data = spot_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_spot, field, value)
    
    db.commit()
    db.refresh(db_spot)
    return db_spot


@router.delete("/{spot_id}", status_code=204)
def delete_photo_spot(
    spot_id: int,
    hard_delete: bool = Query(False, description="Permanently delete instead of soft delete"),
    db: Session = Depends(get_db)
):
    """
    Delete a photo spot (soft delete by default).
    
    Args:
        spot_id: ID of the spot to delete
        hard_delete: If True, permanently delete; if False, soft delete (set is_active=False)
        db: Database session
        
    Raises:
        HTTPException: 404 if spot not found
    """
    db_spot = db.query(PhotoSpot).filter(PhotoSpot.id == spot_id).first()
    if not db_spot:
        raise HTTPException(status_code=404, detail="Photo spot not found")
    
    if hard_delete:
        # Permanent deletion
        db.delete(db_spot)
    else:
        # Soft delete
        db_spot.is_active = False
    
    db.commit()
    return None


@router.get("/nearby/", response_model=List[PhotoSpotResponse])
def get_nearby_spots(
    latitude: float = Query(..., ge=-90, le=90, description="Current latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Current longitude"),
    radius_km: float = Query(10, ge=0.1, le=100, description="Search radius in kilometers"),
    limit: int = Query(10, ge=1, le=50, description="Maximum results"),
    db: Session = Depends(get_db)
):
    """
    Find photo spots near a given GPS coordinate.
    Uses simple distance calculation (will be optimized with PostGIS in future).
    
    Args:
        latitude: Current GPS latitude
        longitude: Current GPS longitude
        radius_km: Search radius in kilometers
        limit: Maximum number of results
        db: Database session
        
    Returns:
        List of nearby PhotoSpots sorted by distance
    """
    # Simple bounding box filter (approximation)
    # 1 degree latitude ≈ 111 km
    # 1 degree longitude ≈ 111 km * cos(latitude)
    import math
    
    lat_delta = radius_km / 111.0
    lon_delta = radius_km / (111.0 * math.cos(math.radians(latitude)))
    
    spots = db.query(PhotoSpot).filter(
        PhotoSpot.is_active == True,
        PhotoSpot.latitude.between(latitude - lat_delta, latitude + lat_delta),
        PhotoSpot.longitude.between(longitude - lon_delta, longitude + lon_delta)
    ).limit(limit).all()
    
    return spots