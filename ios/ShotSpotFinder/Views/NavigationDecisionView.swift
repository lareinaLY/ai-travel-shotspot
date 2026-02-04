import SwiftUI
import CoreLocation
import MapKit

// MARK: - Navigation Decision View
struct NavigationDecisionView: View {
    let spot: PhotoSpot
    @StateObject private var locationManager = LocationManager()
    @State private var distance: CLLocationDistance?
    @Environment(\.dismiss) var dismiss
    
    private let arThreshold: Double = 500.0
    
    var body: some View {
        Group {
            if let dist = distance {
                if dist > arThreshold {
                    MapNavigationView(spot: spot, distance: dist)
                } else {
                    ARNavigationView(spot: spot)
                }
            } else {
                loadingView
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.startUpdating()
        }
        .onDisappear {
            locationManager.stopUpdating()
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            updateDistance()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Getting your location...")
                .font(.headline)
            
            Text("Please allow location access")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func updateDistance() {
        distance = locationManager.distance(to: spot)
    }
}

// MARK: - Map Navigation View
struct MapNavigationView: View {
    let spot: PhotoSpot
    let distance: CLLocationDistance
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text(distanceText)
                    .font(.system(size: 48, weight: .bold))
                
                Text("to \(spot.name)")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("Get closer to unlock AR navigation")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Image(systemName: "arkit")
                        .foregroundColor(.orange)
                    Text("AR unlocks at 500m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button(action: openInMaps) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open in Apple Maps")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Navigate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    private var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spot.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

#Preview {
    NavigationDecisionView(spot: PhotoSpot(
        id: 1,
        name: "Golden Gate Bridge",
        description: "Test",
        latitude: 37.8199,
        longitude: -122.4783,
        city: "San Francisco",
        country: "USA",
        category: "landscape",
        imageUrl: nil,
        thumbnailUrl: nil,
        aestheticScore: 95.0,
        popularityScore: 88.0,
        difficultyLevel: "easy",
        bestTime: "golden_hour",
        equipmentNeeded: "Wide-angle lens",
        tags: ["bridge"],
        isActive: true,
        createdAt: "2025-01-26T12:00:00Z",
        updatedAt: nil,
        overallScore: 92.2,
        locationDisplay: "San Francisco, USA"
    ))
}
