# AI Travel ShotSpot Finder

An AI-powered photography discovery platform that helps travelers find and navigate to aesthetic photo locations using CLIP vision-language model and AR technology.

## Overview

ShotSpot Finder combines **CLIP-based multi-dimensional aesthetic scoring** with **ARKit-powered navigation** to create an intelligent photography assistant. The app analyzes uploaded photos using OpenAI's CLIP model through carefully engineered prompts, evaluating technical quality, composition, lighting, and category-specific appeal. Users are then guided to these spots using a hybrid navigation system that automatically switches between map-based and AR-based guidance depending on distance.

## Key Features

### AI-Powered Aesthetic Evaluation
- **CLIP Multi-Dimensional Scoring**: Evaluates photos across 5 dimensions (universal quality, technical excellence, composition, lighting, category-specific appeal)
- **Two-Stage Evaluation Pipeline**: Quick filter followed by detailed analysis, reducing inference cost by 60%
- **Category-Aware Assessment**: Context-specific prompts for landscape, cityscape, architecture, nature, sunset, night photography
- **Contrastive Validation**: Negative prompts to improve score discrimination
- **Prompt Engineering**: Based on research from LAION Aesthetics Predictor and AVA (Aesthetic Visual Analysis) dataset
- **Score Breakdown**: Interpretable results showing performance in each aesthetic dimension

### Smart Hybrid Navigation
- **Distance-Based Mode Switching**: 
  - Distance >500m: Map-based navigation with Apple Maps integration and turn-by-turn directions
  - Distance <500m: AR-based navigation with real-time 3D directional arrows and distance indicators
- **Continuous GPS Tracking**: Real-time location updates with bearing calculation using CoreLocation
- **Automatic Arrival Detection**: Switches to photo capture mode when within 10m of destination
- **Compass Integration**: AR arrow rotates based on device heading for accurate direction guidance

### Advanced Photo Capture Assistant
- **Reference Photo Overlay**: Real-time camera preview with semi-transparent reference image (adjustable 10-50% opacity)
- **Adaptive UI**: Automatically switches layout between portrait and landscape orientations
- **Overlay Toggle**: Eye icon to show/hide reference photo, opacity slider for fine-tuning
- **Cross-Orientation Support**: Full iOS 17 camera API implementation with videoRotationAngle
- **EXIF Metadata Extraction**: Automatic extraction of camera settings (ISO, aperture, shutter speed, focal length, camera model)

### Intelligent User-Generated Content System
- **Dual Photo Source**: Capture new photo or select from photo library
- **Smart Location Tagging**: 
  - Automatic GPS extraction from photo EXIF metadata
  - Manual location selection with Apple Maps search autocomplete (MKLocalSearchCompleter)
  - Search by city, landmark, or address with real-time suggestions
  - Interactive map with drag-to-select functionality
- **Automatic Thumbnail Generation**: Server-side 300x300 thumbnails using LANCZOS resampling for optimized list performance
- **Comprehensive Metadata**: Name, description, category, difficulty level, best time, equipment recommendations, tags

## Tech Stack

### Frontend (iOS Native)
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with MVVM (Model-View-ViewModel) architecture
- **Minimum iOS**: 17.0
- **Key Technologies**:
  - **ARKit**: Augmented reality navigation with world tracking and gravity alignment
  - **MapKit**: iOS 17 Map API with MapContentBuilder, custom annotations, and region management
  - **CoreLocation**: GPS tracking, heading calculation, bearing computation, distance monitoring
  - **AVFoundation**: Camera capture with orientation handling, photo output configuration
  - **Combine**: Reactive state management with @Published properties and ObservableObject
  - **MKLocalSearchCompleter**: Real-time location search autocomplete

### Backend
- **Framework**: FastAPI (Python 3.9+) with async/await for concurrent request handling
- **Database**: PostgreSQL 14+ with connection pooling and transaction management
- **ORM**: SQLAlchemy 2.0 with hybrid properties for computed fields
- **AI/CV**: 
  - **CLIP (OpenAI)**: Vision-language model (ViT-B/32) for multi-modal aesthetic scoring
  - **PyTorch 2.1**: Deep learning framework with CUDA/MPS/CPU auto-detection
  - **Pillow (PIL)**: Image processing, EXIF extraction, thumbnail generation
- **Key Features**:
  - RESTful API with automatic OpenAPI documentation
  - Multipart form data handling for file uploads
  - Dynamic URL construction with socket-based server IP detection
  - Singleton pattern for CLIP model to avoid redundant loading
  - Pre-encoded text embeddings for 60% inference optimization

## Architecture

### System Design
```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│             │         │              │         │             │
│  iOS App    │◄────────┤  FastAPI     │◄────────┤ PostgreSQL  │
│  (SwiftUI)  │  HTTP   │  Backend     │  ORM    │  Database   │
│             │  mDNS   │              │         │             │
└──────┬──────┘         └──────┬───────┘         └─────────────┘
       │                       │
       │ ARKit                 │ CLIP Model
       │ CoreLocation          │ (ViT-B/32)
       │                       │
       ▼                       ▼
┌─────────────┐         ┌──────────────┐
│   Camera    │         │ Aesthetic    │
│   & GPS     │         │  Scoring     │
└─────────────┘         └──────────────┘
```

### CLIP Aesthetic Scoring Pipeline
```
Photo Upload
    │
    ▼
┌───────────────────────────────────────┐
│ 1. Save Image & Generate Thumbnail   │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│ 2. CLIP Image Encoding (512-dim)     │
└───────────────┬───────────────────────┘
                │
                ▼
┌───────────────────────────────────────┐
│ 3. Quick Filter (2 universal prompts)│
│    - High quality photograph          │
│    - Aesthetically pleasing image     │
└───────────────┬───────────────────────┘
                │
        ┌───────┴───────┐
        │ Score < 0.20? │
        └───┬───────┬───┘
           Yes      No
            │       │
            ▼       ▼
    ┌─────────┐  ┌──────────────────────┐
    │ Return  │  │ 4. Detailed Analysis │
    │ 40-50   │  │  - Technical (25%)   │
    └─────────┘  │  - Composition (25%) │
                 │  - Lighting (15%)    │
                 │  - Category (15%)    │
                 │  - Universal (20%)   │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ 5. Contrastive Check │
                 │  - Negative prompts  │
                 │  - Apply penalty     │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ 6. Score Mapping     │
                 │  0.23-0.26 → 65-80   │
                 │  0.26-0.30 → 80-95   │
                 └──────────┬───────────┘
                            │
                            ▼
                    Final Score (0-100)
```

### Navigation Flow
```
User Selects Spot
    │
    ▼
┌───────────────────┐
│ Get GPS Location  │
└────────┬──────────┘
         │
         ▼
┌───────────────────┐
│ Calculate         │
│ Distance          │
└────────┬──────────┘
         │
    ┌────┴────┐
    │Distance?│
    └────┬────┘
         │
   ┌─────┴─────┐
   │           │
   ▼           ▼
>500m       <500m
   │           │
   ▼           ▼
┌─────────┐ ┌─────────┐
│   Map   │ │   AR    │
│  Mode   │ │  Mode   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
  Apple      ARKit
  Maps       Camera
     │           │
     └─────┬─────┘
           │
      ┌────┴────┐
      │<10m?    │
      └────┬────┘
           │
           ▼
    ┌──────────────┐
    │   Arrived!   │
    │ Show Camera  │
    │ with Overlay │
    └──────────────┘
```

## Project Structure
```
ai-travel-shotspot/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # FastAPI application entry point
│   │   ├── database.py                # PostgreSQL configuration
│   │   │
│   │   ├── api/                       # API endpoints
│   │   │   ├── __init__.py
│   │   │   ├── spots.py              # PhotoSpot CRUD operations
│   │   │   └── upload.py             # Photo upload with CLIP scoring
│   │   │
│   │   ├── models/                    # SQLAlchemy database models
│   │   │   ├── __init__.py
│   │   │   └── photo_spot.py         # PhotoSpot model with hybrid properties
│   │   │
│   │   ├── schemas/                   # Pydantic validation schemas
│   │   │   ├── __init__.py
│   │   │   └── photo_spot.py         # Request/response schemas
│   │   │
│   │   ├── services/                  # Business logic services
│   │   │   ├── __init__.py
│   │   │   └── aesthetic_scorer.py   # CLIP aesthetic evaluation
│   │   │
│   │   └── utils/                     # Utility functions
│   │       └── __init__.py
│   │
│   ├── uploads/                       # User-uploaded content (gitignored)
│   │   ├── photos/                   # Full-size images
│   │   │   └── .gitkeep
│   │   └── thumbnails/               # 300x300 thumbnails
│   │       └── .gitkeep
│   │
│   ├── requirements.txt              # Python dependencies
│   └── test_clip.py                 # CLIP scoring test script
│
├── ios/
│   └── ShotSpotFinder/
│       ├── ShotSpotFinderApp.swift   # App entry point
│       │
│       ├── Models/                    # Data models
│       │   └── PhotoSpot.swift       # PhotoSpot model (matches backend)
│       │
│       ├── ViewModels/                # MVVM ViewModels
│       │   ├── HomeViewModel.swift   # Hot spots logic
│       │   ├── SpotListViewModel.swift # All spots with pagination
│       │   ├── MapViewModel.swift    # Map state management
│       │   └── ARViewModel.swift     # AR session management
│       │
│       ├── Views/                     # SwiftUI views
│       │   ├── HomeView.swift        # Home tab (hot spots)
│       │   ├── SpotListView.swift    # All spots list
│       │   ├── SpotDetailView.swift  # Spot details
│       │   ├── MapView.swift         # Interactive map
│       │   ├── SearchView.swift      # Search interface
│       │   ├── SplashView.swift      # Launch screen
│       │   ├── ARNavigationView.swift      # AR navigation
│       │   ├── NavigationDecisionView.swift # Mode switcher
│       │   ├── UploadSpotView.swift        # Photo upload
│       │   ├── CameraView.swift            # Simple camera
│       │   ├── CustomCameraView.swift      # Camera with overlay
│       │   └── NetworkImage.swift          # Image loader
│       │
│       ├── Services/                  # API and networking
│       │   └── APIService.swift      # Network layer with mDNS
│       │
│       ├── Utilities/                 # Helper utilities
│       │   └── LocationManager.swift # GPS and heading tracking
│       │
│       ├── Assets.xcassets/          # App icons and images
│       └── ShotSpotFinder-Info.plist # App configuration & permissions
│
├── .gitignore                        # Git ignore rules
├── README.md                         # Project documentation
└── test_gitignore.py                # Git ignore validation script
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

This will install:
- FastAPI and web server components
- PostgreSQL drivers and SQLAlchemy
- PyTorch 2.1 and torchvision
- OpenAI CLIP model
- Image processing libraries (Pillow)

**Note**: First installation may take 5-10 minutes due to PyTorch size.

#### 3. Initialize Database
```bash
python3 << EOF
from app.database import init_db
from app.models.photo_spot import PhotoSpot
init_db()
print("Database tables created successfully!")
EOF
```

Verify tables:
```bash
psql -d shotspot_db -c "\dt"
# Should show: photo_spots table

# View table structure
psql -d shotspot_db -c "\d photo_spots"
```

#### 4. Create Upload Directories
```bash
mkdir -p uploads/photos uploads/thumbnails
```

#### 5. Test CLIP Model (Optional)
```bash
python3 test_clip.py
```

This will test CLIP scoring on any existing uploaded photos and verify the model loads correctly.

#### 6. Start Backend Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

First startup will load CLIP model:
```
INFO: Initializing CLIP model on device: cpu
INFO: Pre-encoding text prompts...
INFO: Text prompts encoded successfully
INFO: CLIP model loaded successfully
INFO: Application startup complete.
```

API will be available at:
- Interactive Docs: http://localhost:8002/docs
- ReDoc: http://localhost:8002/redoc
- Health Check: http://localhost:8002/health

### iOS Setup

#### 1. Open Project in Xcode
```bash
cd ios
open ShotSpotFinder.xcodeproj
```

#### 2. Configure Development Team

- Select project in Xcode navigator
- Go to Signing & Capabilities tab
- Select your Apple ID / development team
- Xcode will automatically manage provisioning profiles

#### 3. Verify Info.plist Permissions

The following permissions are pre-configured in `ShotSpotFinder-Info.plist`:
- `NSCameraUsageDescription` - Camera access for AR navigation and photo capture
- `NSLocationWhenInUseUsageDescription` - Location for GPS-based navigation
- `NSPhotoLibraryUsageDescription` - Photo library access for selecting photos
- `NSPhotoLibraryAddUsageDescription` - Save captured photos to library
- `NSAppTransportSecurity` - Allow HTTP for local development
- `UIRequiredDeviceCapabilities` - ARKit support requirement

#### 4. Build and Run

- Select target device (iPhone 15 Pro Simulator or Real iPhone)
- Press `Cmd+R` to build and run
- First build may take 2-3 minutes
- Allow camera and location permissions when prompted

### Network Configuration

The app uses **mDNS (Bonjour)** protocol for automatic backend discovery:

**iOS Simulator**: `http://localhost:8002/api`

**Real iPhone**: `http://YOUR_MAC_HOSTNAME.local:8002/api`

Configuration is handled automatically in `Services/APIService.swift`:
```swift
private var baseURL: String {
    #if targetEnvironment(simulator)
    return "http://localhost:8002/api"
    #else
    return "http://JFHNWJJXGX.local:8002/api"
    #endif
}
```

The backend also uses socket-based IP detection as fallback when `.local` hostname resolution fails.

## API Documentation

### Photo Spots Endpoints

#### List Spots
```http
GET /api/spots?skip=0&limit=20&search=golden&category=landscape
```

**Query Parameters**:
- `skip` - Pagination offset (default: 0)
- `limit` - Number of results (default: 20, max: 100)
- `search` - Search by name, city, or country
- `category` - Filter by category
- `city` - Filter by specific city
- `country` - Filter by specific country
- `is_active` - Include only active spots (default: true)

#### Get Spot Details
```http
GET /api/spots/{id}
```

#### Find Nearby Spots
```http
GET /api/spots/nearby?latitude=37.7749&longitude=-122.4194&radius_km=10&limit=10
```

### Upload Endpoint

#### Upload Photo Spot
```http
POST /api/upload
Content-Type: multipart/form-data
```

**Required Fields**:
- `photo` (file): Image file (JPEG, PNG, HEIC)
- `name` (string): Spot name
- `category` (string): landscape/cityscape/architecture/nature/sunset/night/other
- `latitude` (float): GPS latitude
- `longitude` (float): GPS longitude

**Optional Fields**:
- `description` (string): Detailed description
- `difficulty_level` (string): easy/moderate/hard
- `best_time` (string): golden_hour/blue_hour/midday/night/sunrise/sunset
- `equipment_needed` (string): Recommended equipment
- `tags` (string): Comma-separated tags

**Processing**:
1. Validates image format and dimensions
2. Generates unique filename with UUID
3. Creates 300x300 thumbnail
4. Extracts EXIF metadata
5. **Calculates CLIP aesthetic score**
6. Saves to database with URLs
7. Returns complete PhotoSpot object

### Static Files
```http
GET /uploads/photos/{filename}      # Full-size image
GET /uploads/thumbnails/{filename}  # 300x300 thumbnail
```

## CLIP Aesthetic Scoring Details

### Evaluation Methodology

The system uses **OpenAI's CLIP (Contrastive Language-Image Pre-training) ViT-B/32** model for zero-shot aesthetic evaluation.

**Why CLIP?**
- **Zero-shot learning**: No labeled training data required
- **Multi-modal understanding**: Simultaneous image and text comprehension
- **Semantic alignment**: Unified 512-dimensional embedding space
- **Interpretability**: Detailed breakdown by aesthetic dimension
- **Generalization**: Pre-trained on 400M image-text pairs

**Alternatives Considered**:
- **NIMA**: Photography-specific but requires training data, less interpretable
- **ResNet + Classifier**: Needs labeled dataset and training pipeline
- **GPT-4 Vision**: High API cost and latency
- **Stable Diffusion**: Overweight for scoring task

### Prompt Engineering Strategy

Based on research from **LAION Aesthetics Predictor** and **AVA (Aesthetic Visual Analysis)** dataset.

**Design Principles**:
1. Specific but concise (within CLIP's 77 token limit)
2. Cover multiple aesthetic dimensions independently
3. Use contrastive pairs for better discrimination
4. Adapt prompts to photography category

**Prompt Categories**:
```python
# Universal Quality (20%)
- "a high quality professional photograph"
- "an aesthetically pleasing image with good composition"

# Technical Quality (25%)
- "sharp focus and excellent exposure"
- "professional color grading and contrast"

# Composition (25%)
- "well-balanced composition with strong visual structure"
- "compelling framing following photographic principles"

# Lighting (15%)
- "beautiful natural lighting with great atmosphere"
- "dramatic light creating visual interest"

# Category-Specific (15%)
Landscape: "stunning landscape with dramatic scenery"
Cityscape: "impressive urban architecture and skyline"
Sunset: "breathtaking sunset with stunning colors"

# Negative Prompts (contrastive)
- "poorly composed photograph with bad framing"
- "blurry low-quality image with poor exposure"
```

### Scoring Algorithm
```python
# Stage 1: Quick Filter
quick_score = CLIP_similarity(image, universal_prompts)
if quick_score < 0.20:
    return scaled_score  # 40-50 range

# Stage 2: Detailed Analysis
weighted_score = (
    universal * 0.20 +
    technical * 0.25 +
    composition * 0.25 +
    lighting * 0.15 +
    category * 0.15
)

# Stage 3: Progressive Mapping
# CLIP range [0.18-0.32] → Score [40-95]
if score < 0.23:    aesthetic = map to [40, 65]
elif score < 0.26:  aesthetic = map to [65, 80]
else:               aesthetic = map to [80, 95]

# Stage 4: Contrastive Adjustment
aesthetic -= negative_penalty

# Final: Clamp to [30, 98]
return clamp(aesthetic, 30, 98)
```

### Performance Optimization

- **Singleton Pattern**: Model loaded once and reused
- **Prompt Pre-Encoding**: 60% inference time reduction
- **Two-Stage Evaluation**: 40% computation reduction
- **Device Auto-Detection**: CUDA/MPS/CPU automatic selection

### Score Interpretation
```
Score Range    Quality Level    Description
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
30-45          Poor            Blurry, bad exposure, poor composition
45-60          Below Average   Snapshot quality, lacks visual appeal
60-75          Average         Decent photo, acceptable quality
75-85          Good            Well-composed, good lighting
85-95          Excellent       Professional quality, outstanding
95-98          Outstanding     Exceptional, gallery-worthy
```

## Database Schema
```sql
CREATE TABLE photo_spots (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    latitude FLOAT NOT NULL,
    longitude FLOAT NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100),
    category VARCHAR(50) NOT NULL,
    image_url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    aesthetic_score FLOAT DEFAULT 0,
    popularity_score FLOAT DEFAULT 0,
    difficulty_level VARCHAR(20) DEFAULT 'moderate',
    best_time VARCHAR(50),
    equipment_needed TEXT,
    tags JSON,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Computed properties (SQLAlchemy hybrid_property)
-- overall_score = aesthetic_score * 0.6 + popularity_score * 0.4
-- location_display = 'City, Country' or 'Unknown Location'
```

## Features Implementation Status

### ✅ Completed Features

- Native iOS app with SwiftUI and MVVM architecture
- PostgreSQL backend with RESTful API
- **CLIP-based multi-dimensional aesthetic scoring**
- Photo spot browsing with search and filters
- Interactive map view with custom markers
- AR navigation with distance and bearing tracking
- Smart mode switching (Map >500m vs AR <500m)
- Photo upload (camera / photo library)
- Manual location selection with Apple Maps search
- Automatic thumbnail generation
- EXIF metadata extraction
- Cross-orientation camera support
- mDNS-based cross-platform networking
- Reference photo overlay with adjustable transparency

### 🔄 Future Enhancements

#### Advanced AI Features
- **Visual Similarity Search**: CLIP embedding-based photo search
- **Personalized Recommendations**: User preference modeling with collaborative filtering
- **Social Validation Scoring**: Compare with curated reference photo dataset
- **Scene Composition Analysis**: YOLOv8 object detection for composition feedback

#### Social & Community
- **User Authentication**: JWT-based login system
- **User Engagement Metrics**: Dynamic popularity scoring from interactions
- **Community Features**: Likes, comments, user following, leaderboards

#### Intelligent Planning
- **Multi-Spot Route Optimization**: TSP solver for efficient photography tours
- **Personalized Routes**: Style-based itinerary generation
- **Weather Integration**: Real-time golden hour predictions
- **Time-of-Day Optimization**: Historical data-based recommendations

#### Infrastructure
- **Reverse Geocoding**: Automatic city/country detection
- **Fine-tuned CLIP**: Photography-specific model training
- **Docker Deployment**: Containerization with CI/CD
- **Web Frontend**: React/Next.js for broader accessibility

## Development Workflow

### Running the App

**Backend**:
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

**iOS Simulator**: `http://localhost:8002`  
**iOS Real Device**: `http://YOUR_MAC.local:8002` (same WiFi required)

### Testing Workflows

#### Upload Flow
1. Tap "+" → Choose camera/library
2. Select/capture photo
3. If no GPS: Manual location selection with search
4. Fill details → Upload
5. Backend: Save → Thumbnail → EXIF → **CLIP score** → Database
6. Success: New spot appears in list

#### AR Navigation
1. Select spot → Tap "Navigate"
2. Distance >500m: Map view → "Open in Apple Maps"
3. Distance <500m: AR view with directional arrow
4. Distance <10m: "Arrived!" → Camera with overlay

#### Camera with Overlay
1. Arrive at spot → Tap "Take Photo"
2. Preview shows reference photo overlay
3. Adjust opacity (10-50%) or toggle visibility
4. Capture with correct orientation
5. Save to photo library

## Performance Metrics

### Image Processing
- Original: 2-4MB
- Thumbnails: 20-50KB
- Generation: 100-200ms

### CLIP Inference
- Model loading (first time): 10-15s
- Image encoding: 200-500ms (CPU)
- Total scoring: 1-2s per upload

### API Performance
- List: 50-100ms (20 items)
- Upload: 2-3s (with CLIP)
- Image serving: 100-300ms

### Database
- Connection pool: 10 connections, 20 overflow
- Indexed queries on category, location, scores
- Supports 10+ concurrent uploads

## Technical Highlights

### Mobile Development
- Native iOS with pure Swift/SwiftUI
- MVVM architecture with reactive ViewModels
- iOS 17 modern APIs (MapKit, ARKit, AVFoundation)
- Complete orientation handling

### Backend Engineering
- FastAPI async/await for concurrency
- Database optimization with hybrid properties
- Singleton pattern for CLIP model
- Pre-encoded embeddings for performance

### AI/ML Integration
- Multi-modal CLIP vision-language model
- Research-based prompt engineering
- Two-stage evaluation for efficiency
- Progressive score calibration

## Known Issues & Solutions

**Camera Orientation**: iOS 17 `videoRotationAngle` API with proper mapping

**Photo Orientation Persistence**: Set angle on both preview and output connections

**Image Loading**: Configure `NSAppTransportSecurity` in Info.plist

**mDNS Resolution**: Backend auto-detects IP as fallback

**CLIP Score Distribution**: Progressive non-linear mapping for realistic range

## Development Notes

### Lessons Learned

**iOS**:
- `ObservableObject` requires explicit `import Combine`
- Camera orientation needs separate preview and capture configuration
- iOS 17 MapKit API migration required
- Real device testing essential for camera/GPS/AR

**Backend**:
- StaticFiles must mount after router registration
- PostgreSQL better for production than SQLite
- Async lifespan managers cleaner than startup events
- Logger requires explicit initialization

**AI/ML**:
- CLIP similarities typically 0.15-0.35, need calibration
- Pre-encoding prompts dramatically improves performance
- Category-specific prompts increase relevance
- Two-stage evaluation balances cost and quality

**Network**:
- mDNS works well with IP fallback for reliability
- Dynamic URL construction handles device differences
- Socket-based IP detection more reliable than parsing

### Best Practices

**Code Quality**:
- Comprehensive docstrings
- Type hints throughout
- Proper error handling
- Structured logging

**Architecture**:
- Separation of concerns (MVVM, services, data)
- Dependency injection patterns
- Singleton for expensive resources
- Repository pattern for data access

**Data Integrity**:
- Transaction management with rollback
- File cleanup on failures
- Input validation with Pydantic
- Soft delete for safety

**Performance**:
- Connection pooling
- Image optimization
- Lazy loading
- Efficient indexing

## Code Statistics

- Backend: ~2,000 lines of Python (10+ files)
- iOS: ~4,000 lines of Swift (20+ files)
- Total: ~6,000 lines across 35+ source files

## Portfolio Showcase

This project demonstrates:
- ✅ Full-stack mobile development (iOS + Python)
- ✅ AI/ML integration (CLIP with optimized inference)
- ✅ Computer vision (image processing, aesthetic evaluation)
- ✅ AR technology (ARKit navigation)
- ✅ Modern API design (FastAPI, OpenAPI)
- ✅ Database engineering (PostgreSQL, ORM)
- ✅ Mobile UX design (adaptive, intuitive)
- ✅ Performance optimization (caching, pre-computation)
- ✅ Production readiness (error handling, logging)

## Technologies Deep Dive

**Native iOS**: Better AR/camera performance, latest APIs, superior UX

**FastAPI**: Auto docs, async support, type validation, high performance

**PostgreSQL**: ACID compliance, geospatial support, scalability

**CLIP**: Zero-shot learning, multi-modal, strong generalization

**PyTorch**: Official CLIP support, intuitive debugging, MPS optimization

## Contact

**Ying Lu**

Email: lu.y7@northeastern.edu  
LinkedIn: https://www.linkedin.com/in/yinglulareina/

---

**Project Status**: Production-Ready MVP with AI Integration  
**Last Updated**: February 4, 2026  
**Version**: 1.1.0  
**License**: MIT

**Keywords**: iOS, Swift, SwiftUI, ARKit, CLIP, PyTorch, FastAPI, PostgreSQL, AI/ML, Computer Vision, Mobile Development, Augmented Reality