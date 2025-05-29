import CoreLocation
import MapKit

protocol LocationServiceProtocol: AnyObject {
    var currentLocation: CLLocation? { get }
    var locationAuthorizationStatus: CLAuthorizationStatus { get }
    var onLocationUpdate: ((CLLocation) -> Void)? { get set }
    var onAuthorizationStatusChange: ((CLAuthorizationStatus) -> Void)? { get set }
    
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func checkLocationAuthorization()
}

@Observable final class LocationService: NSObject, LocationServiceProtocol {
    private let locationManager: CLLocationManager
    private(set) var currentLocation: CLLocation?
    private(set) var locationAuthorizationStatus: CLAuthorizationStatus
    
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onAuthorizationStatusChange: ((CLAuthorizationStatus) -> Void)?
    
    override init() {
        locationManager = CLLocationManager()
        locationAuthorizationStatus = locationManager.authorizationStatus
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        
        print("LocationService initialized with authorization status: \(locationManager.authorizationStatus.rawValue)")
        
        // Check authorization status on init
        checkLocationAuthorization()
    }
    
    func requestLocationPermission() {
        print("Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        print("Starting location updates...")
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("Stopping location updates...")
        locationManager.stopUpdatingLocation()
    }
    
    func checkLocationAuthorization() {
        print("Checking location authorization...")
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location authorized, starting updates")
            locationManager.startUpdatingLocation()
        case .notDetermined:
            print("Location authorization not determined, requesting permission")
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        @unknown default:
            print("Unknown authorization status")
            break
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization changed to: \(manager.authorizationStatus.rawValue)")
        locationAuthorizationStatus = manager.authorizationStatus
        onAuthorizationStatusChange?(manager.authorizationStatus)
        
        // Check if we should start updating location
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            print("Authorization granted, starting location updates")
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLocation = location
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        
        // If we get a location error, try to restart location updates
        if let error = error as? CLError {
            switch error.code {
            case .denied, .locationUnknown:
                print("Location access denied or unknown")
                break
            default:
                print("Attempting to restart location updates after error")
                manager.startUpdatingLocation()
            }
        }
    }
} 