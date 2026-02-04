import SwiftUI

struct NetworkImage: View {
    let url: String
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 250)
                
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipped()
                    .cornerRadius(16)
                
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Failed to Load Image")
                        .font(.headline)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Text("URL:")
                        .font(.caption2)
                    Text(url)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(height: 250)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageUrl = URL(string: url) else {
            errorMessage = "Invalid URL format"
            isLoading = false
            return
        }
        
        print("Attempting to load image from: \(url)")
        
        var request = URLRequest(url: imageUrl)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Network Error: \(error.localizedDescription)"
                    print("Image load error: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode != 200 {
                        errorMessage = "HTTP \(httpResponse.statusCode)"
                        
                        if let data = data, let body = String(data: data, encoding: .utf8) {
                            print("Error response: \(body)")
                            errorMessage = "HTTP \(httpResponse.statusCode): \(body)"
                        }
                        return
                    }
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                print("Received \(data.count) bytes")
                
                if let loadedImage = UIImage(data: data) {
                    image = loadedImage
                    print("Image loaded successfully: \(loadedImage.size.width)x\(loadedImage.size.height)")
                } else {
                    errorMessage = "Invalid image data"
                    print("Failed to create UIImage from \(data.count) bytes")
                }
            }
        }.resume()
    }
}
