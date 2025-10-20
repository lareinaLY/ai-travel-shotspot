"""
Database model for PhotoSpot.
Stores information about photography locations including GPS coordinates,
images, ratings, and metadata for the recommendation engine.
"""

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, Text, JSON
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.sql import func
from app.database import Base


class PhotoSpot(Base):
    """
    PhotoSpot model representing a photography location.

    Attributes:
        id: Primary key
        name: Name of the photo spot
        description: Detailed description of the location
        latitude: GPS latitude coordinate
        longitude: GPS longitude coordinate
        city: City name
        country: Country name
        category: Type of spot (landscape, architecture, street, etc.)
        image_url: URL to the main spot image
        thumbnail_url: URL to thumbnail image
        aesthetic_score: AI-generated aesthetic score (0-100)
        popularity_score: User engagement score (0-100)
        difficulty_level: Access difficulty (easy, moderate, hard)
        best_time: Best time to visit (sunrise, sunset, golden_hour, etc.)
        equipment_needed: Recommended photography equipment
        tags: JSON array of tags for filtering
        is_active: Soft delete flag
        created_at: Timestamp of creation
        updated_at: Timestamp of last update
    """
    __tablename__ = "photo_spots"

    # Primary key
    id = Column(Integer, primary_key=True, index=True)

    # Basic information
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)

    # Location data
    latitude = Column(Float, nullable=False, index=True)
    longitude = Column(Float, nullable=False, index=True)
    city = Column(String(100), nullable=True, index=True)
    country = Column(String(100), nullable=True, index=True)

    # Categorization
    category = Column(
        String(50),
        nullable=False,
        index=True,
        comment="Category: landscape, architecture, street, nature, urban, etc."
    )

    # Media
    image_url = Column(String(500), nullable=True)
    thumbnail_url = Column(String(500), nullable=True)

    # Scoring for recommendation engine
    aesthetic_score = Column(
        Float,
        default=0.0,
        comment="AI aesthetic score 0-100"
    )
    popularity_score = Column(
        Float,
        default=0.0,
        comment="User engagement score 0-100"
    )

    # Practical information
    difficulty_level = Column(
        String(20),
        default="moderate",
        comment="Access difficulty: easy, moderate, hard"
    )
    best_time = Column(
        String(50),
        nullable=True,
        comment="Best photography time: sunrise, sunset, golden_hour, blue_hour, etc."
    )
    equipment_needed = Column(
        Text,
        nullable=True,
        comment="Recommended equipment: tripod, wide-angle lens, etc."
    )

    # Flexible metadata
    tags = Column(
        JSON,
        nullable=True,
        comment="Array of tags for filtering and search"
    )

    # Soft delete
    is_active = Column(Boolean, default=True, index=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Computed properties using hybrid_property (avoids Pydantic validation issues)
    @hybrid_property
    def overall_score(self) -> float:
        """
        Calculate overall recommendation score combining aesthetic and popularity.
        This is a computed property that Pydantic can read as an attribute.

        Returns:
            float: Overall score (0-100)
        """
        # Weight: 60% aesthetic, 40% popularity
        return (self.aesthetic_score * 0.6) + (self.popularity_score * 0.4)

    @hybrid_property
    def location_display(self) -> str:
        """
        Format location as "City, Country" for display.

        Returns:
            str: Formatted location string
        """
        if self.city and self.country:
            return f"{self.city}, {self.country}"
        elif self.city:
            return self.city
        elif self.country:
            return self.country
        return "Unknown Location"

    def __repr__(self):
        return f"<PhotoSpot(id={self.id}, name='{self.name}', city='{self.city}')>"