//
//  Implemented by the location provider to pass messages to the game logic controller
//

import CoreLocation

protocol LocationUpdateProtocol {
    func locationDidUpdateToLocation(location : CLLocation)
}
