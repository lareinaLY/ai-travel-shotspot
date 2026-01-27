import Foundation
import SwiftUI
import Combine
import Combine

// MARK: - Spot List ViewModel
// Manages the state and logic for the photo spots list view
@MainActor
class SpotListViewModel: ObservableObject {
    // Published properties - when these change, views update automatically
    @Published var spots: [PhotoSpot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Pagination
    @Published var currentPage = 1
    @Published var totalSpots = 0
    private let pageSize = 20
    
    // API service
    private let apiService = APIService.shared
    
    // MARK: - Load Spots
    func loadSpots() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchPhotoSpots(
                page: currentPage,
                limit: pageSize
            )
            
            // Update UI on main thread
            self.spots = response.spots
            self.totalSpots = response.total
            
        } catch let error as APIError {
            self.errorMessage = error.errorDescription
        } catch {
            self.errorMessage = "Unknown error occurred"
        }
        
        isLoading = false
    }
    
    // MARK: - Refresh
    func refresh() async {
        currentPage = 1
        await loadSpots()
    }
    
    // MARK: - Load More (Pagination)
    func loadMore() async {
        guard !isLoading else { return }
        guard spots.count < totalSpots else { return }
        
        currentPage += 1
        await loadSpots()
    }
}
