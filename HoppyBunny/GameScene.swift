//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Mehmet Sadıç on 12/11/2016.
//  Copyright © 2016 Mehmet Sadıç. All rights reserved.
//

import SpriteKit

enum GameSceneState {
    case active, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var hero: SKSpriteNode!
    var sinceTouch: TimeInterval = 0
    var spawnTimer: TimeInterval = 0
    let fixedDelta: TimeInterval = 1.0/60.0 /* 60 FPS */
    let groundScrollSpeed: CGFloat = 160
    var groundScrollLayer: SKNode!
    let cloudScrollSpeed: CGFloat = 30
    var cloudScrollLayer: SKNode!
    var obstacleLayer: SKNode!
    // UI Connections
    var buttonRestart: MSButtonNode!
    // Game management
    var gameState: GameSceneState = .active
    
    // Player score
    var scoreLabel: SKLabelNode!
    var points = 0
    
    override func didMove(to view: SKView) {
        /* Set up your scene here */
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNode(withName: "//hero") as! SKSpriteNode
        
        /* Set reference to ground scroll layer node */
        groundScrollLayer = self.childNode(withName: "groundScrollLayer")
        
        // Set reference to cloud scroll layer node
        cloudScrollLayer = self.childNode(withName: "cloudScrollLayer")
        
        // Set reference to obstacle layer node
        obstacleLayer = self.childNode(withName: "obstacleLayer")
        
        // Set UI connections
        buttonRestart = self.childNode(withName: "buttonRestart") as! MSButtonNode
        
        // Setup score label node
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        
        // Setup restart button selection handler
        buttonRestart.selectedHandler = { [unowned self] in
            
            // Grab reference to our SpriteKit view
            let skView = self.view as SKView!
            
            // Load game scene
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            // Ensure correct aspect mode
            scene?.scaleMode = .aspectFill
            
            // Restart game scene
            skView?.presentScene(scene)
        }
        
        // Hide restart button
        buttonRestart.state = .hidden
        
        // Set physics contact delegate
        physicsWorld.contactDelegate = self
        
        // Reset score label
        scoreLabel.text = String(points)
    }
    
    /* Called when a touch begins */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Disable touch if game state is not active
        if gameState != .active { return }
        
        // Reset velocity, helps improve response against cumulative falling velocity
        hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        /* Apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 250))
        
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /* Reset touch timer */
        sinceTouch = 0
        
        /* Play SFX */
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        
        self.run(flapSFX)
    }
    
    /* Called before each frame is rendered */
    override func update(_ currentTime: TimeInterval) {
        
        // Skip game update if game no longer active
        if gameState != .active { return }
        
        /* Grab vertical velocity */
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /* Apply falling rotation */
        if sinceTouch > 0.1 {
            let impulse = -2000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation = hero.zRotation.clamped(CGFloat(-90).degreesToRadians(), CGFloat(30).degreesToRadians())
        hero.physicsBody!.angularVelocity = hero.physicsBody!.angularVelocity.clamped(-2, 2)
        
        /* Update last touch timer */
        sinceTouch += fixedDelta
        
        // Update spawn timer
        spawnTimer += fixedDelta
        
        /* Process ground scrolling */
        scroll(groundScrollLayer, withSpeed: groundScrollSpeed)
        
        // Process cloud scrolling
        scroll(cloudScrollLayer, withSpeed: cloudScrollSpeed)
        
        // Process obstacles
        updateObstacles()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Ensure only called while game running
        if gameState != .active { return }
      
        // Get references to bodies involved in collision
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        // Get references to physics body parent nodes
        let nodeA = contactA.node
        let nodeB = contactB.node
        
        // Did our hero pass through the goal?
        if nodeA?.name == "goal" || nodeB?.name == "goal" {
            // Increment the points
            points += 1
            
            // update score label
            scoreLabel.text = String(points)
            
            // now we can return
            return
        }
        
        // Change game state to game over
        gameState = .gameOver
        
        // Stop any new angular velocity being applied
        hero.physicsBody?.allowsRotation = false
        
        // Reset angular velocity
        hero.physicsBody?.angularVelocity = 0
        
        // Stop hero flapping animation
        hero.removeAllActions()
        
        // Create our hero death action
        let heroDeath = SKAction.run {
            // Put our hero face down in the dirt
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            // Stop her0 colliding with anything else
            self.hero.physicsBody?.collisionBitMask = 0
        }
        
        // Run action
        hero.run(heroDeath)
        
        // Load the shake action resource
        let shakeScene: SKAction = SKAction.init(named: "Shake")!
        
        // Loop through all nodes
        for node in self.children {
            // Apply effect each ground node
            node.run(shakeScene)
        }
        
        // Show restart button
        buttonRestart.state = .active
    }
    
    func scroll(_ layer: SKNode, withSpeed speed: CGFloat) {
        /* Scroll World */
        layer.position.x -= speed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes */
        for node in layer.children as! [SKSpriteNode] {
            
            /* Get node position, convert node position to scene space */
            let nodePosition = layer.convert(node.position, to: self)
            
            /* Check if sprite has left the scene */
            if nodePosition.x <= -node.size.width  {
                
                /* Reposition the sprite to the second starting position */
                let newPosition = CGPoint( x: (self.size.width / 2) + node.size.width / 2, y: nodePosition.y)
                
                /* Convert new node position back to scroll layer space */
                node.position = self.convert(newPosition, to: layer)
            }
        }
    }
    
    func updateObstacles() {
        // Update obstacles
        obstacleLayer.position.x -= groundScrollSpeed * CGFloat(fixedDelta)
        
        // Loop through obstacle layer nodes
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            // Get obstacle node position, convert to node position to scene space
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: self)
            
            // Check if obstacle left the scene
            if obstaclePosition.x <= -self.size.width / 2 {
                
                // Remove obstacle node from obstacle layer
                obstacle.removeFromParent()
            }
        }
        
        // Time to add a new obstacle?
        if spawnTimer >= 1.5 {
            
            // Create a new obstacle reference object using our obstacle resource
            let resourcePath = Bundle.main.path(forResource: "Obstacle", ofType: "sks")
            let newObstacle = SKReferenceNode(url: URL(fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            // Generate new obstacle position, start just outside screen and with a random y value
            let randomPosition = CGPoint(x: 192, y: CGFloat.random(min: 18, max: 166))
            
            // Convert new node position back to obstacle layer space
            newObstacle.position = self.convert(randomPosition, to: obstacleLayer)
            
            // Reset spawn timer
            spawnTimer = 0
        }
    }
    
    
}
