//
//  Responsible for rendering game state with ARKit and SceneKit, as well as coordinating model class
//  connections.
//

import UIKit
import SceneKit
import ARKit

import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate, LocationUpdateProtocol {

    @IBOutlet var sceneView: ARSCNView!
    
    // Holds reference IDs for the terrain chunks that should be in memory
    var chunkList = [Chunk]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect location updates
        LocationProvider.Provider.delegate = self
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Do not show statistics, fps, or timing info
        sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/world.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable plane detection
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        return node
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func locationUpdated(location: CLLocation) {
        // Do any chunk updating required at the new location
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        chunkList = ChunkManager.Manager.synchronize(latitude, longitude)
    }
}
