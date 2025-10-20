"""
Pydantic schemas for PhotoSpot API requests and responses.
Handles data validation and serialization.
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime


class PhotoSpotBase(BaseModel):
    """Base schema with common PhotoSpot attributes"""
    name: str = Field(..., min_length=1, max_length=255, description="Name of the photo spot")
    description: Optional[str] = Field(None, description="Detailed description")
    latitude: float = Field(..., ge=-90, le=90, description="GPS latitude (-90 to 90)")
    longitude: float = Field(..., ge=-180, le=180, description="GPS longitude (-180 to 180)")
    city: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    category: str = Field(
        ...,
        description="Category: landscape, architecture, street, nature, urban, etc."
    )
    image_url: Optional[str] = Field(None, max_length=500)
    thumbnail_url: Optional[str] = Field(None, max_length=500)
    aesthetic_score: Optional[float] = Field(
        default=0.0,
        ge=0,
        le=100,
        description="AI aesthetic score 0-100"
    )
    popularity_score: Optional[float] = Field(
        default=0.0,
        ge=0,
        le=100,
        description="User engagement score 0-100"
    )
    difficulty_level: Optional[str] = Field(
        default="moderate",
        description="Access difficulty: easy, moderate, hard"
    )
    best_time: Optional[str] = Field(
        None,
        description="Best time: sunrise, sunset, golden_hour, blue_hour, etc."
    )
    equipment_needed: Optional[str] = None
    tags: Optional[List[str]] = Field(default_factory=list)

    @field_validator('category')
    @classmethod
    def validate_category(cls, v: str) -> str:
        """Validate category is one of the allowed values"""
        allowed = ['landscape', 'architecture', 'street', 'nature', 'urban',
                   'wildlife', 'portrait', 'night', 'aerial', 'other']
        if v.lower() not in allowed:
            raise ValueError(f'Category must be one of: {", ".join(allowed)}')
        return v.lower()

    @field_validator('difficulty_level')
    @classmethod
    def validate_difficulty(cls, v: Optional[str]) -> Optional[str]:
        """Validate difficulty level"""
        if v is None:
            return v
        allowed = ['easy', 'moderate', 'hard']
        if v.lower() not in allowed:
            raise ValueError(f'Difficulty must be one of: {", ".join(allowed)}')
        return v.lower()


class PhotoSpotCreate(PhotoSpotBase):
    """Schema for creating a new PhotoSpot"""
    pass


class PhotoSpotUpdate(BaseModel):
    """Schema for updating an existing PhotoSpot (all fields optional)"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    city: Optional[str] = Field(None, max_length=100)
    country: Optional[str] = Field(None, max_length=100)
    category: Optional[str] = None
    image_url: Optional[str] = Field(None, max_length=500)
    thumbnail_url: Optional[str] = Field(None, max_length=500)
    aesthetic_score: Optional[float] = Field(None, ge=0, le=100)
    popularity_score: Optional[float] = Field(None, ge=0, le=100)
    difficulty_level: Optional[str] = None
    best_time: Optional[str] = None
    equipment_needed: Optional[str] = None
    tags: Optional[List[str]] = None
    is_active: Optional[bool] = None


class PhotoSpotResponse(PhotoSpotBase):
    """Schema for PhotoSpot responses (includes database fields and computed properties)"""
    id: int
    is_active: bool
    created_at: datetime
    updated_at: Optional[datetime] = None

    # Computed properties from hybrid_property in model
    overall_score: float = Field(
        description="Computed overall score (60% aesthetic + 40% popularity)"
    )
    location_display: str = Field(
        description="Formatted location string (City, Country)"
    )

    class Config:
        from_attributes = True  # Allows conversion from SQLAlchemy models


class PhotoSpotList(BaseModel):
    """Schema for paginated list of PhotoSpots"""
    total: int
    page: int
    page_size: int
    spots: List[PhotoSpotResponse]