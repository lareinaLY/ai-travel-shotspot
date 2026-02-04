# AI Travel ShotSpot Finder

An AI-powered photography discovery platform that helps travelers find and navigate to aesthetic photo locations using computer vision and AR technology.

## Overview

ShotSpot Finder combines **CLIP-based aesthetic scoring** with **AR navigation** to create an intelligent photography assistant. The app analyzes uploaded photos using OpenAI's CLIP model to identify visually appealing locations, then guides users to these spots using ARKit-powered augmented reality.

## Key Features

### AI-Powered Discovery
- **CLIP Aesthetic Scoring**: Uses OpenAI's CLIP (Contrastive Language-Image Pre-training) to evaluate photo aesthetics
- **Multi-Modal Analysis**: Compares images against aesthetic concepts like "beautiful landscape", "golden hour lighting"
- **Automatic Categorization**: AI-based scene classification (landscape, cityscape, architecture, etc.)

### Smart Navigation
- **Hybrid Navigation System**: 
  - Distance >500m: Map-based navigation with Apple Maps integration
  - Distance <500m: AR-based navigation with real-time directional guidance
- **GPS Tracking**: Continuous location updates with bearing calculation
- **Arrival Detection**: Automatic mode switching when within 10m of destination

### Photo Capture Assistant
- **Reference Photo Overlay**: Real-time camera preview with adjustable transparency (10-50%)
- **Cross-Orientation Support**: Full portrait and landscape camera functionality
- **EXIF Extraction**: Automatic extraction of camera settings (ISO, aperture, shutter speed, focal length)

### User-Generated Content
- **Photo Upload**: Contribute new spots via camera or photo library
- **Smart Location Tagging**: 
  - Automatic GPS extraction from photo EXIF
  - Manual location selection with Apple Maps search autocomplete
- **Automatic Thumbnail Generation**: Server-side 300x300 thumbnails for optimized performance

## Tech Stack

### Frontend (iOS Native)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with MVVM architecture
- **Minimum iOS**: 17.0
- **Key Technologies**:
  - **ARKit**: Augmented reality navigation and scene tracking
  - **MapKit**: iOS 17 Map API with custom annotations
  - **CoreLocation**: GPS tracking and heading calculation
  - **AVFoundation**: Camera capture with orientation handling
  - **Combine**: Reactive state management

### Backend
- **Framework**: FastAPI (Python 3.9+)
- **Database**: PostgreSQL 14+ with SQLAlchemy ORM
- **AI/CV**: 
  - **CLIP** (OpenAI): Image aesthetic scoring
  - **Pillow**: Image processing and EXIF extraction
- **Key Features**:
  - RESTful API with automatic OpenAPI documentation
  - Multipart form data for file uploads
  - Dynamic URL construction for cross-platform compatibility
  - Automatic thumbnail generation with LANCZOS resampling

## Architecture

### System Design
```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│             │         │              │         │             │
│  iOS App    │◄────────┤  FastAPI     │◄────────┤ PostgreSQL  │
│  (SwiftUI)  │  HTTP   │  Backend     │  ORM    │  Database   │
│             │         │              │         │             │
└──────┬──────┘         └──────┬───────┘         └─────────────┘
       │                       │
       │ ARKit                 │ CLIP
       │                       │
       ▼                       ▼
┌─────────────┐         ┌──────────────┐
│   Camera    │         │  AI Model    │
│   & GPS     │         │  Inference   │
└─────────────┘         └──────────────┘
```

### Data Flow

**Photo Upload Flow**:
```
User Takes Photo → Extract EXIF GPS → [Optional] Manual Location Selection
    → Upload to Backend → CLIP Aesthetic Scoring → Generate Thumbnail
    → Save to PostgreSQL → Return Spot with URLs → Display in App
```

**Navigation Flow**:
```
User Selects Spot → Get GPS Location → Calculate Distance
    → If >500m: Map Navigation → If <500m: AR Navigation
    → Arrival Detection → Show Reference Photo → Capture Photo
```

## Setup Instructions

### Prerequisites
- macOS with Xcode 15+
- Python 3.9+
- PostgreSQL 14+
- iOS device or simulator (iOS 17+)
- iPhone on same WiFi network as Mac (for real device testing)

### Backend Setup

#### 1. Install PostgreSQL
```bash
brew install postgresql@14
brew services start postgresql@14
createdb shotspot_db
```

#### 2. Setup Python Environment
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 3. Install CLIP Dependencies
```bash
pip install torch torchvision
pip install git+https://github.com/openai/CLIP.git
```

#### 4. Initialize Database
```bash
python3 << EOF
from app.database import init_db
from app.models.photo_spot import PhotoSpot
init_db()
print("Database initialized!")
EOF
```

Verify tables:
```bash
psql -d shotspot_db -c "\dt"
```

#### 5. Create Upload Directories
```bash
mkdir -p uploads/photos uploads/thumbnails
```

#### 6. Start Backend
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

API Documentation: http://localhost:8002/docs

### iOS Setup

#### 1. Open in Xcode
```bash
cd ios
open ShotSpotFinder.xcodeproj
```

#### 2. Configure Signing
- Select project → Signing & Capabilities
- Choose your development team

#### 3. Build and Run
- Select target device (Simulator or iPhone)
- Press `Cmd+R`
- Allow permissions when prompted

### Network Configuration

The app uses **mDNS (Bonjour)** for automatic backend discovery:
- **Simulator**: `http://localhost:8002/api`
- **Real iPhone**: `http://YOUR_MAC_HOSTNAME.local:8002/api`

Configuration in `APIService.swift`:
```swift
#if targetEnvironment(simulator)
    return "http://localhost:8002/api"
#else
    return "http://JFHNWJJXGX.local:8002/api"
#endif
```

## API Endpoints

### Photo Spots
```http
GET    /api/spots              # List spots with pagination and filters
GET    /api/spots/{id}         # Get spot details
GET    /api/spots/nearby       # Find nearby spots
```

### Upload
```http
POST   /api/upload             # Upload photo with metadata
GET    /uploads/photos/{file}  # Serve full-size image
GET    /uploads/thumbnails/{file}  # Serve thumbnail
```

## Features Implementation Status

### Completed
- ✅ Native iOS app with SwiftUI and MVVM architecture
- ✅ PostgreSQL backend with RESTful API
- ✅ Photo spot browsing with search and category filters
- ✅ Interactive map view with custom markers
- ✅ AR navigation with distance and bearing tracking
- ✅ Smart mode switching (Map vs AR based on distance)
- ✅ Photo upload with camera and photo library support
- ✅ Manual location selection with Apple Maps search
- ✅ Automatic thumbnail generation (300x300)
- ✅ EXIF metadata extraction
- ✅ Cross-orientation camera support (iOS 17 API)
- ✅ mDNS-based cross-platform networking

### In Progress
- 🔄 CLIP-based aesthetic scoring (Phase 2)
- 🔄 User authentication and profiles

### Planned
- 📋 Multi-spot itinerary optimization
- 📋 Social features (likes, comments, sharing)
- 📋 Weather integration for golden hour timing
- 📋 Reverse geocoding for automatic city/country detection
- 📋 YOLOv8 object detection for scene composition analysis

## Technical Highlights

### Mobile Development
- **Native iOS**: Full Swift/SwiftUI implementation with no cross-platform frameworks
- **MVVM Pattern**: Clean separation of concerns with reactive ViewModels
- **Modern APIs**: iOS 17 MapKit, ARKit, and camera APIs
- **Network Resilience**: Automatic device detection and fallback mechanisms

### Backend Engineering
- **High Performance**: FastAPI with async/await for concurrent requests
- **Database Optimization**: SQLAlchemy hybrid properties for computed fields
- **Image Processing**: Efficient thumbnail generation with Pillow
- **Dynamic URL Construction**: Socket-based server IP detection for reliable iOS connectivity

### Computer Vision (Planned)
- **CLIP Integration**: Zero-shot image classification and aesthetic scoring
- **Multi-Modal AI**: Text-image similarity for semantic search
- **Transfer Learning**: Fine-tuned on photography-specific datasets

## Performance Metrics

### Image Optimization
- Original photos: ~2-4MB
- Thumbnails: ~20-50KB (300x300, quality 85%)
- List view load time: <500ms for 20 items
- Detail view load time: <1s for full image

### Database
- Connection pool: 10 concurrent connections
- Query optimization: Indexed on category, city, country
- Hybrid properties: Computed at query time (no storage overhead)

## Known Issues & Solutions

### Camera Orientation
**Issue**: Camera preview rotated incorrectly on landscape  
**Solution**: Use iOS 17 `videoRotationAngle` API with proper mapping

### Image Loading Fails
**Issue**: AsyncImage fails with HTTP URLs  
**Solution**: Configure `NSAppTransportSecurity` in Info.plist for local development

### mDNS Resolution
**Issue**: `.local` hostname unreliable on some networks  
**Solution**: Backend auto-detects server IP using socket connection

## Development Notes

### Lessons Learned
- SwiftUI's `ObservableObject` requires explicit `import Combine`
- Camera orientation must be set for both preview AND capture
- FastAPI StaticFiles must be mounted before router registration
- PostgreSQL provides better scalability than SQLite for production
- iOS 17 deprecated many MapKit APIs, requiring migration to new MapContentBuilder pattern

### Best Practices Applied
- Proper error handling with user-friendly messages
- Comprehensive logging for debugging
- Separation of concerns (MVVM, service layer)
- Type safety with Pydantic schemas
- Database transaction management with automatic rollback

## Future Enhancements

### Phase 2: AI Features
- Integrate CLIP for aesthetic scoring
- Add visual similarity search
- Implement scene composition analysis

### Phase 3: Social & Gamification
- User profiles and authentication
- Photo likes and favorites
- Leaderboards and achievements
- Community contributions

### Phase 4: Advanced Features
- Weather-based recommendations
- Time-of-day optimization
- Route planning for multiple spots
- Collaborative itineraries

## Portfolio Showcase

This project demonstrates:
- ✅ Full-stack mobile development (iOS native + Python backend)
- ✅ Modern API design with FastAPI
- ✅ Database modeling with PostgreSQL
- ✅ AR technology integration
- ✅ Image processing and optimization
- ✅ Cross-platform networking solutions
- ✅ User experience design
- 🔄 AI/ML integration (CLIP - in progress)

## Contact

**Ying Lu**  
Email: lu.y7@northeastern.edu  
LinkedIn: https://www.linkedin.com/in/yinglulareina/

---

**Project Status**: Active Development  
**Last Updated**: February 3, 2026  
**Version**: 1.0.0