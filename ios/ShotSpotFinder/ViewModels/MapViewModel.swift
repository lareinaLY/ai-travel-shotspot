import Foundation
import SwiftUI
import MapKit
import Combine

// MARK: - Map ViewModel
@MainActor
class MapViewModel: ObservableObject {
    @Published var spots: [PhotoSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Map region
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    private let apiService = APIService.shared
    
    // MARK: - Load All Spots
    func loadSpots() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchPhotoSpots(page: 1, limit: 100)
            self.spots = response.spots
            
            // Auto-fit map to show all spots
            if !spots.isEmpty {
                centerMapOnSpots()
            }
            
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Unknown error occurred"
        }
        
        isLoading = false
    }
    
    // MARK: - Center Map on All Spots
    private func centerMapOnSpots() {
        guard !spots.isEmpty else { return }
        
        var minLat = spots[0].latitude
        var maxLat = spots[0].latitude
        var minLon = spots[0].longitude
        var maxLon = spots[0].longitude
        
        for spot in spots {
            minLat = min(minLat, spot.latitude)
            maxLat = max(maxLat, spot.latitude)
            minLon = min(minLon, spot.longitude)
            maxLon = max(maxLon, spot.longitude)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat = (maxLat - minLat) * 1.5  // Add 50% padding
        let spanLon = (maxLon - minLon) * 1.5
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: max(spanLat, 0.1), longitudeDelta: max(spanLon, 0.1))
        )
    }
    
    // MARK: - Center on Specific Spot
    func centerOn(spot: PhotoSpot) {
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
}
