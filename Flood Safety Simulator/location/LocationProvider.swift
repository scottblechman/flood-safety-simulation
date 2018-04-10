//
//  Handles Core Location features and delivers updates to the ViewController for gameplay and
//  world handling purposes.
//

import Foundation
import CoreLocation

protocol LocationUpdateProtocol {
    func locationUpdated(location : CLLocation)
    func headingUpdated(heading : CLLocationDirection, accuracy : CLLocationDirection)
}

class LocationProvider: NSObject, CLLocationManagerDelegate {
    
    static let Provider = LocationProvider()
    private let locationManager = CLLocationManager()
    
    private var location: CLLocation?
    private var heading: CLLocationDirection?
    private var accuracy: CLLocationDegrees?
    
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
        locationManager.distanceFilter = 1.0  // In meters.
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    //MARK: - CLLocationManagerDelegate
    
    // Called when a new set of locations is provided to the manager
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        delegate.locationUpdated(location: latestLocation)
    }
    
    // Called when a new heading is provided to the manager
    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.heading = newHeading.trueHeading
        } else {
            self.heading = newHeading.magneticHeading
        }
        
        self.accuracy = newHeading.headingAccuracy
        delegate.headingUpdated(heading: self.heading!, accuracy: newHeading.headingAccuracy)
    }
}
