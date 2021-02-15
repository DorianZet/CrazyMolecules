//
//  ViewController.swift
//  MoleculesGame
//
//  Created by Mateusz Zacharski on 05/02/2021.
//

// Full keypath list full Keypath list for Core Animation:
// https://stackoverflow.com/questions/44230796/what-is-the-full-keypath-list-for-cabasicanimation

import UIKit

class ViewController: UIViewController, UICollisionBehaviorDelegate {
    
    lazy var moleculeWidth: CGFloat = view.bounds.width / 12
    lazy var moleculeHeight: CGFloat = view.bounds.width / 12
    
    let redView = UIView()
    let redCircle = UIImageView()
    
    let greenView = UIView()
    let greenCircle = UIImageView()
    
    let yellowView = UIView()
    let yellowCircle = UIImageView()
    
    lazy var circleDiameterWidth: CGFloat = view.bounds.width
    
    var animator: UIDynamicAnimator!
    
    var displayLink: CADisplayLink!
    
    func createButton(bgColor color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color
        button.layer.cornerRadius = 10
        button.setTitle(">>", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(tapButtonSpeedUp), for: .touchDown)
        button.addTarget(self, action: #selector(tapButtonSpeedDown), for: .touchUpInside)
        return button
    }
    
    lazy var redButton: UIButton = createButton(bgColor: .systemRed) // the same way we can create green and yellow button.
    lazy var greenButton: UIButton = createButton(bgColor: .systemGreen)
    lazy var yellowButton: UIButton = createButton(bgColor: .systemYellow)
    
    lazy var bottomStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 16
        [redButton, yellowButton, greenButton].forEach { (button) in
            sv.addArrangedSubview(button)
        }
        return sv
    }()
        
    @objc fileprivate func tapButtonSpeedUp(sender: UIButton) {
        var currentView: UIView!
        
        if sender == redButton {
            currentView = redView
        } else if sender == yellowButton {
            currentView = yellowView
        } else {
            currentView = greenView
        }
        
        currentView.layer.timeOffset = currentView.layer.convertTime(CACurrentMediaTime(), from: nil)
        currentView.layer.beginTime = CACurrentMediaTime()
        currentView.layer.speed = 2.5
    }
    
    @objc fileprivate func tapButtonSpeedDown(sender: UIButton) {
        var currentView: UIView!
        
        if sender == redButton {
            currentView = redView
        } else if sender == yellowButton {
            currentView = yellowView
        } else {
            currentView = greenView
        }
        
        currentView.layer.timeOffset = currentView.layer.convertTime(CACurrentMediaTime(), from: nil)
        currentView.layer.beginTime = CACurrentMediaTime()
        currentView.layer.speed = 1.0
    }
    
    func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handle(_:)))
        displayLink.add(to: RunLoop.current, forMode: .common)
    }
    
    func checkForIntersectionBetween(layer1: CALayer, layer2: CALayer) {
        if layer1.frame.intersects(layer2.frame) {
            if CGPointDistance(from: layer1.position, to: layer2.position) < moleculeWidth {
                print("collision")
                
                redView.layer.removeAnimation(forKey: "redboxOrbit") // stop the animation if you want
                yellowView.layer.removeAnimation(forKey: "yellowBoxOrbit")
                greenView.layer.removeAnimation(forKey: "greenBoxOrbit")

                redView.layer.position = redView.layer.presentation()!.position
                yellowView.layer.position = yellowView.layer.presentation()!.position
                greenView.layer.position = greenView.layer.presentation()!.position
                
                simulateCollisionAndGravity()
                stopDisplayLink() // stop the display link if we don't need it any more
            }
        }
    }
    
    @objc func handle(_ displayLink: CADisplayLink?) {
        let view1PresentationLayer = redView.layer.presentation()
        let view2PresentationLayer = yellowView.layer.presentation()
        let view3PresentationLayer = greenView.layer.presentation()
        
        
        [view1PresentationLayer, view2PresentationLayer].forEach { (presentationLayer) in
            checkForIntersectionBetween(layer1: presentationLayer!, layer2: view3PresentationLayer!)
        }
        
        [view1PresentationLayer, view3PresentationLayer].forEach { (presentationLayer) in
            checkForIntersectionBetween(layer1: presentationLayer!, layer2: view2PresentationLayer!)
        }
        
        [view2PresentationLayer, view3PresentationLayer].forEach { (presentationLayer) in
            checkForIntersectionBetween(layer1: presentationLayer!, layer2: view1PresentationLayer!)
        }
        
        //
        
        
//        if view1PresentationLayer!.frame.intersects(view2PresentationLayer!.frame) {
//            // collide the molecules only when the distance between their centers is less then their summed radiuses - in this way, the collision will correctly occur when the circles touch each other.
//            if CGPointDistance(from: view1PresentationLayer!.position, to: view2PresentationLayer!.position) < moleculeWidth {
//                print("collision")
//
//                redView.layer.removeAnimation(forKey: "redboxOrbit") // stop the animation if you want
//                yellowView.layer.removeAnimation(forKey: "yellowBoxOrbit")
//                greenView.layer.removeAnimation(forKey: "greenBoxOrbit")
//
//                redView.layer.position = view1PresentationLayer!.position
//                yellowView.layer.position = view2PresentationLayer!.position
//                greenView.layer.position = view3PresentationLayer!.position
//
//                simulateCollisionAndGravity()
////                stopDisplayLink() // stop the display link if we don't need it any more
//            }
//        }
    }
    
    func stopDisplayLink() {
        if displayLink != nil {
            displayLink.invalidate()
            displayLink = nil
        }
        
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem, with item2: UIDynamicItem, at p: CGPoint) {
        print("CONTACT")
    }

    func simulateCollisionAndGravity() {
        animator = UIDynamicAnimator(referenceView: view)
        let gravityBehavior = UIGravityBehavior(items: [redView, greenView, yellowView])
        
        let collisionBehavior = UICollisionBehavior(items: [redView, greenView, yellowView])
        collisionBehavior.addBoundary(withIdentifier: "redBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.redView.bounds))
        collisionBehavior.addBoundary(withIdentifier: "greenBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.greenView.bounds))
        collisionBehavior.addBoundary(withIdentifier: "yellowBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.yellowView.bounds))
        collisionBehavior.collisionDelegate = self

        animator.addBehavior(collisionBehavior)
        animator.addBehavior(gravityBehavior)
    }
    
    func configureViews() {
        [redView, greenView, yellowView].forEach { (v) in
            v.frame = CGRect(x: view.bounds.midX - moleculeWidth / 2, y: view.bounds.midY - moleculeHeight / 2, width: moleculeWidth, height: moleculeHeight)
            v.layer.cornerRadius = moleculeWidth / 2
            v.layer.masksToBounds = true
            v.clipsToBounds = true
            v.layer.borderWidth = 2
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.zPosition = 5
        }
        
        let yPosition: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -150 / 2 : -150

        
        [redCircle, greenCircle, yellowCircle].forEach { (circle) in
            circle.frame = CGRect(x: view.bounds.midX - circleDiameterWidth / 2, y: view.bounds.midY + yPosition, width: circleDiameterWidth, height: circleDiameterWidth / 2.5)
            circle.image = drawCircleImage()
        }
        
        redCircle.transform = CGAffineTransform(rotationAngle: .pi / 4)
        greenCircle.transform = CGAffineTransform(rotationAngle: -.pi / 4)
        yellowCircle.transform = CGAffineTransform(rotationAngle: .pi / 2)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Once we are here our view is layed out, so we can dynamically center it on the screen with no hardcoded values.
        
        configureViews()

        animateOrbit()
        startDisplayLink()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        [redView, redCircle, greenView, greenCircle, yellowView, yellowCircle].forEach { (v) in
            self.view.addSubview(v)
        }
        
        redView.backgroundColor = .systemRed
        greenView.backgroundColor = .systemGreen
        yellowView.backgroundColor = .systemYellow
        
        self.view.addSubview(bottomStackView)
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStackView.heightAnchor.constraint(equalToConstant: 50),
            bottomStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
//            redButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            bottomStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    
    func createOrbitAnimation(withRadians radians: CGFloat, initialDuration duration: CFTimeInterval) -> CAKeyframeAnimation {
        let yPosition: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -150 / 2 : -150

        let boundingRect = CGRect(x: -circleDiameterWidth / 2, y: yPosition, width: circleDiameterWidth, height: circleDiameterWidth / 2.5).insetBy(dx: 5, dy: 5) // making our rectangle in the exact same position as our circleView.
        
        let ellipseInBoundingRect = CGPath(ellipseIn: boundingRect, transform: nil) // first we create just a path of an ellipse in the boundingRect.
        
        let orbitAnimation = CAKeyframeAnimation()
        orbitAnimation.keyPath = "position" // we will be changing the x and y position of our square.
        orbitAnimation.path = createPathRotatedAroundBoundingBoxCenter(path: ellipseInBoundingRect, radians: radians)
        orbitAnimation.duration = duration
        orbitAnimation.speed = 0.3 // changes speed of the animation.
        orbitAnimation.repeatCount = Float.infinity
        orbitAnimation.isAdditive = true
        orbitAnimation.calculationMode = CAAnimationCalculationMode.paced // creating an even pace of the keyframes in the animation.
        orbitAnimation.rotationMode = CAAnimationRotationMode.rotateAuto
        
        return orbitAnimation
    }
    
    func animateOrbit() {
        redView.layer.add(createOrbitAnimation(withRadians: .pi / 4, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "redboxOrbit")
        greenView.layer.add(createOrbitAnimation(withRadians: -.pi / 4, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "greenBoxOrbit")
        yellowView.layer.add(createOrbitAnimation(withRadians: .pi / 2, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "yellowBoxOrbit")
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
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
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
    
}


