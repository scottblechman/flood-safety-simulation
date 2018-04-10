//
//  GameManager.swift
//  Flood Safety Simulator
//
//  Created by Scott Blechman on 4/10/18.
//  Copyright © 2018 Scott Blechman. All rights reserved.
//

import Foundation

protocol GameTickProtocol {
    func update(time: String, score: String, waterLevel: String)
}

class GameManager {
    static let Manager = GameManager()
    
    var delegate: GameTickProtocol!
    
    var timer = Timer()
    var timerRunning = false
    
    // Seconds remaining in the game, starting at 3 min.
    var seconds: Int = 180
    
    // Allows for a uniform water rise over the course of the game to the final water level
    var tickAmount: Double = 0
    
    // When calculating the position of the water model, compare the user's elevation to
    // the lowest environment elevation to place the model at the proper relative start.
    let minElevationLevel = 971.288
    
    // final water level at end of game, approx. 20-40 cm
    var waterLevel: Double = 0
    
    var finalWaterLevel: Double = 0
    
    func startGame() {
        // water level will always be at least .2 m, at the most .4 m
        finalWaterLevel = Double(20 + arc4random_uniform(21))
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(update)), userInfo: nil, repeats: true)
    }
    
    func displayTimeRemaining() -> String {
        let mins = seconds / 60
        let sec = seconds-(60*mins)
        var secString = String(sec)
        if sec <= 9 {
            secString = "0\(sec)"
        }
        return "\(mins):\(secString)"
    }
    
    // Perform game tick functions once per second
    @objc func update() {
        seconds -= 1
        delegate?.update(time: displayTimeRemaining(), score: "", waterLevel: "")
        if seconds <= 0 {
            timer.invalidate()
        }
    }
}
