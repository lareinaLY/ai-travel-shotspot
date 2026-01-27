import Foundation
import SwiftUI
import Combine

// MARK: - Home ViewModel
@MainActor
class HomeViewModel: ObservableObject {
    @Published var hotSpots: [PhotoSpot] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - Load Hot Spots
    func loadHotSpots() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch top spots sorted by overall score
            let response = try await apiService.fetchPhotoSpots(page: 1, limit: 10)
            
            // Sort by overall score (highest first)
            self.hotSpots = response.spots.sorted { $0.overallScore > $1.overallScore }
            
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Failed to load hot spots"
        }
        
        isLoading = false
    }
    
    // MARK: - Search (placeholder for now)
    func search() {
        // Will implement search functionality later
        print("Searching for: \(searchText)")
    }
}
