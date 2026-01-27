import SwiftUI
import Combine

// MARK: - Search View
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Results
                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                    emptyResultsView
                } else if !viewModel.searchResults.isEmpty {
                    resultsList
                } else {
                    placeholderView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search by city or country...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.search()
                    }
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    viewModel.searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    private var resultsList: some View {
        List(viewModel.searchResults) { spot in
            NavigationLink(destination: SpotDetailView(spot: spot)) {
                SpotRowView(spot: spot)
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.headline)
            
            Text("Try searching for a different city")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("Search photo spots")
                .font(.headline)
            
            Text("Enter a city or country name")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Search ViewModel
@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [PhotoSpot] = []
    @Published var isSearching = false
    
    private let apiService = APIService.shared
    
    func search() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        
        do {
            // Use general search parameter
            let response = try await apiService.fetchPhotoSpots(
                page: 1,
                limit: 50,
                search: searchText  // ← 使用通用搜索
            )
            self.searchResults = response.spots
        } catch {
            self.searchResults = []
        }
        
        isSearching = false
    }
}

#Preview {
    SearchView()
}
