//
//  GameScene.swift
//  ZombieConga
//
//  Created by Virt on 19/11/14.
//  Copyright (c) 2014 @pp. All rights reserved.
//

import SpriteKit


class GameScene: SKScene {
    var lastTouchLocation: CGPoint?
    let zombie: SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPointZero
    let playableRect:CGRect
    let zombieRotateRadianPerSec:CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    let catCollisionSound: SKAction =  SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    var invincible = false
    let catMovePerSec:CGFloat = 480.0
    var lives = 5
    var gameOver = false
    let backgroundMovePointsPerSec: CGFloat = 200.0
    let backgroundLayer = SKNode()

    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin =  (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin,
            width: size.width,
            height: playableHeight)
        var textures:[SKTexture] = []
        for i in 1...4{
           textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        
        
        zombieAnimation = SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1))
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func debugDrawPlayableArea()
    {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    
    override func didMoveToView(view: SKView) {
        playBackgroundMusic("backgroundMusic.mp3")
        backgroundLayer.zPosition = -1
        addChild(backgroundLayer)

        
        backgroundColor = SKColor.whiteColor()
//        let background = SKSpriteNode(imageNamed: "background1")
//        addChild(background)
        
//        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
//        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        background.zPosition = -1;
        
        for i in 0...1{
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.name = "background"
//            addChild(background)
            backgroundLayer.addChild(background)
        }
        
        
        /// zombie
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
//        addChild(zombie)
        backgroundLayer.addChild(zombie)
        
        
//        zombie.runAction(SKAction.repeatActionForever(zombieAnimation))
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnEnemy),
                SKAction.waitForDuration(2.0)])))
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([SKAction.runBlock(spawnCat),
                SKAction.waitForDuration(1.0)])))
//        debugDrawPlayableArea()
    }
    
    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0
        {
            dt = currentTime - lastUpdateTime
        }
        else
        {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        
        if  let lastTouch = lastTouchLocation
        {
//            var diff = lastTouch - zombie.position
//            if (diff.length() <= zombieMovePointsPerSec * CGFloat(dt))
//            {
//                zombie.position = lastTouchLocation!
//                velocity = CGPointZero
//                stopZombie()
//            }
//            else
//            {
                moveSprite(zombie, velocity: velocity)
                
                rotateSprite(zombie, direction: velocity, rotateRadianPerSec: zombieRotateRadianPerSec)
//            }
        }
        boundsCheckZombie()
        moveTrain()
        moveBackground()
        
        if lives <= 0 && !gameOver{
            gameOver = true
            println("You lose!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    override func didEvaluateActions() {
        checkCollision()
    }
    
    
    
    func moveSprite(sprite:SKSpriteNode, velocity: CGPoint)
    {
//        let amountToMove = CGPoint(x:  velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
//        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
        
    }

    func moveZombieToward(location: CGPoint){
//        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
//        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
//        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
//        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        startZombieAnimation()
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec

    }
    
    func sceneTouched(touchLocation:CGPoint)
    {
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(backgroundLayer)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        let touch = touches.anyObject() as UITouch
//        let touchLocation = touch.locationInNode(self)
        let touchLocation = touch.locationInNode(backgroundLayer)
        sceneTouched(touchLocation)
    }
    
    func boundsCheckZombie(){
//        let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
//        let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        let bottomLeft = backgroundLayer.convertPoint(
            CGPoint(x: 0, y: CGRectGetMinY(playableRect)),
            fromNode: self)
        let topRight = backgroundLayer.convertPoint(
            CGPoint(x: size.width, y: CGRectGetMaxY(playableRect)),
            fromNode: self);
        
        if zombie.position.x <= bottomLeft.x{
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.x >= topRight.x
        {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        
        if zombie.position.y <= bottomLeft.y{
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        
        
        if zombie.position.y >= topRight.y{
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadianPerSec: CGFloat)
    {
//        sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
        /// smoooth rotation
        let shortest = shortestAngleBetween(zombie.zRotation, velocity.angle())
        let amtToRotate = min(rotateRadianPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amtToRotate
    }
    
    
    func spawnEnemy(){
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        let enemyScenePos = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        enemy.position = backgroundLayer.convertPoint(enemyScenePos, fromNode: self)
//        enemy.position = CGPoint(
//            x: size.width + enemy.size.width/2,
//            y: CGFloat.random(
//                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
//                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
//        addChild(enemy)
        backgroundLayer.addChild(enemy)

        
//        let actionMove = SKAction.moveToX(-enemy.size.width / 2, duration: 2.0)
        let actionMove = SKAction.moveByX(-size.width-enemy.size.width, y: 0, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }

    
    
    func startZombieAnimation(){
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombie () {
        zombie.removeActionForKey("animation")
    }
    
    
    func spawnCat(){
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        let catScenePos = CGPoint(
            x: CGFloat.random(
                min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.position = backgroundLayer.convertPoint(catScenePos, fromNode: self)
//        cat.position = CGPoint(
//            x: CGFloat.random(
//                min: CGRectGetMinX(playableRect),
//                max: CGRectGetMaxX(playableRect)),
//            y: CGFloat.random(
//                min: CGRectGetMinY(playableRect),
//                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
//        addChild(cat)
        backgroundLayer.addChild(cat)
        
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
    
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
//        let wiggleWait = SKAction.repeatAction(fullWiggle, count: 10)
        let scaleUp =  SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let grouWait = SKAction.repeatAction(group, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, grouWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat:SKSpriteNode){
//        cat.removeFromParent()
        runAction(catCollisionSound)
        
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        
        let turnGreen = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(turnGreen)
    }
    
    func moveTrain(){
        var trainCount = 0
        var targetPosition = zombie.position
        
        backgroundLayer.enumerateChildNodesWithName("train")
            {
                node, _ in
                if !node.hasActions(){
                    let actionDuration = 0.3
                    let offset = targetPosition - node.position
                    let direction = offset.normalized()
                    let amountToMovePerSec = direction * self.catMovePerSec
                    let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                    let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                    node.runAction(moveAction)
                }
                targetPosition = node.position
                trainCount++
        }
        
        if trainCount >= 5 && !gameOver {
            gameOver = true
            println("You win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func zombieHitEnemy(enemy:SKSpriteNode){
        invincible = true
        runAction(enemyCollisionSound)
        loseCats()
        lives--
//        enemy.removeFromParent()
        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        
        let setHidden = SKAction.runBlock() {
            self.zombie.hidden = false
            self.invincible = false
        }
        zombie.runAction(SKAction.sequence([blinkAction, setHidden]))
    }
    
    func checkCollision() {
        var hitCats : [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame)
            {
                hitCats.append(cat)
            }
        
            
        }
        
        for cat in hitCats
        {
            zombieHitCat(cat)
        }
        

        if invincible {
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("enemy"){ node, _ in
            let enemy = node as SKSpriteNode
            if CGRectIntersectsRect(
                CGRectInset(node.frame, 20, 20), self.zombie.frame){
                    
                    hitEnemies.append(enemy)
            }
            
        }
        
        for enemy in hitEnemies{
            zombieHitEnemy(enemy)
        }
    }
    
    func loseCats(){
        var loseCount = 0
        backgroundLayer.enumerateChildNodesWithName("train"){ node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            
            node.name = ""
            node.runAction(
                SKAction.sequence([
                    SKAction.group([
                        SKAction.rotateByAngle(π * 4, duration: 1.0),
                        SKAction.moveTo(randomSpot, duration: 1.0),
                        SKAction.scaleTo(0, duration: 1.0)
                        ]),
                    SKAction.removeFromParent()
                    ])
            );
            loseCount++
            if loseCount >= 2{
                stop.memory = true
            }
        }
    }
    
    func backgroundNode()-> SKSpriteNode{
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPointZero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPointZero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPointZero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        
        return backgroundNode
    }
    
    func moveBackground(){
        let backgroundVelocity = CGPoint(x: -backgroundMovePointsPerSec,
            y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        backgroundLayer.position += amountToMove
        
        backgroundLayer.enumerateChildNodesWithName("background"){ node, _ in
            let background = node as SKSpriteNode
//            let backgroundVelocity =
//            CGPoint(x: -self.backgroundMovePointsPerSec,
//                y: 0)
//            let amountToMove = backgroundVelocity * CGFloat(self.dt)
//            background.position += amountToMove
            let backgroundScreenPos = self.backgroundLayer.convertPoint(background.position, toNode: self)
            if backgroundScreenPos.x <= -background.size.width{
                background.position = CGPoint(
                    x: background.position.x + background.size.width * 2,
                    y: background.position.y)
            }
            
        }
    }
}
