//
//  Handles Core Location features and delivers updates to the ViewController for gameplay and
//  world handling purposes.
//

import Foundation
import CoreLocation

class LocationProvider: NSObject, CLLocationManagerDelegate {
    
    static let Provider = LocationProvider()
    private let locationManager = CLLocationManager()
    
    private var location: CLLocation?
    
    var delegate: LocationUpdateProtocol!
    
    override init() {
        print("Initializing location manager")
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
            print("Authorized to enable location")
            // Enable location features
            startLocationUpdates()
            break
        }
    }
    
    func startLocationUpdates() {
        // Slightly redundant; this method is only called when authorized
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            // User has not authorized access to location information.
            return
        }
        
        // Do not start services that aren't available.
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available.
            return
        }
        
        // Configure and start the service.
        print("Starting location updates")
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100.0  // In meters.
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    /*func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        print("Updated location in LocationProvider")
        //location = newLocation
        delegate.locationDidUpdateToLocation(location: newLocation)
    }*/
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        print("Updated location in LocationProvider")
        let latestLocation: CLLocation = locations[locations.count - 1]
        delegate.locationDidUpdateToLocation(location: latestLocation)
    }
}
