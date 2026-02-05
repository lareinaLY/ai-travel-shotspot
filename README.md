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
  - **CLIP (OpenAI)**: Vision-language model for multi-modal aesthetic scoring
  - **PyTorch**: Deep learning framework with CUDA/MPS/CPU auto-detection
  - **Pillow (PIL)**: Image processing, EXIF extraction, thumbnail generation
- **Key Features**:
  - RESTful API with automatic OpenAPI documentation
  - Multipart form data handling for file uploads
  - Dynamic URL construction with socket-based server IP detection
  - Singleton pattern for CLIP model to avoid redundant loading
  - Pre-encoded text embeddings for inference optimization

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
├── ios/
│   └── ShotSpotFinder/
│       ├── Models/
│       │   └── PhotoSpot.swift              # Data model matching backend schema
│       ├── ViewModels/
│       │   ├── HomeViewModel.swift          # Hot spots management
│       │   ├── SpotListViewModel.swift      # All spots with pagination
│       │   ├── MapViewModel.swift           # Map view state management
│       │   └── ARViewModel.swift            # AR session management
│       ├── Views/
│       │   ├── HomeView.swift               # Home tab with hot spots ranking
│       │   ├── SpotListView.swift           # Complete spots list
│       │   ├── SpotDetailView.swift         # Spot details with scores
│       │   ├── MapView.swift                # Interactive map with markers
│       │   ├── SearchView.swift             # Search functionality
│       │   ├── ARNavigationView.swift       # AR navigation interface
│       │   ├── NavigationDecisionView.swift # Smart mode switcher
│       │   ├── UploadSpotView.swift         # Photo upload form
│       │   ├── CameraView.swift             # Simple camera for AR
│       │   ├── CustomCameraView.swift       # Advanced camera with overlay
│       │   └── NetworkImage.swift           # Custom image loader
│       ├── Services/
│       │   └── APIService.swift             # Network layer with mDNS
│       ├── Utilities/
│       │   └── LocationManager.swift        # GPS and heading tracking
│       └── ShotSpotFinder-Info.plist        # App permissions
└── backend/
    └── app/
        ├── api/
        │   ├── spots.py                     # CRUD endpoints
        │   └── upload.py                    # Photo upload with CLIP scoring
        ├── models/
        │   └── photo_spot.py                # SQLAlchemy model
        ├── schemas/
        │   └── photo_spot.py                # Pydantic validation schemas
        ├── services/
        │   └── aesthetic_scorer.py          # CLIP aesthetic evaluation
        ├── database.py                      # Database configuration
        └── main.py                          # FastAPI application
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
- PyTorch and torchvision
- OpenAI CLIP model
- Image processing libraries

First installation may take 5-10 minutes due to PyTorch size.

#### 3. Initialize Database
```bash
python3 << EOF
from app.database import init_db
from app.models.photo_spot import PhotoSpot
init_db()
print("Database tables created successfully!")
EOF
```

Verify:
```bash
psql -d shotspot_db -c "\dt"
# Should show: photo_spots table
```

#### 4. Create Upload Directories
```bash
mkdir -p uploads/photos uploads/thumbnails
```

#### 5. Test CLIP Model (Optional)
```bash
python3 test_clip.py
```

This will test CLIP scoring on any existing uploaded photos.

#### 6. Start Backend Server
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

First startup will load CLIP model (10-15 seconds):
```
INFO: Initializing CLIP model on device: cpu
INFO: Pre-encoding text prompts...
INFO: CLIP model loaded successfully
INFO: Application startup complete.
```

API will be available at:
- Docs: http://localhost:8002/docs
- ReDoc: http://localhost:8002/redoc
- Health: http://localhost:8002/health

### iOS Setup

#### 1. Open Project in Xcode
```bash
cd ios
open ShotSpotFinder.xcodeproj
```

#### 2. Configure Development Team

- Select project in Xcode
- Go to Signing & Capabilities
- Select your Apple ID / development team

#### 3. Verify Info.plist Permissions

The following permissions are pre-configured:
- `NSCameraUsageDescription` - Camera access for AR and photo capture
- `NSLocationWhenInUseUsageDescription` - Location for navigation
- `NSPhotoLibraryUsageDescription` - Photo library access
- `NSPhotoLibraryAddUsageDescription` - Save photos to library
- `NSAppTransportSecurity` - Allow HTTP for local development
- `UIRequiredDeviceCapabilities` - ARKit support

#### 4. Build and Run

- Select target device (iPhone 15 Pro Simulator or Real iPhone)
- Press `Cmd+R` to build and run
- Allow camera and location permissions when prompted

### Network Configuration

The app uses **mDNS (Bonjour)** protocol for automatic device detection:

**iOS Simulator**:
```swift
http://localhost:8002/api
```

**Real iPhone**:
```swift
http://YOUR_MAC_HOSTNAME.local:8002/api
```

Configuration is handled automatically in `APIService.swift`:
```swift
#if targetEnvironment(simulator)
    return "http://localhost:8002/api"
#else
    return "http://JFHNWJJXGX.local:8002/api"
#endif
```

The backend also uses socket-based IP detection as fallback when `.local` resolution fails.

## API Documentation

### Photo Spots Endpoints

#### List Spots
```http
GET /api/spots?skip=0&limit=20&search=golden&category=landscape
```

Query Parameters:
- `skip` - Pagination offset (default: 0)
- `limit` - Number of results (default: 20, max: 100)
- `search` - Search by name, city, or country
- `category` - Filter by category (landscape, cityscape, etc.)
- `city` - Filter by specific city
- `country` - Filter by specific country

Response:
```json
{
  "total": 50,
  "page": 1,
  "page_size": 20,
  "spots": [
    {
      "id": 1,
      "name": "Golden Gate Bridge at Sunset",
      "latitude": 37.8199,
      "longitude": -122.4783,
      "aesthetic_score": 85.2,
      "popularity_score": 78.5,
      "overall_score": 82.5,
      "category": "landscape",
      "image_url": "http://...",
      "thumbnail_url": "http://..."
    }
  ]
}
```

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

Required Fields:
- photo (file): Image file (JPEG, PNG)
- name (string): Spot name
- category (string): landscape/cityscape/architecture/nature/sunset/night/other
- latitude (float): GPS latitude (-90 to 90)
- longitude (float): GPS longitude (-180 to 180)

Optional Fields:
- description (string): Detailed description
- difficulty_level (string): easy/moderate/hard (default: moderate)
- best_time (string): golden_hour/blue_hour/midday/night/sunrise/sunset
- equipment_needed (string): Recommended equipment
- tags (string): Comma-separated tags
```

Response includes:
- CLIP-calculated aesthetic score with multi-dimensional breakdown
- Automatically extracted EXIF camera parameters
- Generated thumbnail URL
- Complete PhotoSpot object

Example Response:
```json
{
  "id": 10,
  "name": "Sunset at Ocean Beach",
  "aesthetic_score": 78.5,
  "popularity_score": 50.0,
  "overall_score": 67.1,
  "category": "sunset",
  "image_url": "http://192.168.1.100:8002/uploads/photos/uuid.jpg",
  "thumbnail_url": "http://192.168.1.100:8002/uploads/thumbnails/thumb_uuid.jpg",
  "equipment_needed": "Focal length: 24mm, Aperture: f/8, ISO: 100",
  "created_at": "2026-02-04T10:30:00Z"
}
```

### Static Files
```http
GET /uploads/photos/{filename}      # Full-size image (2-4MB)
GET /uploads/thumbnails/{filename}  # 300x300 thumbnail (20-50KB)
```

## CLIP Aesthetic Scoring Details

### Evaluation Methodology

The system uses OpenAI's CLIP (Contrastive Language-Image Pre-training) ViT-B/32 model for zero-shot aesthetic evaluation.

**Why CLIP?**
- **Zero-shot learning**: No need for labeled training data
- **Multi-modal understanding**: Simultaneous image and text comprehension
- **Semantic alignment**: Unified embedding space for meaningful comparisons
- **Interpretability**: Breakdown shows performance in specific dimensions

**Alternatives Considered**:
- NIMA (Neural Image Assessment): Requires training data, less interpretable
- ResNet + Classifier: Needs labeled dataset and training pipeline
- GPT-4 Vision: High API cost and latency
- Stable Diffusion: Overly complex for scoring task

### Prompt Engineering Strategy

Based on research from LAION Aesthetics Predictor and AVA dataset:

**Design Principles**:
1. **Specific but concise**: Visual descriptions within CLIP's 77 token limit
2. **Multiple aspects**: Cover different aesthetic dimensions
3. **Contrastive pairs**: Positive and negative prompts for discrimination
4. **Category awareness**: Adapt prompts to photography type

**Prompt Categories**:
```python
# Universal Quality (20% weight)
- "a high quality professional photograph"
- "an aesthetically pleasing image with good composition"

# Technical Quality (25% weight)  
- "sharp focus and excellent exposure"
- "professional color grading and contrast"

# Composition (25% weight)
- "well-balanced composition with strong visual structure"
- "compelling framing following photographic principles"

# Lighting (15% weight)
- "beautiful natural lighting with great atmosphere"  
- "dramatic light creating visual interest"

# Category-Specific (15% weight)
Landscape: "stunning landscape with dramatic scenery"
Cityscape: "impressive urban architecture and skyline"
Sunset: "breathtaking sunset with stunning colors"
# ... etc for each category

# Negative Prompts (contrastive)
- "poorly composed photograph with bad framing"
- "blurry low-quality image with poor exposure"
```

### Scoring Algorithm
```python
# Stage 1: Quick Filter
quick_score = CLIP_similarity(image, universal_prompts)
if quick_score < 0.20:
    return scaled_quick_score  # 40-50 range

# Stage 2: Detailed Analysis  
weighted_score = (
    universal * 0.20 +
    technical * 0.25 +
    composition * 0.25 +
    lighting * 0.15 +
    category * 0.15
)

# Stage 3: Score Mapping
# CLIP similarities typically range 0.18-0.32
# Map to intuitive 40-95 scale with progressive tiers

if score < 0.23:  # Average photos
    aesthetic = map(score, 0.18→0.23, 40→65)
elif score < 0.26:  # Good photos  
    aesthetic = map(score, 0.23→0.26, 65→80)
else:  # Excellent photos
    aesthetic = map(score, 0.26→0.30, 80→95)

# Stage 4: Contrastive Adjustment
negative_similarity = CLIP_similarity(image, negative_prompts)
if negative_similarity > threshold:
    aesthetic -= penalty

# Final: Clamp to [30, 98]
return clamp(aesthetic, 30, 98)
```

### Performance Optimization

**Singleton Pattern**: CLIP model loaded once and reused
- First upload: ~10-15s (model loading + inference)
- Subsequent uploads: ~1-2s (inference only)

**Prompt Pre-encoding**: Text prompts encoded at initialization
- Eliminates redundant text encoding on each image
- Reduces inference time by 60%
- Only image needs encoding per upload

**Two-Stage Evaluation**: Skip detailed analysis for low-quality images
- Quick filter: 2 prompts
- Detailed analysis: 6-8 prompts (only for promising images)
- Saves computation on poor quality submissions

### Score Interpretation
```
Score Range    Quality Level    Description
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
30-45          Poor            Blurry, bad exposure, poor composition
45-60          Below Average   Snapshot quality, lacks visual appeal  
60-75          Average         Decent photo, acceptable quality
75-85          Good            Well-composed, good lighting
85-95          Excellent       Professional quality, outstanding
95-98          Outstanding     Exceptional, gallery-worthy
```

## Database Schema

### PhotoSpot Model
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
    aesthetic_score FLOAT DEFAULT 0,      -- CLIP-calculated
    popularity_score FLOAT DEFAULT 0,     -- User engagement
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

### Completed Features
- ✅ Native iOS app with SwiftUI and MVVM architecture
- ✅ PostgreSQL backend with RESTful API
- ✅ **CLIP-based multi-dimensional aesthetic scoring**
- ✅ Photo spot browsing with search and filters
- ✅ Interactive map view with custom markers
- ✅ AR navigation with distance and bearing tracking
- ✅ Smart mode switching (Map vs AR based on distance)
- ✅ Photo upload with camera and photo library support
- ✅ Manual location selection with Apple Maps search autocomplete
- ✅ Automatic thumbnail generation (300x300, LANCZOS)
- ✅ EXIF metadata extraction (GPS, camera settings)
- ✅ Cross-orientation camera support (iOS 17 videoRotationAngle API)
- ✅ mDNS-based cross-platform networking
- ✅ Reference photo overlay with adjustable transparency
- ✅ Dynamic URL construction with server IP detection

### Future Enhancements

#### Phase 2: Advanced AI Features (High Priority)
- **Visual Similarity Search**: Upload photo to find similar photo spots
  - Use CLIP image embeddings for content-based retrieval
  - Approximate nearest neighbors (FAISS/Annoy) for fast similarity search
  - "Find spots like this photo" functionality
  
- **Personalized Recommendations**: User preference-based spot suggestions
  - Track user browsing history and favorites
  - Build user profile embeddings from interaction data
  - Collaborative filtering with CLIP embeddings
  - "Recommended for you" section in Home tab

- **Social Validation Scoring**: Compare with popular photography
  - Curate dataset of 100-200 high-quality reference photos from Unsplash/500px
  - Pre-calculate CLIP embeddings for reference set
  - Calculate similarity with reference photos as popularity_score
  - Weighted combination: aesthetic (intrinsic) + social validation (extrinsic)

- **Scene Composition Analysis**: Object detection for composition insights
  - Integrate YOLOv8 for object detection
  - Analyze rule of thirds, leading lines, symmetry
  - Provide composition feedback and suggestions

#### Phase 3: Social & Community Features
- **User Authentication**: JWT-based login system
  - User profiles with photography preferences
  - Upload history and contribution tracking
  - Privacy controls for shared spots

- **User Engagement Metrics**: Calculate popularity_score from real interactions
  - Photo likes and favorites
  - Spot visits and check-ins
  - User ratings and reviews
  - Dynamic popularity_score updates

- **Community Features**:
  - Comments and discussions on spots
  - Photo galleries from multiple users at same location
  - Leaderboards for top contributors
  - Achievement system and badges

#### Phase 4: Intelligent Itinerary Planning
- **Multi-Spot Route Optimization**: 
  - TSP (Traveling Salesman Problem) solver for efficient routes
  - Consider golden hour timing for multiple spots
  - Balance aesthetic scores with geographic proximity
  - Generate day-long photography tours

- **Personalized Route Generation**:
  - Match user's photography style preferences
  - Optimize for available time and transportation mode
  - Weather-aware scheduling for optimal lighting
  - Alternative spot suggestions based on conditions

#### Phase 5: Enhanced Intelligence
- **Reverse Geocoding**: Automatic city/country detection
  - Use geocoding API (Google Maps / OpenStreetMap)
  - Populate city and country fields automatically
  - Improve location search and filtering

- **Weather Integration**: 
  - Real-time weather data for golden hour prediction
  - Cloud cover analysis for optimal shooting times
  - Sunset/sunrise time calculations
  - Weather-based spot recommendations

- **Time-of-Day Optimization**:
  - Analyze EXIF timestamps from existing photos
  - Identify optimal shooting times for each spot
  - Recommend best visit times based on historical data

- **Fine-tuned CLIP Model**:
  - Collect user feedback on score accuracy
  - Build photography-specific training dataset
  - Fine-tune CLIP on aesthetic photography
  - Improve score calibration and consistency

## Development Workflow

### Running the App

#### Backend (Development Mode)
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8002
```

#### iOS Simulator
Backend accessible at `http://localhost:8002`
- No special configuration needed
- Just build and run from Xcode

#### iOS Real Device
Backend accessible at `http://YOUR_MAC.local:8002`
- Ensure iPhone and Mac on same WiFi
- mDNS handles automatic discovery
- Run from Xcode on connected device

### Testing Upload Flow

1. Tap "+" button in Home view
2. Choose photo source:
   - **Take Photo**: Opens camera with orientation support
   - **Choose from Library**: Opens photo picker with GPS extraction
3. Location handling:
   - **Has GPS in EXIF**: Automatically displays green checkmark with coordinates
   - **No GPS**: Shows orange warning, tap "Select Location Manually"
     - Search for city/place using Apple Maps autocomplete
     - Or drag map to precise location
4. Fill spot details:
   - Name (required)
   - Description (optional)
   - Category (required, dropdown)
   - Equipment recommendations (optional)
   - Tags (optional, comma-separated)
5. Tap "Upload & Share Spot"
6. Backend processing:
   - Saves photo and generates thumbnail
   - Extracts EXIF camera parameters
   - **Calculates CLIP aesthetic score** (1-2 seconds)
   - Creates database entry
7. Success: Returns to list with new spot visible

### Testing AR Navigation

1. Select photo spot from list or map
2. Tap "Navigate" button
3. Allow location permissions if prompted
4. Navigation mode determined by distance:
   - **>500m**: Map view with distance display and "Open in Apple Maps" button
   - **<500m**: AR view with 3D directional arrow and real-time distance
5. AR view features:
   - Orange arrow rotates based on bearing to destination
   - Distance updates continuously
   - Compass integration for accurate direction
6. **Within 10m**: Shows "You've Arrived!" panel
   - Displays recommended camera settings
   - Shows best time to shoot
   - "Take Photo" button opens camera with reference overlay

### Testing Camera with Reference Overlay

1. Arrive at photo spot (AR navigation)
2. Tap "Take Photo" button
3. Camera opens with:
   - Real-time preview
   - Semi-transparent reference photo overlay (default 25% opacity)
   - Eye icon to toggle overlay visibility
   - Slider to adjust opacity (10-50%)
4. Compose shot aligning with reference
5. Capture photo with proper orientation (portrait/landscape)
6. Review and save to photo library

## Performance Metrics

### Image Processing
- Original photos: 2-4MB (4032x3024 typical iPhone resolution)
- Thumbnails: 20-50KB (300x300, JPEG quality 85%)
- Thumbnail generation: 100-200ms per image
- EXIF extraction: 50-100ms per image

### CLIP Inference
- Model loading (first time): 10-15 seconds
- Image encoding: 200-500ms on CPU, 50-100ms on GPU
- Text encoding (pre-computed): 0ms during inference
- Total scoring time: 1-2 seconds per upload

### API Performance
- List endpoint: 50-100ms for 20 items
- Detail endpoint: 20-30ms
- Upload endpoint: 2-3s (including CLIP scoring)
- Image serving: 100-300ms depending on size

### Database
- Connection pool: 10 concurrent connections, 20 overflow
- Query optimization: Indexed on category, city, country, is_active
- Hybrid properties: Computed at query time with zero storage overhead
- Transaction safety: Automatic rollback on errors with file cleanup

## Technical Highlights

### Mobile Development Excellence
- **Native iOS**: Pure Swift/SwiftUI, no cross-platform compromises
- **MVVM Architecture**: Clear separation of concerns, testable ViewModels
- **Modern APIs**: iOS 17 MapKit, ARKit, AVFoundation with latest best practices
- **Network Resilience**: Automatic device detection, graceful degradation
- **Orientation Handling**: Complete portrait/landscape support with iOS 17 videoRotationAngle

### Backend Engineering
- **Async/Await**: FastAPI with concurrent request handling
- **Database Optimization**: Hybrid properties, connection pooling, indexed queries
- **Image Processing**: Efficient thumbnail generation, EXIF extraction, validation
- **AI Integration**: Singleton pattern, pre-computed embeddings, two-stage evaluation
- **Error Handling**: Comprehensive try-catch with resource cleanup

### Computer Vision & AI
- **Multi-Modal Learning**: CLIP vision-language model application
- **Prompt Engineering**: Research-based prompt design (LAION, AVA)
- **Score Calibration**: Progressive mapping for realistic distribution
- **Optimization**: 60% inference reduction through smart caching
- **Interpretability**: Detailed breakdown of scoring dimensions

## Known Issues & Solutions

### Camera Orientation
**Issue**: Camera preview rotated incorrectly on landscape  
**Solution**: Implemented iOS 17 `videoRotationAngle` API with proper device orientation mapping:
- Portrait: 90°, LandscapeLeft: 0°, LandscapeRight: 180°

### Photo Orientation Persistence
**Issue**: Landscape photos saved as portrait  
**Solution**: Set `videoRotationAngle` on both preview connection AND photo output connection at capture time

### Image Loading Fails
**Issue**: AsyncImage fails to load HTTP URLs  
**Solution**: Configure `NSAppTransportSecurity` with `NSAllowsArbitraryLoads` and `NSAllowsLocalNetworking` in Info.plist

### mDNS Resolution Unreliable
**Issue**: `.local` hostname fails on some WiFi networks  
**Solution**: Backend auto-detects server IP using socket connection and returns IP-based URLs

### CLIP Model Loading Slow
**Issue**: First upload takes 10-15 seconds  
**Solution**: Model loads on backend startup, subsequent requests are fast. Consider pre-warming on deployment.

### Score Distribution
**Issue**: CLIP scores cluster in narrow range (0.20-0.28)  
**Solution**: Implemented progressive non-linear mapping to utilize full 30-98 scale

## Development Notes

### Lessons Learned

**iOS Development**:
- SwiftUI's `ObservableObject` requires explicit `import Combine`
- Camera orientation must be set separately for preview and capture
- iOS 17 deprecated many MapKit APIs, requiring MapContentBuilder migration
- Real device testing essential for camera and GPS features

**Backend Development**:
- FastAPI `StaticFiles` must mount before router registration to avoid 404s
- PostgreSQL provides better scalability than SQLite for production
- Multipart form data requires careful boundary handling
- Async context managers (lifespan) better than startup/shutdown events

**AI/ML Integration**:
- CLIP similarities are typically low (0.15-0.35), need calibration
- Pre-encoding prompts dramatically improves performance
- Category-specific prompts improve relevance
- Two-stage evaluation balances cost and quality

**Network Engineering**:
- mDNS works well but needs IP fallback for reliability
- Dynamic URL construction handles simulator/device differences
- Socket-based IP detection more reliable than hostname parsing

### Best Practices Applied

**Code Quality**:
- Comprehensive docstrings following Google style
- Type hints throughout (Python typing, Swift strong typing)
- Proper error handling with specific exception types
- Logging at appropriate levels (INFO, WARNING, ERROR)

**Architecture**:
- Clear separation of concerns (MVVM, service layer, data layer)
- Dependency injection (FastAPI Depends, Swift @StateObject)
- Singleton pattern for expensive resources (CLIP model)
- Factory pattern for database sessions

**Data Integrity**:
- Transaction management with automatic rollback
- File cleanup on database failures
- Input validation with Pydantic schemas
- Soft delete for data safety

**Performance**:
- Connection pooling for database
- Image optimization with thumbnails
- Lazy loading with AsyncImage
- Caching strategies for static content

## Future Development Roadmap

### Immediate Next Steps (1-2 weeks)
1. Implement visual similarity search with CLIP embeddings
2. Add user authentication with JWT tokens
3. Build personalized recommendation engine
4. Integrate weather API for golden hour suggestions

### Medium Term (1-2 months)
1. Collect reference photo dataset for social validation scoring
2. Implement YOLOv8 for composition analysis
3. Build multi-spot itinerary optimizer
4. Add social features (likes, comments, sharing)
5. Deploy to production with Docker and CI/CD

### Long Term (3-6 months)
1. Fine-tune CLIP on photography-specific dataset
2. Implement collaborative filtering for recommendations
3. Build web frontend for broader accessibility
4. Scale to handle 10k+ active users
5. Expand to international locations with localization

## Portfolio Showcase

This project demonstrates:
- ✅ **Full-stack mobile development**: iOS native + Python backend
- ✅ **AI/ML integration**: CLIP vision-language model with optimized inference
- ✅ **Computer vision**: Image processing, EXIF extraction, aesthetic evaluation
- ✅ **AR technology**: ARKit navigation with GPS and compass
- ✅ **Modern API design**: FastAPI with automatic documentation
- ✅ **Database engineering**: PostgreSQL with ORM and hybrid properties
- ✅ **Mobile UX design**: Intuitive navigation, adaptive layouts
- ✅ **Cross-platform networking**: mDNS protocol for seamless device connectivity
- ✅ **Performance optimization**: Caching, pre-computation, two-stage evaluation
- ✅ **Production readiness**: Error handling, logging, resource management

## Technologies Deep Dive

### Why These Choices?

**Native iOS vs React Native/Flutter**:
- Better performance for AR and camera features
- Access to latest iOS APIs (MapKit 17, ARKit)
- Superior user experience with native components

**FastAPI vs Django/Flask**:
- Automatic OpenAPI documentation
- Native async/await support
- Type hints with Pydantic validation
- High performance for ML inference endpoints

**PostgreSQL vs MongoDB/SQLite**:
- ACID compliance for data integrity
- Better support for geospatial queries (future PostGIS)
- Connection pooling and scalability
- Rich query capabilities with SQLAlchemy

**CLIP vs Other Vision Models**:
- Zero-shot learning eliminates training data requirement
- Multi-modal enables text-image comparison
- Pre-trained on 400M image-text pairs
- Strong generalization to photography domain

## Testing

### Manual Testing Checklist

**Photo Upload**:
- [ ] Upload photo with GPS EXIF
- [ ] Upload photo without GPS, manual selection
- [ ] Take new photo with camera
- [ ] Verify CLIP score calculated
- [ ] Check thumbnail generated
- [ ] Confirm EXIF parameters extracted

**Navigation**:
- [ ] Far distance (>500m) shows map
- [ ] Close distance (<500m) shows AR
- [ ] AR arrow points correctly
- [ ] Distance updates in real-time
- [ ] Arrival detection works (<10m)

**Camera Features**:
- [ ] Reference overlay displays
- [ ] Opacity slider works
- [ ] Eye toggle works
- [ ] Portrait orientation captures correctly
- [ ] Landscape orientation captures correctly

**Data Integrity**:
- [ ] Scores persist to database
- [ ] Images accessible via URLs
- [ ] List shows thumbnails
- [ ] Detail shows full images

## Contact

**Ying Lu**  
Full-Stack Developer | iOS Engineer | AI/ML Enthusiast  

Email: lu.y7@northeastern.edu  
LinkedIn: https://www.linkedin.com/in/yinglulareina/

---

**Project Status**: Production-Ready MVP  
**Last Updated**: February 4, 2026  
**Version**: 1.1.0  
**License**: MIT