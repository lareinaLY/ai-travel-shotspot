import Foundation

// MARK: - API Service
// Handles all network requests to FastAPI backend
// Auto-detects simulator vs real device for URL configuration
class APIService {
    // MARK: - Singleton
    static let shared = APIService()
    
    // Auto-detect base URL based on device type
    func getBaseURL() -> String {
        return baseURL
    }

    private var baseURL: String {
        #if targetEnvironment(simulator)
        // Running on iOS Simulator - use localhost
        return "http://localhost:8002/api"
        #else
        // Running on real iPhone - use Mac's Bonjour hostname
        return "http://JFHNWJJXGX.local:8002/api"
        #endif
    }
    
    private init() {
        // Print base URL for debugging
        print("🌐 API Base URL: \(baseURL)")
    }
    
    // MARK: - Fetch All Spots (with search and filters)
    func fetchPhotoSpots(
        page: Int = 1,
        limit: Int = 20,
        search: String? = nil,
        city: String? = nil,
        category: String? = nil,
        country: String? = nil
    ) async throws -> PhotoSpotListResponse {
        guard var components = URLComponents(string: "\(baseURL)/spots") else {
            throw APIError.invalidURL
        }
        
        var queryItems = [
            URLQueryItem(name: "skip", value: String((page - 1) * limit)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        // Add search parameter (searches name, city, country)
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        // Add specific filter parameters if provided
        if let city = city, !city.isEmpty {
            queryItems.append(URLQueryItem(name: "city", value: city))
        }
        if let category = category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let country = country, !country.isEmpty {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        print("📡 Fetching spots: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let spotResponse = try decoder.decode(PhotoSpotListResponse.self, from: data)
        
        return spotResponse
    }
    
    // MARK: - Fetch Single Spot
    func fetchPhotoSpot(id: Int) async throws -> PhotoSpot {
        guard let url = URL(string: "\(baseURL)/spots/\(id)") else {
            throw APIError.invalidURL
        }
        
        print("📡 Fetching spot \(id): \(url)")
        
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
    func fetchNearbySpots(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 10,
        limit: Int = 10
    ) async throws -> [PhotoSpot] {
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
        
        print("📡 Fetching nearby spots: \(url)")
        
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
