import SwiftUI
import ARKit

// MARK: - AR Navigation View
struct ARNavigationView: View {
    let spot: PhotoSpot
    @StateObject private var viewModel = ARViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // AR Camera view
            ARViewContainer(arSession: viewModel.arSession)
                .edgesIgnoringSafeArea(.all)
            
            // Navigation overlay
            VStack {
                // Top info bar
                topInfoBar
                
                Spacer()
                
                // Bottom navigation info
                bottomNavigationPanel
            }
            
            // Close button
            VStack {
                HStack {
                    closeButton
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .onAppear {
            viewModel.targetSpot = spot
            viewModel.startARSession()
        }
        .onDisappear {
            viewModel.pauseARSession()
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
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            
            Text(spot.locationDisplay)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(16)
        }
        .padding(.top, 60)
    }
    
    private var bottomNavigationPanel: some View {
        VStack(spacing: 16) {
            // Distance indicator
            HStack(spacing: 20) {
                // Distance
                VStack {
                    Image(systemName: "location.fill")
                        .font(.title2)
                    Text(distanceText)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Distance")
                        .font(.caption)
                }
                .foregroundColor(.white)
                
                // Direction arrow (placeholder)
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(viewModel.bearing))
                
                // Bearing
                VStack {
                    Image(systemName: "safari")
                        .font(.title2)
                    Text(String(format: "%.0f°", viewModel.bearing))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Bearing")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
            
            // Arrival indicator
            if viewModel.isNearTarget {
                Text("📍 You've arrived at the spot!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(12)
            }
        }
        .padding(.bottom, 40)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    private var distanceText: String {
        let dist = viewModel.distance
        if dist < 1000 {
            return String(format: "%.0fm", dist)
        } else {
            return String(format: "%.1fkm", dist / 1000)
        }
    }
}

// MARK: - AR View Container (UIViewRepresentable)
struct ARViewContainer: UIViewRepresentable {
    let arSession: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.session = arSession
        arView.autoenablesDefaultLighting = true
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Updates handled by ARSession
    }
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
