import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var heading: CLHeading?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5  // Update every 5 meters
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    // Calculate distance to spot
    func distance(to spot: PhotoSpot) -> CLLocationDistance? {
        guard let userLoc = userLocation else { return nil }
        
        let spotLocation = CLLocation(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
        
        return userLoc.distance(from: spotLocation)
    }
    
    // Calculate bearing to spot
    func bearing(to spot: PhotoSpot) -> Double? {
        guard let userLoc = userLocation else { return nil }
        
        let lat1 = userLoc.coordinate.latitude * .pi / 180
        let lon1 = userLoc.coordinate.longitude * .pi / 180
        let lat2 = spot.latitude * .pi / 180
        let lon2 = spot.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return (bearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
