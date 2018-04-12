//
//  Responsible for rendering game state with ARKit and SceneKit, as well as coordinating model class
//  connections.
//

import UIKit
import SceneKit
import ARKit

import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate,
LocationUpdateProtocol, GameTickProtocol {
    
    @IBOutlet var sceneView: ARSCNView!
    
    // Holds reference IDs for the terrain chunks that should be in memory
    var chunkList = [Chunk]()
    
    // Current location of the device
    var location: CLLocation? = nil
    
    var elevationDelta: Double = 0
    
    // Current heading of the device
    var heading: CLLocationDirection? = nil
    
    // Corrected for initial rotation by 90º
    var trueHeading: Double = 0
    
    // Scene attached to the main AR Scene View
    let scene = SCNScene(named: "art.scnassets/world.scn")!
    
    var assetsLoaded = false
    
    // UI components programatically shown and hidden
    var labelTimer: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    var labelScore: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    var gameEndLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Connect location update messages to ViewController
        LocationProvider.Provider.delegate = self
        
        // Connect game update messaging to ViewController
        GameManager.Manager.delegate = self
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Hide statistics, fps, and timing info
        sceneView.showsStatistics = false
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Initialize game start UI
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        button.setTitle("START", for: .normal)
        button.addTarget(self, action: #selector(runGame), for: .touchUpInside)
        button.tag = 101
        
        self.view.addSubview(button)
        button.center = self.view.center
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
    
    // MARK: - UserInterface
    
    @objc func runGame(sender: UIButton!) {
        print("Button tapped")
        let children = scene.rootNode.childNodes.count
        if children >= 1 {
            print("Water and terrain available, starting game")
            GameManager.Manager.startGame()
            for view in self.view.subviews {
                if view.tag == sender.tag {
                    view.removeFromSuperview()
                }
            }
            initializeGameInterface()
        }
    }
    
    @objc func resetGame(sender: UIButton!) {
        print("Reset button tapped")
        GameManager.Manager.startGame()
        for view in self.view.subviews {
            if view.tag == sender.tag {
                view.removeFromSuperview()
            }
            else if view.tag == gameEndLabel.tag {
                view.removeFromSuperview()
            }
        }
        initializeGameInterface()
    }
    
    func initializeGameInterface() {
        labelTimer.center = CGPoint(x: 96, y: 96)
        labelTimer.textAlignment = .center
        labelTimer.tag = 102
        labelTimer.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(labelTimer)
        
        labelTimer.heightAnchor.constraint(equalToConstant: 96).isActive = true
        labelTimer.widthAnchor.constraint(equalToConstant: 96).isActive = true
        labelTimer.leadingAnchor.constraint(equalTo: labelTimer.superview!.leadingAnchor).isActive = true
        labelTimer.topAnchor.constraint(equalTo: labelTimer.superview!.topAnchor).isActive = true
        
        labelScore.center = CGPoint(x: view.bounds.size.width-112, y: 96)
        labelScore.textAlignment = .center
        labelScore.tag = 103
        labelScore.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(labelScore)
        
        labelScore.heightAnchor.constraint(equalToConstant: 96).isActive = true
        labelScore.widthAnchor.constraint(equalToConstant: 96).isActive = true
        labelScore.trailingAnchor.constraint(equalTo: labelScore.superview!.trailingAnchor).isActive = true
        labelScore.topAnchor.constraint(equalTo: labelScore.superview!.topAnchor).isActive = true
    }
    
    func removeGameInterface() {
        labelTimer.removeFromSuperview()
        labelScore.removeFromSuperview()
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
        if self.location != nil {
            self.elevationDelta = self.location!.altitude - location.altitude
        } else {
            self.elevationDelta = 0
        }
        self.location = location
        
        // Do any chunk updating required at the new location
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        print("Updated location to \(latitude), \(longitude)")
        
        let newChunkList = ChunkManager.Manager.update(latitude, longitude)
        
        if heading != nil {
            //synchronize(old: self.chunkList, new: newChunkList)
        }
        
        if assetsLoaded == false && heading != nil {
            let bottomElevation = GameManager.Manager.minElevationLevel - location.altitude
            print("Bottom elevation translation is \(bottomElevation)")
            addWaterGeometry(world: sceneView.scene, initialPosition: bottomElevation)
            addTerrainGeometry(world: sceneView.scene, initialPosition: bottomElevation)
            assetsLoaded = true
        }
    }
    
    // Called automatically when a new location is provided. Allows to update the device's
    // heading (and true north-facing heading) to properly position chunks in the 3D space.
    func headingUpdated(heading: CLLocationDirection, accuracy: CLLocationDirection) {
        self.heading = heading
        self.trueHeading = (heading.magnitude + 90).truncatingRemainder(dividingBy: 360)
    }
    
    // MARK: - GameTickProtocol
    
    // Called automatically when the game timer performs an update. Reflects the game state in
    // the UI.
    func update(time: String, score: String, waterLevel: Double, elevation: Double, tickAmount: Double) {
        labelTimer.text = time
        labelScore.text = score
        print(time)
        tickWater(increment: Float(tickAmount), elevationDelta: Float(elevationDelta))
        GameManager.Manager.updateScore(location: self.location!)
    }
    
    // Called automatically when the game manager has determined the game should end.
    func gameEnded(score: String) {
        removeGameInterface()
        
        gameEndLabel.text = "Game Over Score: "+score
        gameEndLabel.tag = 201
        self.view.addSubview(gameEndLabel)
        gameEndLabel.center = self.view.center
        
        let resetButton = UIButton(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        resetButton.setTitle("TRY AGAIN", for: .normal)
        resetButton.addTarget(self, action: #selector(resetGame(sender:)), for: .touchUpInside)
        resetButton.tag = 202
        
        self.view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        resetButton.heightAnchor.constraint(equalToConstant: 96).isActive = true
        resetButton.widthAnchor.constraint(equalToConstant: 96).isActive = true
        resetButton.centerXAnchor.constraint(equalTo: resetButton.superview!.centerXAnchor).isActive = true
        resetButton.bottomAnchor.constraint(equalTo: resetButton.superview!.bottomAnchor).isActive = true
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
        //node.scale = SCNVector3(x: 4180.0, y: 1.0, z: 3983.42)
        
        world.rootNode.addChildNode(node)
    }
    
    func addWaterGeometry(world: SCNScene, initialPosition: Double) {
        let geometry = SCNScene(named: "art.scnassets/water.dae")
        let node: SCNNode = (geometry?.rootNode.childNodes[0])!
        node.name = "water"
        
        node.scale = SCNVector3(x: 500.0, y: 1.0, z: 500.0)
        node.position = SCNVector3Make(0.0, Float(initialPosition)*10, 0.0)
        
        world.rootNode.addChildNode(node)
    }
    
    func addTerrainGeometry(world: SCNScene, initialPosition: Double) {
        /*let geometry = SCNScene(named: "art.scnassets/campus.dae")
        let node: SCNNode = (geometry?.rootNode.childNodes[0])!
        node.name = "terrain"
        
        //let xAngle = SCNMatrix4MakeRotation(Float.pi/2, 1, 0, 0)
        //let yAngle = SCNMatrix4MakeRotation(0, 0, 1, 0)
        //let zAngle = SCNMatrix4MakeRotation(0, 0, 0, 1)
        //let rotationMatrix = SCNMatrix4Mult(SCNMatrix4Mult(xAngle, yAngle), zAngle)
        //node.pivot = SCNMatrix4Mult(rotationMatrix, node.transform)
        
        // TODO: change scale of node to fit documentation
        node.scale = SCNVector3(x: 1000.0, y: 1000.0, z: 1000.0)
        node.position = SCNVector3Make(0.0, Float(initialPosition), 0.0)
        
        world.rootNode.addChildNode(node)*/
    }
    
    func tickWater(increment: Float, elevationDelta: Float) {
        let node = scene.rootNode.childNode(withName: "water", recursively: true)
        node?.position.y += (increment) - elevationDelta
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
