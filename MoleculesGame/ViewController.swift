//
//  ViewController.swift
//  MoleculesGame
//
//  Created by Mateusz Zacharski on 05/02/2021.
//

// Full keypath list full Keypath list for Core Animation:
// https://stackoverflow.com/questions/44230796/what-is-the-full-keypath-list-for-cabasicanimation

// THERE SEEMS TO BE A BUG WHEN WE INITIALIZE THE ELLIPSE ANIMATION OF THE VIEWS. ONCE WE DO IT, THERE IS A VERY FAST BLINK OF THE VIEWS IN THE CENTER OF THE SCREEN JUST BEFORE THE ANIMATION STARTS. MOST LIKELY IT HAS SOMETHING TO DO WITH CABASICANIMATION. TO DEAL WITH THAT, I CAN INTRODUCE SLOW FADE-OUT OF THE VIEWS WHEN THE RELOAD BUTTON IS PRESSED, A SLOW FADE-IN OF THE VIEWS IN AT THEIR STARTING POINT ON THE ELLIPSES, AND THEN START THE ANIMATION AFTER PREVIOUSLY DESIGNATED TIME.

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
    
    var animator: UIDynamicAnimator?
    
    var displayLink: CADisplayLink!
    
    var reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "reload"), for: .normal)
        button.addTarget(self, action: #selector(handleReload), for: .touchUpInside)
        return button
    }()
    
    var newGameTimer: Timer?
    var newGameTime = 0
    
    var displayLinkTimer: Timer?
    var displayLinkTime = 0
    
    @objc fileprivate func handleReload() {
        newGame()
    }
    
    @objc fileprivate func tapButtonSpeedUp(sender: UIButton) {
        var currentView: UIView!
        
        if sender == bottomStackView.redButton {
            currentView = redView
        } else if sender == bottomStackView.yellowButton {
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
        
        if sender == bottomStackView.redButton {
            currentView = redView
        } else if sender == bottomStackView.yellowButton {
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
                
                animateShake()
                
                redView.layer.removeAnimation(forKey: "redboxOrbit")
                yellowView.layer.removeAnimation(forKey: "yellowBoxOrbit")
                greenView.layer.removeAnimation(forKey: "greenBoxOrbit")
                
                [redView, greenView, yellowView].forEach { (v) in
                    v.layer.position = v.layer.presentation()!.position // update the position of our views
                }
                
                simulateCollisionAndGravity()
                reloadButton.isHidden = false
                stopDisplayLink() // stop the display link if we don't need it any more
            }
        }
    }
    
    fileprivate func newGame() {
        animator?.removeAllBehaviors()
        animator = nil
        
        self.reloadButton.isHidden = true

        [redView, greenView, yellowView].forEach { (v) in
            v.layer.removeAllAnimations()
            v.transform = CGAffineTransform.identity // fixing a bug with squished molecules when starting a new game when the molecules are still bouncing.
            v.frame = CGRect(x: view.bounds.midX - moleculeWidth / 2, y: view.bounds.midY - moleculeHeight / 2, width: moleculeWidth, height: moleculeHeight)
            v.layer.speed = 1.0
            v.alpha = 0
        }
        
        newGameTime = 0
        newGameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleNewGameTimer), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func handleNewGameTimer() {
        newGameTime += 1
        
        if newGameTime == 3 {
            [redView, greenView, yellowView].forEach { (v) in
                v.alpha = 1
            }
            
            animateOrbit()

            displayLinkTime = 0
            displayLinkTimer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(handleDisplayLinkTimer), userInfo: nil, repeats: true)
            
            newGameTimer?.invalidate()
            newGameTimer = nil
        }
        
    }
    
    @objc fileprivate func handleDisplayLinkTimer() {
        displayLinkTime += 1
        
        if displayLinkTime == 1 {
            print("started display link")
            startDisplayLink()
            displayLinkTimer?.invalidate()
            displayLinkTimer = nil
        }
    }
    
    @objc fileprivate func handle(_ displayLink: CADisplayLink?) {
        let view1PresentationLayer = redView.layer.presentation()
        let view2PresentationLayer = yellowView.layer.presentation()
        let view3PresentationLayer = greenView.layer.presentation()
        
        [view1PresentationLayer, view2PresentationLayer].forEach { (presentationLayer) in
            checkForIntersectionBetween(layer1: presentationLayer!, layer2: view3PresentationLayer!)
        }
        checkForIntersectionBetween(layer1: view1PresentationLayer!, layer2: view2PresentationLayer!)
    }
    
    fileprivate func stopDisplayLink() {
        if displayLink != nil {
            displayLink.invalidate()
            displayLink = nil
        }
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem, with item2: UIDynamicItem, at p: CGPoint) {
        print("CONTACT")
    }

    fileprivate func simulateCollisionAndGravity() {
        animator = UIDynamicAnimator(referenceView: view)
        let moleculeViews = [redView, greenView, yellowView]
        
        let gravityBehavior = UIGravityBehavior(items: moleculeViews)
        
        let collisionBehavior = UICollisionBehavior(items: moleculeViews)
        collisionBehavior.addBoundary(withIdentifier: "redBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.redView.bounds))
        collisionBehavior.addBoundary(withIdentifier: "greenBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.greenView.bounds))
        collisionBehavior.addBoundary(withIdentifier: "yellowBoundary" as NSCopying, for: UIBezierPath(ovalIn: self.yellowView.bounds))
        collisionBehavior.addBoundary(withIdentifier: "viewBoundary" as NSCopying, for: UIBezierPath(rect: self.view.bounds))
        collisionBehavior.collisionDelegate = self
        
        let bounceBehavior = UIDynamicItemBehavior(items: moleculeViews)
        bounceBehavior.elasticity = 0.8
        bounceBehavior.friction = 0.2

        animator?.addBehavior(collisionBehavior)
        animator?.addBehavior(gravityBehavior)
        animator?.addBehavior(bounceBehavior)
    }
    
    fileprivate func configureViews() {
        [redView, greenView, yellowView].forEach { (v) in
            v.frame = CGRect(x: view.bounds.midX - moleculeWidth / 2, y: view.bounds.midY - moleculeHeight / 2, width: moleculeWidth, height: moleculeHeight)
            v.layer.cornerRadius = moleculeWidth / 2
            v.layer.masksToBounds = true
            v.clipsToBounds = true
            v.layer.borderWidth = 2
            v.layer.borderColor = UIColor.white.cgColor
            v.layer.zPosition = 5
            v.alpha = 0
        }
        
        redView.backgroundColor = .systemRed
        greenView.backgroundColor = .systemGreen
        yellowView.backgroundColor = .systemYellow
        
        let yPosition: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? -150 / 2 : -150
        
        [redCircle, greenCircle, yellowCircle].forEach { (circle) in
            circle.frame = CGRect(x: view.bounds.midX - circleDiameterWidth / 2, y: view.bounds.midY + yPosition, width: circleDiameterWidth, height: circleDiameterWidth / 2.5)
            circle.image = drawCircleImage()
        }
        
        redCircle.transform = CGAffineTransform(rotationAngle: .pi / 4)
        greenCircle.transform = CGAffineTransform(rotationAngle: -.pi / 4)
        yellowCircle.transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        [redView, redCircle, greenView, greenCircle, yellowView, yellowCircle].forEach { (v) in
            self.view.addSubview(v)
        }
        
        self.view.addSubview(reloadButton)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reloadButton.heightAnchor.constraint(equalToConstant: 75),
            reloadButton.widthAnchor.constraint(equalToConstant: 75),
            reloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reloadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        self.view.addSubview(bottomStackView)
        bottomStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomStackView.heightAnchor.constraint(equalToConstant: 75),
            bottomStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bottomStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bottomStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Once we are here our view is layed out, so we can dynamically center it on the screen with no hardcoded values.
        configureViews()
    }
    
    let bottomStackView = BottomControlsStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        [bottomStackView.redButton, bottomStackView.yellowButton, bottomStackView.greenButton].forEach { (button) in
            button.addTarget(self, action: #selector(tapButtonSpeedUp(sender:)), for: .touchDown)
            button.addTarget(self, action: #selector(tapButtonSpeedDown(sender:)), for: .touchUpInside)
        }
    }
    
    fileprivate func createOrbitAnimation(withRadians radians: CGFloat, initialDuration duration: CFTimeInterval) -> CAKeyframeAnimation {
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
    
    fileprivate func animateOrbit() {
        redView.layer.add(createOrbitAnimation(withRadians: .pi / 4, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "redboxOrbit")
        greenView.layer.add(createOrbitAnimation(withRadians: -.pi / 4, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "greenBoxOrbit")
        yellowView.layer.add(createOrbitAnimation(withRadians: .pi / 2, initialDuration: CFTimeInterval.random(in: 1...1.8)), forKey: "yellowBoxOrbit")
        CATransaction.commit()
        
        [redView, greenView, yellowView].forEach { (v) in
            v.alpha = 1
        }
    }
    
    fileprivate func createPathRotatedAroundBoundingBoxCenter(path: CGPath, radians: CGFloat) -> CGPath {
        let bounds = path.boundingBox
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var transform = CGAffineTransform(translationX: 0, y: 0)
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        return path.copy(using: &transform)!
    }
    
    fileprivate func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    fileprivate func CGPointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: from, to: to))
    }
    
    fileprivate func drawCircleImage() -> UIImage {
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
    
    fileprivate func animateShake() {
        let animation = CAKeyframeAnimation() // KeyFrame Animation works using... keyframes! The way the keyframes work is that we define all the different positions we would like our view to oscilate between.
        animation.keyPath = "position.x"
        animation.values = [0, 10, -10, 10, 0] // We define here the values of our keyframes. We say that we want our view to go from x=0 to x=10, then from x=10 to x=-10, then from x=-10 to x=10, and then back to x=0.
        animation.keyTimes = [0, 0.16, 0.5, 0.83, 1] // We specify the time at which we would like each value to to be. So we start with 0, then at 0.16 of the whole given time we want the view to be at x=10, then at 0.5 of the whole given time we want it to be at x=-10 and so on.
        animation.duration = 0.2 // we specify the duration of the shake in seconds.
//        animation.repeatCount = Float.infinity // uncomment this to make the shake infinite.
        
        animation.isAdditive = true // this means that each value is relative to the starting position (0).
        view.layer.add(animation, forKey: "animateShake")
    }
    
}


