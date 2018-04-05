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
    
    // Current location of the device
    var location: CLLocation? = nil
    
    // Scene attached to the main AR Scene View
    let scene = SCNScene(named: "art.scnassets/world.scn")!
    
    // temp flag while rendering rect geometries
    var testRenderFlag: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect location update messages to ViewController
        LocationProvider.Provider.delegate = self
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Hide statistics, fps, and timing info
        sceneView.showsStatistics = false
        
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
        // Might want to scale back model rendering here, if possible.
    }

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    /*func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        return node
    }*/

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - LocationUpdateProtocol
    
    func locationUpdated(location: CLLocation) {
        self.location = location
        
        // Do any chunk updating required at the new location
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        print("Updated location to \(latitude), \(longitude)")
        
        let newChunkList = ChunkManager.Manager.update(latitude, longitude)
        print("Got new chunks")
        synchronize(old: self.chunkList, new: newChunkList)
    }
    
    // MARK: - ARSCNViewManager
    
    func addModelFile(world: SCNScene, chunk: Chunk, position: SCNVector3) {
        let geometry = SCNScene(named: "art.scnassets/collada_chunks/chunk_\(chunk.gridX)_\(chunk.gridY).dae")
        let node: SCNNode = (geometry?.rootNode.childNodes[0])!
        node.name = "chunk_\(chunk.gridX)_\(chunk.gridY)"
        world.rootNode.addChildNode(node)
    }
    
    func removeModelFile(world: SCNScene, chunkId: String) {
        //let geoScene = SCNScene(named: "art.scnassets/ball.dae")
        //scene.rootNode.addChildNode(geoScene!.rootNode.childNode(withName: "Ball", recursively: true)!)
        let node = scene.rootNode.childNode(withName: chunkId, recursively: true)
        
        node?.removeFromParentNode()
    }
    
    // Loads a model file from the terrain assets associated with the provided chunk, and
    // anchors the model in virtual space over the real-world terrain
    func addChunkGeometry(_ scene: SCNScene, _ chunk: Chunk) {
        let translationPointX = (chunk.geoAnchor.0, self.location!.coordinate.longitude)
        let translationPointZ = (self.location!.coordinate.latitude, chunk.geoAnchor.1)
        
        let translationX = vectorTo(tail: self.location!.coordinate, head: translationPointX)
        let translationZ = vectorTo(tail: self.location!.coordinate, head: translationPointZ)
        
        // Determine the elevation for each chunk by determining its anchor elevation
        // to the current elevation
        let elevationZero = -self.location!.altitude
        let translationY = elevationZero + chunk.anchorElevation

        // SceneKit/AR coordinates are in meters
        let position = SCNVector3(translationX, translationY, translationZ)
        addModelFile(world: scene, chunk: chunk, position: position)
    }
    
    func removeChunkGeometry(_ scene: SCNScene, _ chunk: Chunk) {
        let chunkIdentifier = "chunk_\(chunk.gridX)_\(chunk.gridY)"
        removeModelFile(world: scene, chunkId: chunkIdentifier)
    }
    
    // Provides a negative or positive distance, in meters, to translate an initial point
    // (the lat/lon location of the device), to a terminal point (the intended chunk origin)
    func vectorTo(tail: CLLocationCoordinate2D, head: (Double, Double)) -> Double {
        // Radius of the Earth, in KM
        let Radius = 6378.137
        
        let dLat = head.0 * Double.pi / 180 - tail.latitude * Double.pi / 180
        let dLon = head.1 * Double.pi / 180 - tail.longitude * Double.pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(tail.latitude * Double.pi / 180) *
            cos(head.0 * Double.pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        
        var c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        // Determine pos or neg translation
        if(head.1 < tail.longitude || head.0 > tail.latitude) {
            c *= -1
        }
        
        return Radius * c * 1000
    }
    
    // Compares the current standing list of active chunks to a pending updated list. Adds,
    // retains, or removes chunk geometries based on the list comparison.
    func synchronize(old: [Chunk], new: [Chunk]) {
        print("Old chunks: \(old)\nNew chunks:")
        for chunk in new {
            print("\(chunk.gridX), \(chunk.gridY)")
        }
        let tempList = new
        for oldChunk in old {
            var match = false
            for newChunk in new {
                if oldChunk == newChunk {
                    match = true
                }
            }
            if !match {
                removeChunkGeometry(scene, oldChunk)
            }
        }
        for chunk in new {
            addChunkGeometry(scene, chunk)
        }
        chunkList = tempList
    }
}
