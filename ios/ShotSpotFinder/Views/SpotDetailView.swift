import SwiftUI
import MapKit

// MARK: - Spot Detail View
struct SpotDetailView: View {
    let spot: PhotoSpot
    
    // Camera region for map
    @State private var region: MKCoordinateRegion
    
    init(spot: PhotoSpot) {
        self.spot = spot
        
        // Initialize map region centered on spot
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: spot.latitude,
                longitude: spot.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image placeholder
                heroImageSection
                
                // Title and location
                titleSection
                
                // Scores
                scoresSection
                
                // Map preview
                mapSection
                
                // Details
                detailsSection
                
                // Tags
                if let tags = spot.tags, !tags.isEmpty {
                    tagsSection(tags: tags)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - View Components
    
    private var heroImageSection: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [Color.orange.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 250)
            .overlay {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Photo will load here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(spot.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                Text(spot.locationDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var scoresSection: some View {
        HStack(spacing: 20) {
            // Overall score
            ScoreCard(
                title: "Overall",
                score: spot.overallScore,
                color: .orange,
                icon: "star.fill"
            )
            
            // Aesthetic score
            ScoreCard(
                title: "Aesthetic",
                score: spot.aestheticScore,
                color: .purple,
                icon: "sparkles"
            )
            
            // Popularity score
            ScoreCard(
                title: "Popularity",
                score: spot.popularityScore,
                color: .blue,
                icon: "heart.fill"
            )
        }
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
            
            Map(coordinateRegion: $region, annotationItems: [spot]) { spot in
                MapMarker(
                    coordinate: CLLocationCoordinate2D(
                        latitude: spot.latitude,
                        longitude: spot.longitude
                    ),
                    tint: .red
                )
            }
            .frame(height: 200)
            .cornerRadius(12)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.secondary)
                Text("Lat: \(String(format: "%.4f", spot.latitude)), Lon: \(String(format: "%.4f", spot.longitude))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            if let description = spot.description {
                DetailRow(
                    icon: "text.alignleft",
                    title: "Description",
                    content: description,
                    color: .blue
                )
            }
            
            // Category
            DetailRow(
                icon: "square.grid.2x2",
                title: "Category",
                content: spot.category.capitalized,
                color: .green
            )
            
            // Best time
            if let bestTime = spot.bestTime {
                DetailRow(
                    icon: "clock.fill",
                    title: "Best Time",
                    content: bestTime.replacingOccurrences(of: "_", with: " ").capitalized,
                    color: .orange
                )
            }
            
            // Difficulty
            DetailRow(
                icon: "figure.hiking",
                title: "Difficulty",
                content: spot.difficultyLevel.capitalized,
                color: difficultyColor(spot.difficultyLevel)
            )
            
            // Equipment
            if let equipment = spot.equipmentNeeded {
                DetailRow(
                    icon: "camera.metering.matrix",
                    title: "Equipment Needed",
                    content: equipment,
                    color: .purple
                )
            }
        }
    }
    
    private func tagsSection(tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundColor(.secondary)
                Text("Tags")
                    .font(.headline)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
        }
    }
    
    // Helper function
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy": return .green
        case "moderate": return .orange
        case "hard": return .red
        default: return .gray
        }
    }
}

// MARK: - Score Card Component
struct ScoreCard: View {
    let title: String
    let score: Double
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(String(format: "%.1f", score))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        SpotDetailView(spot: PhotoSpot(
            id: 1,
            name: "Golden Gate Bridge",
            description: "Iconic suspension bridge with stunning views of San Francisco Bay.",
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
            equipmentNeeded: "Wide-angle lens, tripod",
            tags: ["bridge", "iconic", "sunset"],
            isActive: true,
            createdAt: "2025-01-26T12:00:00Z",
            updatedAt: nil,
            overallScore: 92.2,
            locationDisplay: "San Francisco, USA"
        ))
    }
}
