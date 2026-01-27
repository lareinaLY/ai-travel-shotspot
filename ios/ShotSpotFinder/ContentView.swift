import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // List tab
            SpotListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
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
