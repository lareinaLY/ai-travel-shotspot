import Foundation
import SwiftUI
import ARKit
import CoreLocation
import Combine

// MARK: - AR ViewModel
@MainActor
class ARViewModel: NSObject, ObservableObject {
    // AR Session
    let arSession = ARSession()
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Published state
    @Published var isARAvailable = ARWorldTrackingConfiguration.isSupported
    @Published var userLocation: CLLocation?
    @Published var targetSpot: PhotoSpot?
    @Published var distance: Double = 0.0  // meters
    @Published var bearing: Double = 0.0   // degrees
    @Published var isNearTarget = false    // within 10 meters
    
    // AR session state
    @Published var sessionState: ARSessionState = .notStarted
    
    enum ARSessionState {
        case notStarted
        case running
        case paused
        case failed(String)
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Location Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - AR Session Control
    func startARSession() {
        guard isARAvailable else {
            sessionState = .failed("AR is not supported on this device")
            return
        }
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        
        // Start session
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Start location updates
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        sessionState = .running
    }
    
    func pauseARSession() {
        arSession.pause()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        sessionState = .paused
    }
    
    // MARK: - Calculate Navigation Data
    func updateNavigationData() {
        guard let userLoc = userLocation,
              let target = targetSpot else { return }
        
        let targetLocation = CLLocation(
            latitude: target.latitude,
            longitude: target.longitude
        )
        
        // Calculate distance
        distance = userLoc.distance(from: targetLocation)
        
        // Calculate bearing
        bearing = calculateBearing(from: userLoc.coordinate, to: targetLocation.coordinate)
        
        // Check if near target (within 10 meters)
        isNearTarget = distance < 10.0
    }
    
    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}

// MARK: - Location Manager Delegate
extension ARViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        updateNavigationData()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Heading updates (for compass direction)
        updateNavigationData()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
