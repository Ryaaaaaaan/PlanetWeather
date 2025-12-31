import Foundation
import CoreLocation

// MARK: - Location Manager

/// Manages user location for Earth weather and astronomical calculations
@MainActor
final class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = LocationManager()
    
    // MARK: - Published Properties
    
    @Published var location: CLLocation?
    @Published var locationName: String = "Ma Position"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - Computed Properties
    
    var latitude: Double {
        location?.coordinate.latitude ?? 48.8566 // Default: Paris
    }
    
    var longitude: Double {
        location?.coordinate.longitude ?? 2.3522
    }
    
    var hasLocation: Bool {
        location != nil
    }
    
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Get current location
    func requestLocation() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        
        isLoading = true
        error = nil
        locationManager.requestLocation()
    }
    
    /// Start continuous location updates
    func startUpdating() {
        guard isAuthorized else {
            requestPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Private Methods
    
    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                if let placemark = placemarks?.first {
                    if let city = placemark.locality {
                        self?.locationName = city
                    } else if let area = placemark.administrativeArea {
                        self?.locationName = area
                    } else if let country = placemark.country {
                        self?.locationName = country
                    }
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        Task { @MainActor in
            self.location = newLocation
            self.isLoading = false
            self.reverseGeocode(newLocation)
            
            if Secrets.enableNetworkLogging {
                print("[Location] Updated: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            self.isLoading = false
            
            if Secrets.enableNetworkLogging {
                print("[Location] Error: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            if self.isAuthorized && self.location == nil {
                self.requestLocation()
            }
        }
    }
}
