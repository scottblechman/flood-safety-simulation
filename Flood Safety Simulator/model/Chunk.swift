//
//  Represents a single world chunk, holding the information required to render in the parent
//  Scene View.
//

import Foundation
import SceneKit

class Chunk: SCNNode{
    
    let CHUNK_BOUNDARY = 160.9344  // each chunk is a real-world size of 528 sq. ft.
    
    // Position of the chunk on the overall world grid, required for geometry fetching
    var gridX: Int
    var gridY: Int
    
    // If the chunk is an anchor (the chunk the user is occupying), its position will be
    // determined in a different way in the ViewController
    var anchor: Bool
    
    // Chunk IDs follow the format "chunk_x_y"
    var chunkId: String
    
    // Intended origin point of the chunk in space
    var geoAnchor: (Double, Double)
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(x: Int, y: Int, anchor: Bool) {
        // Extended class data (not associated with SCNNode) must be declared before super method
        self.gridX = x
        self.gridY = y
        self.anchor = anchor
        
        self.chunkId = "\(x)_\(y)"
        
        // Determine where the chunk should be located relative to the corner of the entire map.
        let anchorX = FACE_WEST+(INCREMENT_X*Double(x))
        let anchorY = FACE_NORTH-(INCREMENT_Y*Double(y))
        self.geoAnchor = (anchorX, anchorY)
        
        super.init()
    }
}
