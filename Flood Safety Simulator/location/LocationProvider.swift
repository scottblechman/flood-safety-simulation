//
//  Handles Core Location features and delivers updates to the ViewController for gameplay and
//  world handling purposes.
//

import Foundation
import CoreLocation

protocol LocationUpdateProtocol {
    func locationUpdated(location : CLLocation)
}

class LocationProvider: NSObject, CLLocationManagerDelegate {
    
    static let Provider = LocationProvider()
    private let locationManager = CLLocationManager()
    
    private var location: CLLocation?
    
    var delegate: LocationUpdateProtocol!
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
        
        // Begin location updates if authorized, and do authorization if not
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            stopLocationUpdates()
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Enable location features
            startLocationUpdates()
            break
        }
    }
    
    func startLocationUpdates() {
        // Check before calling location manager that services are enabled on device.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            return
        }
        
        // Configure and start the service.
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100.0  // In meters.
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        delegate.locationUpdated(location: latestLocation)
    }
}
