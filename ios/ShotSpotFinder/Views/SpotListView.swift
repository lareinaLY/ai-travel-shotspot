import SwiftUI

// MARK: - Spot List View
struct SpotListView: View {
    @StateObject private var viewModel = SpotListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.spots.isEmpty {
                    // Loading state
                    ProgressView("Loading photo spots...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = viewModel.errorMessage {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if viewModel.spots.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Photo Spots")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start by adding some photo spots from the backend")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    // List of spots
                    List(viewModel.spots) { spot in
                        NavigationLink(destination: SpotDetailView(spot: spot)) {
                                SpotRowView(spot: spot)
                            }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Photo Spots")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
        }
        .task {
            // Load data when view appears
            await viewModel.loadSpots()
        }
    }
}

// MARK: - Spot Row View
struct SpotRowView: View {
    let spot: PhotoSpot
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.gray)
                }
            
            // Spot info
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(spot.locationDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    // Overall score badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text(String(format: "%.1f", spot.overallScore))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    
                    // Category tag
                    Text(spot.category.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    SpotListView()
}
