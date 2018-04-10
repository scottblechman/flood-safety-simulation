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
    
    // Current heading of the device
    var heading: CLLocationDirection? = nil
    
    // Corrected for initial rotation by 90º
    var trueHeading: Double = 0
    
    // Scene attached to the main AR Scene View
    let scene = SCNScene(named: "art.scnassets/world.scn")!
    
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
    
    // Called automatically when a new location is provided. Allows to check the user's
    // location in order to refresh the world chunks close to the user.
    func locationUpdated(location: CLLocation) {
        self.location = location
        
        // Do any chunk updating required at the new location
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        print("Updated location to \(latitude), \(longitude)")
        
        let newChunkList = ChunkManager.Manager.update(latitude, longitude)
        
        if heading != nil {
            synchronize(old: self.chunkList, new: newChunkList)
        }
    }
    
    // Called automatically when a new location is provided. Allows to update the device's
    // heading (and true north-facing heading) to properly position chunks in the 3D space.
    func headingUpdated(heading: CLLocationDirection, accuracy: CLLocationDirection) {
        self.heading = heading
        self.trueHeading = (heading.magnitude + 90).truncatingRemainder(dividingBy: 360)
    }
    
    // MARK: - ARSCNViewManager
    
    // Configures a chunk of terrain geometry from a model file to be properly positioned
    // in the 3D scene.
    func addModelFile(world: SCNScene, chunk: Chunk, position: SCNVector3) {
        let geometry = SCNScene(named: "art.scnassets/collada_chunks/chunk_\(chunk.gridX)_\(chunk.gridY).dae")
        let node: SCNNode = (geometry?.rootNode.childNodes[0])!
        node.name = "chunk_\(chunk.gridX)_\(chunk.gridY)"
        print("Position of \(node.name ?? "chunk") fixed to \(position.x), \(position.y), \(position.z)")
        node.position = position
        
        // normalize the rotation of the geometry loaded from the .dae file
        let alignedHeading = Float((self.trueHeading * -1) * Double.pi / 180.0)
        
        let xAngle = SCNMatrix4MakeRotation(Float.pi/2, 1, 0, 0)
        let yAngle = SCNMatrix4MakeRotation(0, 0, 1, 0)
        let zAngle = SCNMatrix4MakeRotation(0, 0, 0, 1)
        let rotationMatrix = SCNMatrix4Mult(SCNMatrix4Mult(xAngle, yAngle), zAngle)
        node.pivot = SCNMatrix4Mult(rotationMatrix, node.transform)
        
        // TODO: change scale of node to fit documentation
        node.scale = SCNVector3(x: 4180.0, y: 1.0, z: 3983.42)
        
        world.rootNode.addChildNode(node)
    }
    
    // Removes chunks no longer close enough to the user to require rendering from the
    // scene to improve memory impact.
    func removeModelFile(world: SCNScene, chunkId: String) {
        let node = scene.rootNode.childNode(withName: chunkId, recursively: true)
        node?.removeFromParentNode()
    }
    
    // Loads a model file from the terrain assets associated with the provided chunk, and
    // anchors the model in virtual space over the real-world terrain
    func addChunkGeometry(_ scene: SCNScene, _ chunk: Chunk) {
        let translationPointX = (chunk.geoAnchor.0, self.location!.coordinate.longitude)
        let translationPointZ = (self.location!.coordinate.latitude, chunk.geoAnchor.1)
        
        print("Translation points are x: \(translationPointX), z: \(translationPointZ)")
        
        let translationX = vectorTo(tail: self.location!.coordinate, head: translationPointX)
        let translationZ = vectorTo(tail: self.location!.coordinate, head: translationPointZ)
        
        print("Translation vectors are x: \(translationX) z: \(translationZ)")
        
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
        /*let Radius = 6378.137
        
        let dLat = head.0 * Double.pi / 180 - tail.latitude * Double.pi / 180
        let dLon = head.1 * Double.pi / 180 - tail.longitude * Double.pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(tail.latitude * Double.pi / 180) *
            cos(head.0 * Double.pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        
        var c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        // Determine pos or neg translation
        if(head.1 < tail.longitude || head.0 > tail.latitude) {
            c *= -1
        }
        
        return Radius * c * 1000*/
        let dist = sqrt(pow(head.0-tail.longitude, 2)+pow(head.1-tail.latitude, 2))
        return abs(dist)
    }
    
    // Compares the current standing list of active chunks to a pending updated list. Adds,
    // retains, or removes chunk geometries based on the list comparison.
    func synchronize(old: [Chunk], new: [Chunk]) {
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
