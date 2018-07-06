//
//  GameScene.swift
//  skiGame
//
//  Created by Katie  Lee on 7/5/18.
//  Copyright © 2018 Katie  Lee. All rights reserved.
//

import CoreMotion
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player:SKSpriteNode!
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    var rainfield:SKEmitterNode!
    var scoreLabel: SKLabelNode!
    var score:Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var gameTimer:Timer!

    var possible_obstacles = ["ob1", "ob2", "food1", "shark", "popeye"]
    let obsCategory:UInt32 = 0x1 << 1
    let photonCategory:UInt32 = 0x1 << 0
    override func didMove(to view: SKView) {
        SKTAudio.sharedInstance().playBackgroundMusic("win.mp3")
        
        motionManager.startAccelerometerUpdates()
        motionManager.accelerometerUpdateInterval = 0.001
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {
            (data:CMAccelerometerData?, error: Error?) in
            self.physicsWorld.gravity = CGVector(dx: 0, dy: CGFloat((data?.acceleration.y)!) * 100)
            
            
        }
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: self.frame.midX-200, y: self.frame.midY+150)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
//        scoreLabel.zPosition = 1
        score = 0
        self.addChild(scoreLabel)
        rainfield = SKEmitterNode(fileNamed: "rain")
        rainfield.position = CGPoint(x: -275
            , y: self.frame.midY-50)
        rainfield.advanceSimulationTime(10)
        self.addChild(rainfield)
        rainfield.zPosition = -1
        player = SKSpriteNode(imageNamed: "djk")
        player.setScale(0.25)
        player.position = CGPoint(x:
            self.frame.midX-200, y: self.frame.midY)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = photonCategory
        player.physicsBody?.contactTestBitMask = obsCategory
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(player)
        self.physicsWorld.gravity = CGVector(dx:0.0, dy:0.0)
        self.physicsWorld.contactDelegate = self
        
        
        
        gameTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(addObstacle), userInfo: nil, repeats: true)
        
    }
    
    @objc func addObstacle(){
        possible_obstacles = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possible_obstacles) as! [String]
        let obs = SKSpriteNode(imageNamed: possible_obstacles[0])
        if possible_obstacles[0].starts(with: "food"){
            obs.name = "food"
        }
        else if possible_obstacles[0].starts(with: "shark"){
            obs.name = "shark"
        }
        else if possible_obstacles[0].starts(with: "pop"){
            obs.name = "pop"
        }
        else {
            obs.name = "obs"
        }
        if let naming = obs.name {
//            print(naming)
        }
        obs.setScale(0.25)
        let randomObsPosition = GKRandomDistribution(lowestValue: 50, highestValue: 414)
        let position = CGFloat(randomObsPosition.nextInt())
        obs.position = CGPoint(x: position+100, y: self.frame.midY)
        obs.physicsBody = SKPhysicsBody(rectangleOf: obs.size)
        obs.physicsBody?.isDynamic = true
        obs.physicsBody?.categoryBitMask = obsCategory
        obs.physicsBody?.contactTestBitMask = photonCategory
        obs.physicsBody?.collisionBitMask = 0
        
        self.addChild(obs)
        let animationDuration: TimeInterval = 6
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: -self.frame.size.width,y: self.frame.midY), duration: animationDuration))
//        actionArray.append(SKAction.node.physicsBody.velocity=CGVectorMake(200, 200);)
//        actionArray.append(SKAction.move(to: CGPoint(x: position,y: -obs.size.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        obs.run(SKAction.sequence(actionArray))
    }
    
//    func fireTorepedo(){
//        self.run(SKAction.playSoundFileNamed("torepedo.mp3", waitForCompletion: false))
//        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
//        torpedoNode.position = player.position
//        torpedoNode.position.y += 5
//        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
//        torpedoNode.physicsBody?.isDynamic = true
//        torpedoNode.physicsBody?.categoryBitMask = photonCategory
//        torpedoNode.physicsBody?.contactTestBitMask = obsCategory
//        torpedoNode.physicsBody?.collisionBitMask = 0
//        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
//        self.addChild(torpedoNode)
//        let animationDuration: TimeInterval = 0.3
//
//        var actionArray = [SKAction]()
//        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x,y: self.frame.size.height + 10), duration: animationDuration))
//        actionArray.append(SKAction.removeFromParent())
//        torpedoNode.run(SKAction.sequence(actionArray))
//    }
//
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        fireTorepedo()
//    }

    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonCategory) != 0 && (secondBody.categoryBitMask & obsCategory) != 0 {
            playerDidCollideWithObs(playerNode: firstBody.node as! SKSpriteNode, obsNode: secondBody.node as! SKSpriteNode)
        }

    }
    
    func playerDidCollideWithObs(playerNode: SKSpriteNode, obsNode: SKSpriteNode) {
        let explosion = SKSpriteNode(imageNamed: "explode")
        let cloud = SKSpriteNode(imageNamed: "cloud")
        let lion = SKSpriteNode(imageNamed: "lion")
        cloud.setScale(0.5)
        explosion.setScale(0.5)
        lion.setScale(1.0)
        if let naming = obsNode.name {
            if naming.starts(with: "food") {
                cloud.position = obsNode.position
                self.addChild(cloud)
                self.run(SKAction.playSoundFileNamed("chaching.mp3", waitForCompletion: false))
                //        playerNode.removeFromParent()
                obsNode.removeFromParent()
                self.run(SKAction.wait(forDuration: 1)) {
                    cloud.removeFromParent()
                }
                score += 5
            }
            else if naming.starts(with: "pop") {
                lion.setScale(1)
                lion.position = obsNode.position
                self.addChild(lion)
                self.run(SKAction.playSoundFileNamed("chaching.mp3", waitForCompletion: false))
                obsNode.removeFromParent()
                self.run(SKAction.wait(forDuration: 1)) {
                    lion.removeFromParent()
                }
                score += 15
            }
            else if naming.starts(with: "shark") {
                explosion.setScale(1)
                explosion.position = obsNode.position
                self.addChild(explosion)
                self.run(SKAction.playSoundFileNamed("grenade.mp3", waitForCompletion: false))
                //        playerNode.removeFromParent()
                obsNode.removeFromParent()
                self.run(SKAction.wait(forDuration: 1)) {
                    explosion.removeFromParent()
                }
                score -= 15
            }
            else{
                explosion.position = obsNode.position
                self.addChild(explosion)
                self.run(SKAction.playSoundFileNamed("grenade.mp3", waitForCompletion: false))
                //        playerNode.removeFromParent()
                obsNode.removeFromParent()
                self.run(SKAction.wait(forDuration: 1)) {
                    explosion.removeFromParent()
                }
                score -= 5
            }
        }
//        explosion.position = obsNode.position
//        self.addChild(explosion)
//        self.run(SKAction.playSoundFileNamed("grenade.mp3", waitForCompletion: false))
////        playerNode.removeFromParent()
//        obsNode.removeFromParent()
//        self.run(SKAction.wait(forDuration: 1)) {
//            explosion.removeFromParent()
//        }
//        score -= 5
//        print(score)
    }

    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
