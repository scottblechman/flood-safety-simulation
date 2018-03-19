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
    
    // For the moment, represent geometry as a flat plane to continue developing other components
    var chunkGeometry: SCNPlane
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(x: Int, y: Int, anchor: Bool) {
        // Extended class data (not associated with SCNNode) must be declared before super method
        self.gridX = x
        self.gridY = y
        self.anchor = anchor
        self.chunkGeometry = SCNPlane(width: CGFloat(CHUNK_BOUNDARY), height: CGFloat(CHUNK_BOUNDARY))
        
        // Class data associated with SCNNode must be declared following super method
        super.init()
        self.geometry = chunkGeometry
    }
}
