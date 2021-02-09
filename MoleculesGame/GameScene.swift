//
//  GameScene.swift
//  MoleculesGame
//
//  Created by Mateusz Zacharski on 09/02/2021.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // in order to make things work, the red, green and yellow views will have to be added as SKNodes. Then, we can place them in the center and add SKAction to them in order to animate them in ellipses motion (SKActions use CGPath for animations, like keyframe animations in UIKit). Of course, now they will be under SKPhysicsContactDelegate control and in contactBegan() function we can insert all things that happen when the player loses the game. As they won't be just views with modified cornerRadius, we will have to insert a png of red/green/yellow circles and then set its size to 0.1 of the current view's total width.
   
    lazy var width: CGFloat = view!.bounds.width / 10
    lazy var height: CGFloat = view!.bounds.width / 10
    
    let redView = UIView()
    let redCircle = UIImageView()
    
    let greenView = UIView()
    let greenCircle = UIImageView()
    
    let yellowView = UIView()
    let yellowCircle = UIImageView()
    
    lazy var circleDiameterWidth: CGFloat = view!.bounds.width
    
    override func didMove(to view: SKView) {
        view.backgroundColor = .black
        
        [redView, redCircle, greenView, greenCircle, yellowView, yellowCircle].forEach { (v) in
            self.view!.addSubview(v)
        }
        
        redView.backgroundColor = .systemRed
        greenView.backgroundColor = .systemGreen
        yellowView.backgroundColor = .systemYellow
        
        //
        
        [redView, greenView, yellowView].forEach { (v) in
            v.frame = CGRect(x: view.bounds.midX - width / 2, y: view.bounds.midY - height / 2, width: width, height: height)
            v.layer.cornerRadius = width / 2
            v.layer.borderWidth = 2
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.zPosition = 5
        }
        
        let yPosition = UIDevice.current.userInterfaceIdiom == .phone ? view.bounds.midY - 150 / 2 : view.bounds.midY - 150
        
        [redCircle, greenCircle, yellowCircle].forEach { (circle) in
            circle.frame = CGRect(x: view.bounds.midX - circleDiameterWidth / 2, y: yPosition, width: circleDiameterWidth, height: circleDiameterWidth / 2.5)
            circle.image = drawCircleImage()
        }
        
        redCircle.transform = CGAffineTransform(rotationAngle: .pi / 4)
        greenCircle.transform = CGAffineTransform(rotationAngle: -.pi / 4)
        yellowCircle.transform = CGAffineTransform(rotationAngle: .pi / 2)

        animateOrbit()
        
    }
    
    func drawCircleImage() -> UIImage {
        // drawing a circle:
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: circleDiameterWidth, height: circleDiameterWidth))
        
        let img = renderer.image { (ctx) in
            let rectangle = CGRect(x: 0, y: 0, width: circleDiameterWidth, height: circleDiameterWidth).insetBy(dx: 5, dy: 5)
            ctx.cgContext.setStrokeColor(UIColor.systemRed.cgColor)
            ctx.cgContext.setFillColor(UIColor.clear.cgColor)
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.addEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
        return img
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
    }
    
    func createOrbitAnimation(withRadians radians: CGFloat, initialDuration duration: CFTimeInterval) -> CAKeyframeAnimation {
        let yPosition: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -150 / 2 : -150
        
        let boundingRect = CGRect(x: -circleDiameterWidth / 2, y: yPosition, width: circleDiameterWidth, height: circleDiameterWidth / 2.5).insetBy(dx: 5, dy: 5) // making our rectangle in the exact same position as our circleView.
        
        let ellipseInBoundingRect = CGPath(ellipseIn: boundingRect, transform: nil) // first we create just a path of an ellipse in the boundingRect.
        
        let orbitAnimation = CAKeyframeAnimation()
        orbitAnimation.keyPath = "position" // we will be changing the x and y position of our square.
        orbitAnimation.path = createPathRotatedAroundBoundingBoxCenter(path: ellipseInBoundingRect, radians: radians)
        orbitAnimation.duration = duration
//        orbit.speed = 0.1 // changes speed of the animation.
        orbitAnimation.repeatCount = Float.infinity
        orbitAnimation.isAdditive = true
        orbitAnimation.calculationMode = CAAnimationCalculationMode.paced // creating an even pace of the keyframes in the animation.
        orbitAnimation.rotationMode = CAAnimationRotationMode.rotateAuto
        
        return orbitAnimation
    }
    
    func animateOrbit() {
        redView.layer.add(createOrbitAnimation(withRadians: .pi / 4, initialDuration: CFTimeInterval.random(in: 1.5...2.5)), forKey: "redboxOrbit")
        greenView.layer.add(createOrbitAnimation(withRadians: -.pi / 4, initialDuration: CFTimeInterval.random(in: 1.5...2.5)), forKey: "greenBoxOrbit")
        yellowView.layer.add(createOrbitAnimation(withRadians: .pi / 2, initialDuration: CFTimeInterval.random(in: 1.5...2.5)), forKey: "yellowBoxOrbit")
    }
    
    func createPathRotatedAroundBoundingBoxCenter(path: CGPath, radians: CGFloat) -> CGPath {
        let bounds = path.boundingBox
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var transform = CGAffineTransform(translationX: 0, y: 0)
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        return path.copy(using: &transform)!
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        // The above guard let lines keep us safe, since sometimes Swift will read the code two times - for the ball as bodyA and for the ball as bodyB in the collision. The first time it runs is fine - the ball is just destroyed. But if it runs the second time, there is nothing to be destroyed, and because we assured that there WILL be a ball to destroy (node!), the game crashes. This lets us replace "contact.bodyA.node!" with just "nodeA" and "contact.bodyB.node!" with "nodeB", preventing the game from crashing.

        if nodeA.name == "ball" {
//            collision(between: nodeA, object: nodeB)
        // If the first body (bodyA) is the ball, we will call the collision between two objects, using nodeA for the ball, and nodeB for the other object.
        } else if nodeB.name == "ball" {
//            collision(between: nodeB, object: nodeA)
        // If the second body (bodyB) is the ball, we will call the collision between two objects, using nodeB for the ball, and nodeA for the other object.
        }
        // Now we will view a game over alert, which will happen if there is no balls left and the scene does NOT have any boxes left.
        if nodeA.name == "box" {
//            collisionBallBox(between: nodeA, object: nodeB)
        } else if nodeB.name == "box" {
//            collisionBallBox(between: nodeB, object: nodeA)
        }
    }
    
}
