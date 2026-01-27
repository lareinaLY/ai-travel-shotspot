import SwiftUI
import MapKit

// MARK: - Map View (Simplified for iOS 17)
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedSpot: PhotoSpot?
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationView {
            ZStack {
                mapLayer
                selectedSpotCard
                loadingOverlay
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                refreshButton
            }
        }
        .task {
            await viewModel.loadSpots()
        }
    }
    
    // MARK: - View Components (Separated for compiler)
    
    private var mapLayer: some View {
        Map(position: $position) {
            ForEach(viewModel.spots) { spot in
                Annotation(spot.name, coordinate: spotCoordinate(spot)) {
                    markerView(for: spot)
                }
            }
        }
        .mapStyle(.standard)
        .edgesIgnoringSafeArea(.bottom)
    }
    
    @ViewBuilder
    private var selectedSpotCard: some View {
        if let spot = selectedSpot {
            VStack {
                Spacer()
                SpotMapCard(spot: spot) {
                    withAnimation {
                        selectedSpot = nil
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView("Loading spots...")
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
    }
    
    private var refreshButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                Task { await viewModel.loadSpots() }
            }) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func spotCoordinate(_ spot: PhotoSpot) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude)
    }
    
    private func markerView(for spot: PhotoSpot) -> some View {
        SpotMapMarker(spot: spot, isSelected: selectedSpot?.id == spot.id)
            .onTapGesture {
                withAnimation {
                    selectedSpot = spot
                    centerOn(spot: spot)
                }
            }
    }
    
    private func centerOn(spot: PhotoSpot) {
        position = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
}

// MARK: - Map Marker
struct SpotMapMarker: View {
    let spot: PhotoSpot
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            markerCircle
            markerTail
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(), value: isSelected)
    }
    
    private var markerCircle: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.orange : Color.red)
                .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                .shadow(radius: 4)
            
            Image(systemName: "camera.fill")
                .foregroundColor(.white)
                .font(.system(size: isSelected ? 16 : 12))
        }
    }
    
    private var markerTail: some View {
        Triangle()
            .fill(isSelected ? Color.orange : Color.red)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(180))
            .offset(y: -5)
    }
}

// Simple triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Map Card
struct SpotMapCard: View {
    let spot: PhotoSpot
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            dragIndicator
            cardContent
            closeButton
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 20)
        .padding(.horizontal)
    }
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 40, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
    
    private var cardContent: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            spotInfo
            Spacer()
            navigationArrow
        }
        .padding()
    }
    
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 70, height: 70)
            .overlay {
                Image(systemName: "camera.fill")
                    .foregroundColor(.gray)
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
            
            HStack {
                scoreBadge
                categoryBadge
            }
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
    
    private var navigationArrow: some View {
        NavigationLink(destination: SpotDetailView(spot: spot)) {
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
    }
    
    private var closeButton: some View {
        Button(action: onDismiss) {
            HStack {
                Spacer()
                Text("Close")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
        }
    }
}

// MARK: - Rounded Corners Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    MapView()
}
