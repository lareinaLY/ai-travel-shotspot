import SwiftUI

struct SpotListView: View {
    @StateObject private var viewModel = SpotListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.spots.isEmpty {
                    ProgressView("Loading photo spots...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.spots.isEmpty {
                    emptyView
                } else {
                    spotsList
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
            await viewModel.loadSpots()
        }
    }
    
    private var spotsList: some View {
        List(viewModel.spots) { spot in
            NavigationLink(destination: SpotDetailView(spot: spot)) {
                SpotRowView(spot: spot)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No photo spots yet")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct SpotRowView: View {
    let spot: PhotoSpot
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailView
            spotInfo
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var thumbnailView: some View {
        Group {
            if let imageUrl = spot.thumbnailUrl ?? spot.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                            .background(Color.gray.opacity(0.2))
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.gray)
                    }
            }
        }
    }
    
    private var spotInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(.headline)
                .lineLimit(2)
            
            Text(spot.locationDisplay)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                scoreBadge
                categoryBadge
            }
            .padding(.top, 4)
        }
    }
    
    private var scoreBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text(String(format: "%.1f", spot.overallScore))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.orange)
    }
    
    private var categoryBadge: some View {
        Text(spot.category.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

#Preview {
    SpotListView()
}
