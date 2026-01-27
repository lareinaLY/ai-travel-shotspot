import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            // Main app content
            if !showSplash {
                mainContent
            }
            
            // Splash screen overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Hide splash after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
    
    private var mainContent: some View {
        TabView {
            // Home tab (new!)
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // All spots list
            SpotListView()
                .tabItem {
                    Label("All", systemImage: "list.bullet")
                }
            
            // Map tab
            MapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
