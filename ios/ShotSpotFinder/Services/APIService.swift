import Foundation

// MARK: - API Service
// Handles all network requests to FastAPI backend
class APIService {
    // MARK: - Singleton
    static let shared = APIService()
    
    // Backend URL - change this if your backend runs on different port
    private let baseURL = "http://localhost:8002/api"
    
    private init() {}
    
    // MARK: - Fetch All Spots
    func fetchPhotoSpots(page: Int = 1, limit: Int = 20) async throws -> PhotoSpotListResponse {
        // Build URL with query parameters
        guard var components = URLComponents(string: "\(baseURL)/spots") else {
            throw APIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "skip", value: String((page - 1) * limit)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        // Make request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode JSON
        let decoder = JSONDecoder()
        let spotResponse = try decoder.decode(PhotoSpotListResponse.self, from: data)
        
        return spotResponse
    }
    
    // MARK: - Fetch Single Spot
    func fetchPhotoSpot(id: Int) async throws -> PhotoSpot {
        guard let url = URL(string: "\(baseURL)/spots/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let spot = try decoder.decode(PhotoSpot.self, from: data)
        
        return spot
    }
    
    // MARK: - Search Nearby Spots
    func fetchNearbySpots(latitude: Double, longitude: Double, radiusKm: Double = 10, limit: Int = 10) async throws -> [PhotoSpot] {
        guard var components = URLComponents(string: "\(baseURL)/spots/nearby") else {
            throw APIError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "radius_km", value: String(radiusKm)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let spots = try decoder.decode([PhotoSpot].self, from: data)
        
        return spots
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP Error: \(statusCode)"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        }
    }
}
