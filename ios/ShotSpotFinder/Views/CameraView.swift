import SwiftUI
import Photos

// MARK: - Camera View
struct CameraView: View {
    let spot: PhotoSpot
    @Environment(\.dismiss) var dismiss
    @State private var showingImagePicker = false
    @State private var capturedImage: UIImage?
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    if let image = capturedImage {
                        // Show captured photo
                        capturedPhotoView(image: image)
                    } else {
                        // Camera interface
                        cameraInterfaceView
                    }
                }
            }
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $capturedImage, onImagePicked: {
                    saveToPhotoLibrary()
                })
            }
            .alert("Photo Saved!", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your photo has been saved to the photo library")
            }
        }
    }
    
    private var cameraInterfaceView: some View {
        VStack {
            Spacer()
            
            // Instructions
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Align your shot with the reference")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let equipment = spot.equipmentNeeded {
                    Text(equipment)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
            
            Spacer()
            
            // Capture button
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private func capturedPhotoView(image: UIImage) -> some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .padding()
            
            HStack(spacing: 20) {
                Button("Retake") {
                    capturedImage = nil
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveToPhotoLibrary()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    private func saveToPhotoLibrary() {
        guard let image = capturedImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            showingSaveSuccess = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: () -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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
        imageUrl: "https://example.com/golden-gate.jpg",
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
