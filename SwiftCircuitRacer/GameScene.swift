//
//  GameScene.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import SpriteKit

enum CarType: Int {
    case Yellow, Blue, Red
}

enum LevelType: Int {
    case Easy, Medium, Hard
}

class GameScene: SKScene, AnalogControlPositionChange {
    
    var carType: CarType!
    var levelType: LevelType!
    var timeInSeconds = 0
    var numberOfLaps = 0
    
    var box1: SKSpriteNode!, box2: SKSpriteNode!
    var laps: SKLabelNode!, time: SKLabelNode!
    
    var maxSpeed = 0
    
    var trackCenter = CGPoint.zeroPoint
    var nextProgressAngle = M_PI
    
    override func didMoveToView(view: SKView) {
        initializeGame()
    }

    func initializeGame() {
        loadLevel()
        loadTrackTexture()
        setupPhysicsBodies()
        loadCarTexture()
        loadObstacles()
        addLabels()
        
        maxSpeed = 500 * (2 + carType.toRaw())
        
        trackCenter = childNodeWithName("track")!.position
    }
    
    func loadLevel() {
        let filePath = NSBundle.mainBundle().pathForResource("LevelDetails", ofType: "plist")!
        
        let levels = NSArray(contentsOfFile: filePath)
        
        let levelData = levels[levelType.toRaw()] as NSDictionary
        
        timeInSeconds = levelData["time"] as Int
        numberOfLaps = levelData["laps"] as Int
    }
    
    func loadTrackTexture() {
        let track = self.childNodeWithName("track") as SKSpriteNode
        track.texture = SKTexture(imageNamed: "track_\(levelType.toRaw() + 1)")
    }
    
    func setupPhysicsBodies() {
        let innerBoundary = SKNode()
        innerBoundary.position = childNodeWithName("track")!.position
        addChild(innerBoundary)
        
        innerBoundary.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(720, 480))
        innerBoundary.physicsBody!.dynamic = false
        
        let trackFrame = CGRectInset(self.childNodeWithName("track")!.frame, 200, 0)
        
        let maxAspectRatio: CGFloat = 3.0 / 2.0 // iPhone 4
        let maxAspectRatioHeight = trackFrame.size.width / maxAspectRatio
        let playableMarginY: CGFloat = (trackFrame.size.height - maxAspectRatioHeight) / 2
        let playableMaringX: CGFloat = (frame.size.width - trackFrame.size.width) / 2
        
        let playableRect = CGRect(x: playableMaringX, y: playableMarginY, width: trackFrame.size.width, height: trackFrame.size.height - playableMarginY * 2)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
    }
    
    func loadCarTexture() {
        let car = self.childNodeWithName("car") as SKSpriteNode
        car.texture = SKTexture(imageNamed: "car_\(carType.toRaw() + 1)")
    }
    
    func loadObstacles() {
        box1 = self.childNodeWithName("box_1") as SKSpriteNode
        box2 = self.childNodeWithName("box_2") as SKSpriteNode
    }
    
    func addLabels() {
        laps = self.childNodeWithName("laps_label") as SKLabelNode
        time = self.childNodeWithName("time_left_label") as SKLabelNode
        
        laps.text = "Laps: \(numberOfLaps)"
        time.text = "Time: \(timeInSeconds)"
    }
    
    func analogControlPositionChanged(analogControl: AnalogControl, position: CGPoint) {
        let car = self.childNodeWithName("car") as SKSpriteNode
        
        car.physicsBody!.velocity = CGVector(position.x * CGFloat(maxSpeed), -position.y * CGFloat(maxSpeed))
        
        if position != CGPointZero {
            car.zRotation = CGPointMake(position.x, -position.y).angle
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        let carPosition = childNodeWithName("car")!.position
        let vector = carPosition - trackCenter
        let progressAngle = Double(vector.angle) + M_PI
        
        // check whether the current angle is greater than the next target, but only by a little it: M_PI_4. This prevents the player from going backward.
        if progressAngle > nextProgressAngle && (progressAngle - nextProgressAngle) < M_PI_4 {
            // move on to the next quadrant.
            nextProgressAngle += M_PI_2
            
            //
            if nextProgressAngle >= (2 * M_PI) {
                nextProgressAngle = 0
            }
            
            // if next target angle = M_PI, car has just passed the finish line.
            if fabs(nextProgressAngle - M_PI) < Double(FLT_EPSILON) {
                // lap completed!
                numberOfLaps -= 1
                laps.text = "Laps: \(numberOfLaps)"
            }
        }
    }
}
