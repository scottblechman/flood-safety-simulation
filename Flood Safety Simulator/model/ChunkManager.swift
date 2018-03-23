//
//  Responsible for determining, based on the provided device location, which chunks of the
//  overall terrain model should be active or inactive.
//

import Foundation

// Common information also required by Chunk model for geographic positioning
let CHUNKS_X: Double = 7
let CHUNKS_Y: Double = 7

let FACE_NORTH = 33.58829
let FACE_SOUTH = 33.57808
let FACE_EAST = -101.8706
let FACE_WEST = -101.8815

//increment between chunks on the x-axis
let INCREMENT_X = abs(FACE_EAST - FACE_WEST) / CHUNKS_X
//increment between chunks on the y-axis
let INCREMENT_Y = abs(FACE_NORTH - FACE_SOUTH) / CHUNKS_Y

class ChunkManager {
    static let Manager = ChunkManager()
    
    var chunkList = [Chunk]()
    
    func update(_ latitude: Double, _ longitude: Double) -> Array<Chunk> {
        //1. Take location and return world grid coordinate
        let position: (Int, Int)
        position.0 = Int(floor((latitude-FACE_WEST)/INCREMENT_X))
        position.1 = Int(CHUNKS_Y) - Int(floor((longitude-FACE_NORTH)/INCREMENT_Y))
        
        //2. Take world grid coordinate and return coordinate + surrounding coordinates
        let coordinateList = coordinateListFrom(position)
        
        //3. Take coordinate list and return chunk list
        let chunkList = chunkListFrom(anchorCoordinate: position, coordinateList)
        
        //4. pass chunk list through to ViewController
        return chunkList
    }
    
    // Takes a world grid coordinate pair, and returns a list of the pair, plus any valid
    // border coordinates (lte 8 pairs that are not outside the bounds [[0, 48], [0, 48]].
    func coordinateListFrom(_ position: (Int, Int)) -> Array<(Int, Int)> {
        var coordinateList = [
            (position.0 - 1, position.1 - 1), (position.0, position.1 - 1), (position.0 + 1, position.1 - 1),
            (position.0 - 1, position.1), (position.0, position.1), (position.0 + 1, position.1),
            (position.0 - 1, position.1 + 1), (position.0, position.1 + 1), (position.0 + 1, position.1 + 1)
        ]
        
        
        for coordinate in coordinateList {
            if(coordinate.0 < 0 || coordinate.0 >= 7 || coordinate.1 < 0 || coordinate.1 >= 7) {
                coordinateList = coordinateList.filter() { $0 != coordinate }
            }
        }
        
        return coordinateList
    }
    
    // Takes the list of world grid coordinates and creates a list of Chunk objects representing
    // them. The original position the user occupies is used to mark the anchor chunk.
    func chunkListFrom(anchorCoordinate: (Int, Int), _ coordinateList: Array<(Int, Int)>) -> Array<Chunk> {
        var chunks = [Chunk]()
        
        for pair in coordinateList {
            if pair == anchorCoordinate {
                chunks.append(Chunk(x: pair.0, y: pair.1, anchor: true))
            } else {
                chunks.append(Chunk(x: pair.0, y: pair.1, anchor: false))
            }
        }
        
        return chunks
    }
}
