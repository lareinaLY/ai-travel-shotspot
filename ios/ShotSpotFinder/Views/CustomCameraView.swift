import SwiftUI
import AVFoundation
import Photos
import Combine

// MARK: - Custom Camera View with Orientation Detection
struct CustomCameraView: View {
    let spot: PhotoSpot
    let referenceImageUrl: String?
    
    @StateObject private var camera = CameraManager()
    @StateObject private var orientationObserver = OrientationObserver()
    @State private var capturedImage: UIImage?
    @State private var showingSaveSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            CameraPreview(session: camera.session)
                .edgesIgnoringSafeArea(.all)
            
            if camera.showOverlay, let urlString = referenceImageUrl {
                AsyncImage(url: URL(string: urlString)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.clear
                }
                .opacity(camera.overlayOpacity)
                .allowsHitTesting(false)
            }
            
            if let image = capturedImage {
                capturedPhotoUI(image: image)
            } else if orientationObserver.isLandscape {
                landscapeCameraUI
            } else {
                portraitCameraUI
            }
        }
        .statusBarHidden(true)
        .onAppear {
            camera.checkPermissions()
        }
        .alert("Photo Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") { dismiss() }
        }
    }
    
    // MARK: - Portrait UI
    private var portraitCameraUI: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
                if referenceImageUrl != nil { overlayButton }
            }
            .padding(.horizontal, 24)
            .padding(.top, 50)
            
            Spacer()
            
            Text("Align with the reference")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.black.opacity(0.6))
                .cornerRadius(20)
            
            Spacer()
            
            if camera.showOverlay, referenceImageUrl != nil {
                opacitySlider(vertical: false)
            }
            
            captureButton
                .padding(.bottom, 120)
        }
    }
    
    // MARK: - Landscape UI
    private var landscapeCameraUI: some View {
        HStack(spacing: 0) {
            VStack {
                closeButton.padding(24)
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 20) {
                Spacer()
                
                if referenceImageUrl != nil { overlayButton }
                
                if camera.showOverlay, referenceImageUrl != nil {
                    opacitySlider(vertical: true)
                }
                
                captureButton
                    .padding(.trailing, 50)
                
                Spacer()
            }
            .frame(width: 140)
        }
    }
    
    // MARK: - Components
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
    }
    
    private var overlayButton: some View {
        Button(action: { withAnimation { camera.toggleOverlay() } }) {
            Image(systemName: camera.showOverlay ? "eye.fill" : "eye.slash.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(12)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
    }
    
    private func opacitySlider(vertical: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(camera.overlayOpacity * 100))%")
                .font(.caption2)
                .foregroundColor(.white)
            
            Slider(value: $camera.overlayOpacity, in: 0.1...0.5)
                .frame(width: vertical ? 120 : 200, height: 40)
                .rotationEffect(.degrees(vertical ? -90 : 0))
                .tint(.white)
        }
    }
    
    private var captureButton: some View {
        Button(action: { camera.capturePhoto { capturedImage = $0 } }) {
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 5)
                    .frame(width: 75, height: 75)
                Circle()
                    .fill(Color.white)
                    .frame(width: 63, height: 63)
            }
        }
    }
    
    private func capturedPhotoUI(image: UIImage) -> some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding(20)
                Spacer()
                
                HStack(spacing: 40) {
                    Button("Retake") {
                        withAnimation { capturedImage = nil }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(12)
                    
                    Button("Save") { saveToPhotoLibrary(image: image) }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.bottom, orientationObserver.isLandscape ? 40 : 120)
            }
        }
    }
    
    private func saveToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, _ in
                    DispatchQueue.main.async {
                        if success { showingSaveSuccess = true }
                    }
                }
            }
        }
    }
}

// MARK: - Orientation Observer
class OrientationObserver: ObservableObject {
    @Published var isLandscape = false
    
    init() {
        updateOrientation()
        
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateOrientation()
        }
    }
    
    private func updateOrientation() {
        let orientation = UIDevice.current.orientation
        let newValue = orientation.isLandscape
        
        if newValue != isLandscape {
            isLandscape = newValue
            print("📱 Orientation changed to: \(isLandscape ? "LANDSCAPE ✅" : "PORTRAIT ✅")")
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var showOverlay = true
    @Published var overlayOpacity: Double = 0.25
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var photoCaptureCompletion: ((UIImage) -> Void)?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { _ in }
    }
    
    private func setupCamera() {
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
        } catch {}
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        photoCaptureCompletion = completion
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    func toggleOverlay() {
        showOverlay.toggle()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        DispatchQueue.main.async {
            self.photoCaptureCompletion?(image)
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewView {
        CameraPreviewView(session: session)
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {}
}

class CameraPreviewView: UIView {
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
        
        // Use new iOS 17 API
        if #available(iOS 17.0, *) {
            switch orientation {
            case .portrait:
                connection.videoRotationAngle = 90
            case .portraitUpsideDown:
                connection.videoRotationAngle = 270
            case .landscapeLeft:
                connection.videoRotationAngle = 180
            case .landscapeRight:
                connection.videoRotationAngle = 0
            default:
                break
            }
        } else {
            // Fallback for older iOS
            if connection.isVideoOrientationSupported {
                switch orientation {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeRight
                case .landscapeRight:
                    connection.videoOrientation = .landscapeLeft
                default:
                    break
                }
            }
        }
        
        print("🔄 Video orientation updated for \(orientation.isLandscape ? "landscape" : "portrait")")
    }
}
