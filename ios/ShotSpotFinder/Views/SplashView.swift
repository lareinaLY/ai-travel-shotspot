import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // App icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(radius: 20)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                }
                .scaleEffect(scale)
                
                // App name
                VStack(spacing: 8) {
                    Text("AI Travel")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("ShotSpot Finder")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            // Animation on appear
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
