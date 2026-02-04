import SwiftUI
import PhotosUI
import CoreLocation
import MapKit
import AVFoundation
import Combine

struct UploadSpotView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var showPhotoOptions = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    
    @State private var selectedImage: UIImage?
    @State private var photoLocation: CLLocationCoordinate2D?
    @State private var manualLocationSelection = false
    
    @State private var name = ""
    @State private var description = ""
    @State private var category = "landscape"
    @State private var tags = ""
    @State private var equipment = ""
    
    @State private var isUploading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let categories = ["landscape", "cityscape", "architecture", "nature", "sunset", "night", "wildlife", "other"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    photoSection
                    locationSection
                    formSection
                    uploadButton
                }
                .padding()
            }
            .navigationTitle("Share a Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showPhotoOptions) {
                Button("Take Photo") {
                    checkCameraPermission()
                }
                Button("Choose from Library") {
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoPickerView(selectedImage: $selectedImage, onImageSelected: handleImageSelection)
            }
            .sheet(isPresented: $showCamera) {
                UploadCameraView(image: $selectedImage, isPresented: $showCamera)
            }
            .sheet(isPresented: $manualLocationSelection) {
                ManualLocationSelectionView(
                    selectedLocation: $photoLocation,
                    isPresented: $manualLocationSelection
                )
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your spot has been shared successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: 12) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        Button(action: {
                            selectedImage = nil
                            photoLocation = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                Button(action: {
                    showPhotoOptions = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Text("Add Photo")
                            .font(.headline)
                    }
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
            
            if let location = photoLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Latitude: \(location.latitude, specifier: "%.6f")")
                            .font(.caption)
                        Text("Longitude: \(location.longitude, specifier: "%.6f")")
                            .font(.caption)
                    }
                    Spacer()
                    Button("Change") {
                        manualLocationSelection = true
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else if selectedImage != nil {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.orange)
                        Text("No location found in photo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        manualLocationSelection = true
                    }) {
                        Label("Select Location Manually", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Spot Name")
                    .font(.headline)
                TextField("e.g., Golden Gate at Sunset", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat.capitalized).tag(cat)
                    }
                }
                .pickerStyle(.menu)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Equipment Needed (Optional)")
                    .font(.headline)
                TextField("e.g., Wide-angle lens, tripod", text: $equipment)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags (Optional)")
                    .font(.headline)
                TextField("bridge, sunset, urban", text: $tags)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var uploadButton: some View {
        Button(action: uploadSpot) {
            if isUploading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
            } else {
                Text("Upload & Share Spot")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 50)
        .background(canUpload ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!canUpload || isUploading)
    }
    
    private var canUpload: Bool {
        selectedImage != nil &&
        !name.isEmpty &&
        photoLocation != nil
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    locationManager.requestPermission()
                    showCamera = true
                } else {
                    errorMessage = "Camera permission denied. Please enable it in Settings."
                    showError = true
                }
            }
        }
    }
    
    private func handleImageSelection() {
        guard let image = selectedImage else { return }
        
        if let location = extractGPSLocation(from: image) {
            photoLocation = location
        } else {
            photoLocation = nil
        }
    }
    
    private func extractGPSLocation(from image: UIImage) -> CLLocationCoordinate2D? {
        guard let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gpsInfo = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            return nil
        }
        
        guard let lat = gpsInfo[kCGImagePropertyGPSLatitude as String] as? Double,
              let latRef = gpsInfo[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let lon = gpsInfo[kCGImagePropertyGPSLongitude as String] as? Double,
              let lonRef = gpsInfo[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            return nil
        }
        
        let latitude = latRef == "S" ? -lat : lat
        let longitude = lonRef == "W" ? -lon : lon
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private func uploadSpot() {
        guard let image = selectedImage,
              let location = photoLocation else { return }
        
        isUploading = true
        
        Task {
            do {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw URLError(.badURL)
                }
                
                let boundary = UUID().uuidString
                var request = URLRequest(url: URL(string: "\(APIService.shared.getBaseURL())/upload")!)
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var body = Data()
                
                let fields: [String: String] = [
                    "name": name,
                    "description": description,
                    "latitude": "\(location.latitude)",
                    "longitude": "\(location.longitude)",
                    "category": category,
                    "tags": tags,
                    "equipment_needed": equipment
                ]
                
                for (key, value) in fields {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(value)\r\n".data(using: .utf8)!)
                }
                
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
                
                request.httpBody = body
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 201 else {
                    throw URLError(.badServerResponse)
                }
                
                await MainActor.run {
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Upload failed: \(error.localizedDescription)"
                    showError = true
                }
            }
            
            await MainActor.run {
                isUploading = false
            }
        }
    }
}

// MARK: - Upload Camera View
struct UploadCameraView: View {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    @StateObject private var camera = UploadCameraManager()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            UploadCameraPreview(session: camera.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                Button(action: {
                    camera.capturePhoto { capturedImage in
                        image = capturedImage
                        isPresented = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 5)
                            .frame(width: 75, height: 75)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 63, height: 63)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

// MARK: - Upload Camera Manager
@MainActor
final class UploadCameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCaptureCompletion: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        Task {
            await setupCamera()
        }
    }
    
    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    private func setupCamera() async {
        session.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
            
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCaptureCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        
        // Set photo orientation based on device orientation
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            let deviceOrientation = UIDevice.current.orientation
            
            if #available(iOS 17.0, *) {
                // iOS 17+ uses videoRotationAngle
                switch deviceOrientation {
                case .portrait:
                    photoOutputConnection.videoRotationAngle = 90
                case .portraitUpsideDown:
                    photoOutputConnection.videoRotationAngle = 270
                case .landscapeLeft:
                    photoOutputConnection.videoRotationAngle = 0
                case .landscapeRight:
                    photoOutputConnection.videoRotationAngle = 180
                default:
                    photoOutputConnection.videoRotationAngle = 90
                }
            } else {
                // iOS 16 and below use videoOrientation
                if photoOutputConnection.isVideoOrientationSupported {
                    switch deviceOrientation {
                    case .portrait:
                        photoOutputConnection.videoOrientation = .portrait
                    case .portraitUpsideDown:
                        photoOutputConnection.videoOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        photoOutputConnection.videoOrientation = .landscapeRight
                    case .landscapeRight:
                        photoOutputConnection.videoOrientation = .landscapeLeft
                    default:
                        photoOutputConnection.videoOrientation = .portrait
                    }
                }
            }
            
            print("Capturing with orientation: \(deviceOrientation.isLandscape ? "Landscape" : "Portrait"), angle: \(photoOutputConnection.videoRotationAngle)")
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension UploadCameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        print("Photo captured successfully, size: \(image.size)")
        
        Task { @MainActor in
            self.photoCaptureCompletion?(image)
        }
    }
}

// MARK: - Upload Camera Preview
struct UploadCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UploadCameraUIView {
        UploadCameraUIView(session: session)
    }
    
    func updateUIView(_ uiView: UploadCameraUIView, context: Context) {}
}

// MARK: - Upload Camera UIView
class UploadCameraUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        backgroundColor = .black
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        previewLayer = layer
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        updateVideoOrientation()
    }
    
    @objc private func orientationChanged() {
        updateVideoOrientation()
    }
    
    private func updateVideoOrientation() {
        guard let connection = previewLayer?.connection else { return }
        let orientation = UIDevice.current.orientation
        
        if #available(iOS 17.0, *) {
            // iOS 17+ uses videoRotationAngle
            switch orientation {
            case .portrait:
                connection.videoRotationAngle = 90
            case .portraitUpsideDown:
                connection.videoRotationAngle = 270
            case .landscapeLeft:
                // Left landscape (Home button on left) = 0 degrees
                connection.videoRotationAngle = 0
            case .landscapeRight:
                // Right landscape (Home button on right) = 180 degrees
                connection.videoRotationAngle = 180
            default:
                connection.videoRotationAngle = 90  // Default to portrait
            }
        } else {
            // iOS 16 and below use videoOrientation
            if connection.isVideoOrientationSupported {
                switch orientation {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .portraitUpsideDown:
                    connection.videoOrientation = .portraitUpsideDown
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeRight
                case .landscapeRight:
                    connection.videoOrientation = .landscapeLeft
                default:
                    connection.videoOrientation = .portrait
                }
            }
        }
        
        print("Camera orientation updated: \(orientation.isLandscape ? "Landscape" : "Portrait"), angle: \(connection.videoRotationAngle)")
    }
}

// MARK: - Photo Picker View
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImageSelected: () -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
                parent.onImageSelected()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Manual Location Selection View
struct ManualLocationSelectionView: View {
    @Binding var selectedLocation: CLLocationCoordinate2D?
    @Binding var isPresented: Bool
    @StateObject private var searchViewModel = LocationSearchViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                
                if !searchViewModel.searchResults.isEmpty {
                    searchResultsList
                } else {
                    mapView
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search city or place", text: $searchViewModel.searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onChange(of: searchViewModel.searchText) { _, newValue in
                        searchViewModel.searchLocation(query: newValue)
                    }
                
                if !searchViewModel.searchText.isEmpty {
                    Button(action: {
                        searchViewModel.searchText = ""
                        searchViewModel.searchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            if searchViewModel.isSearching {
                ProgressView()
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var searchResultsList: some View {
        List(searchViewModel.searchResults) { result in
            Button(action: {
                selectSearchResult(result)
            }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(result.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }
    
    private var mapView: some View {
        VStack(spacing: 0) {
            ZStack {
                Map(coordinateRegion: $region, interactionModes: .all)
                
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Spacer()
                }
            }
            
            VStack(spacing: 12) {
                Text("Drag map to select location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Lat: \(region.center.latitude, specifier: "%.6f"), Lon: \(region.center.longitude, specifier: "%.6f")")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Button(action: {
                    selectedLocation = region.center
                    isPresented = false
                }) {
                    Text("Confirm Location")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        searchViewModel.getCoordinate(for: result) { coordinate in
            if let coordinate = coordinate {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                
                searchViewModel.searchText = ""
                searchViewModel.searchResults = []
            }
        }
    }
}

// MARK: - Location Search ViewModel
@MainActor
class LocationSearchViewModel: NSObject, ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false
    
    private let searchCompleter = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    func searchLocation(query: String) {
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            searchCompleter.queryFragment = query
        }
    }
    
    func getCoordinate(for completion: MKLocalSearchCompletion, handler: @escaping (CLLocationCoordinate2D?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                handler(nil)
                return
            }
            handler(coordinate)
        }
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension LocationSearchViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.searchResults = completer.results
            self.isSearching = false
        }
    }
    
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            print("Search error: \(error.localizedDescription)")
            self.isSearching = false
        }
    }
}

// MARK: - MKLocalSearchCompletion Identifiable
extension MKLocalSearchCompletion: Identifiable {
    public var id: String {
        "\(title)-\(subtitle ?? "")"
    }
}

#Preview {
    UploadSpotView()
}
