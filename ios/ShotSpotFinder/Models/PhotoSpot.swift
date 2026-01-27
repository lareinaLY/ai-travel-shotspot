import Foundation

// MARK: - PhotoSpot Model
// Matches the backend API response
struct PhotoSpot: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let city: String?
    let country: String?
    let category: String
    let imageUrl: String?
    let thumbnailUrl: String?
    let aestheticScore: Double
    let popularityScore: Double
    let difficultyLevel: String
    let bestTime: String?
    let equipmentNeeded: String?
    let tags: [String]?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String?
    
    // Computed properties from backend
    let overallScore: Double
    let locationDisplay: String
    
    // Coding keys to match backend's snake_case
    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude
        case city, country, category, tags
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case aestheticScore = "aesthetic_score"
        case popularityScore = "popularity_score"
        case difficultyLevel = "difficulty_level"
        case bestTime = "best_time"
        case equipmentNeeded = "equipment_needed"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case overallScore = "overall_score"
        case locationDisplay = "location_display"
    }
}

// MARK: - API Response Models
struct PhotoSpotListResponse: Codable {
    let total: Int
    let page: Int
    let pageSize: Int
    let spots: [PhotoSpot]
    
    enum CodingKeys: String, CodingKey {
        case total, page, spots
        case pageSize = "page_size"
    }
}
