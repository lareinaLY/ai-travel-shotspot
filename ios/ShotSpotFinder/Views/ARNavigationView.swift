import SwiftUI
import ARKit
import CoreLocation

// MARK: - AR Navigation View
struct ARNavigationView: View {
    let spot: PhotoSpot
    @StateObject private var locationManager = LocationManager()
    @State private var arViewModel = ARSessionManager()
    @State private var distance: CLLocationDistance = 0
    @State private var bearing: Double = 0
    @State private var hasArrived = false
    @State private var showCamera = false
    @Environment(\.dismiss) var dismiss
    
    private let arrivalThreshold: Double = 1000000.0  // for testing
    
    var body: some View {
        ZStack {
            // AR Camera Feed
            ARViewContainer(session: arViewModel.session)
                .edgesIgnoringSafeArea(.all)
            
            // Sample photo overlay (when arrived)
            if hasArrived, let imageUrl = spot.imageUrl {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.clear
                }
                .opacity(0.3)
                .allowsHitTesting(false)
            }
            
            // Navigation UI
            VStack {
                topInfoBar
                Spacer()
                if !hasArrived {
                    navigationPanel
                } else {
                    arrivedPanel
                }
            }
            
            // Close button
            closeButton
        }
        .onAppear {
            setupARSession()
            
            // Force arrival for testing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("🎯 Forcing arrival state for UI testing")
                hasArrived = true
                distance = 5.0
                print("✅ hasArrived set to: \(hasArrived)")
            }
        }
        .onDisappear {
            cleanupARSession()
        }
        .onChange(of: locationManager.userLocation) { oldValue, newValue in
            updateNavigationData()
        }
        .fullScreenCover(isPresented: $showCamera) {  // fullScreenCover
            CustomCameraView(spot: spot, referenceImageUrl: spot.imageUrl)
        }
    }
    
    // MARK: - UI Components
    
    private var topInfoBar: some View {
        VStack(spacing: 8) {
            Text(spot.name)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
            
            Text(spot.locationDisplay)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)
        }
        .padding(.top, 60)
    }
    
    private var navigationPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .rotationEffect(.degrees(bearing - (locationManager.heading?.trueHeading ?? 0)))
                .shadow(radius: 10)
            
            VStack(spacing: 4) {
                Text(distanceText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                
                Text("to destination")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
        }
        .padding(.bottom, 40)
    }
    
    private var arrivedPanel: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                Text("You've Arrived!")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.green.opacity(0.9))
            .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Settings:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let bestTime = spot.bestTime {
                    HStack {
                        Image(systemName: "sun.horizon.fill")
                            .foregroundColor(.orange)
                        Text("Best time: \(bestTime.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                
                if let equipment = spot.equipmentNeeded {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.orange)
                        Text(equipment)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Button(action: {
                showCamera = true
            }) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }
    
    private var closeButton: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding()
                Spacer()
            }
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private var distanceText: String {
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    private func setupARSession() {
        locationManager.requestPermission()
        locationManager.startUpdating()
        arViewModel.startSession()
    }
    
    private func cleanupARSession() {
        locationManager.stopUpdating()
        arViewModel.stopSession()
    }
    
    private func updateNavigationData() {
        print("🔄 Updating navigation data...")
        
        if let dist = locationManager.distance(to: spot) {
            distance = dist
            hasArrived = dist < arrivalThreshold
            
            print("📏 Distance: \(dist)m")
            print("🎯 Threshold: \(arrivalThreshold)m")
            print("✅ Has arrived: \(hasArrived)")
        }
        
        if let bear = locationManager.bearing(to: spot) {
            bearing = bear
            print("🧭 Bearing: \(bear)°")
        }
    }
}

// MARK: - AR Session Manager
class ARSessionManager {
    let session = ARSession()
    
    func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func stopSession() {
        session.pause()
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    let session: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session = session
        arView.autoenablesDefaultLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

#Preview {
    ARNavigationView(spot: PhotoSpot(
        id: 1,
        name: "Golden Gate Bridge",
        description: "Test",
        latitude: 37.8199,
        longitude: -122.4783,
        city: "San Francisco",
        country: "USA",
        category: "landscape",
        imageUrl: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/GoldenGateBridge-001.jpg/800px-GoldenGateBridge-001.jpg",
        thumbnailUrl: nil,
        aestheticScore: 95.0,
        popularityScore: 88.0,
        difficultyLevel: "easy",
        bestTime: "golden_hour",
        equipmentNeeded: "Wide-angle lens, tripod",
        tags: ["bridge"],
        isActive: true,
        createdAt: "2025-01-26T12:00:00Z",
        updatedAt: nil,
        overallScore: 92.2,
        locationDisplay: "San Francisco, USA"
    ))
}
