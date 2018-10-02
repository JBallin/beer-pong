import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var tablePlaced = false
    var ballSunkSound: SCNAudioSource!
    var sunkCups = [SCNNode]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setScene()
        addPhysicsContactDelegate()
        addLighting()
        loadSound()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addHorizontalPlaneDetection()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }

    // Mark: - Scene

    private func setScene() {
        sceneView.delegate = self
        sceneView.scene = SCNScene()
    }

    private func addLighting() { sceneView.autoenablesDefaultLighting = true }

    private func loadSound() {
        ballSunkSound = SCNAudioSource(fileNamed: "art.scnassets/sunk.wav")
        ballSunkSound.load()
    }

    // Mark: - Physics

    private func addPhysicsContactDelegate() { sceneView.scene.physicsWorld.contactDelegate = self }

    private func addHorizontalPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let cupBottom = contact.nodeB
        let cup = cupBottom.parent!
        let ball = contact.nodeA
        playBallSunkSound(toNode: cup)
        ball.physicsBody?.restitution = 0.0
        fadeOut(cup, ball)
    }

    private func fadeOut(_ cup: SCNNode, _ ball: SCNNode) {
        let shortFade = 0.5
        let longFade = 0.75

        func fade(_ node: SCNNode, duration: Double) {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = duration
            node.opacity = 0.0
            SCNTransaction.commit()
        }

        func hide(_ node: SCNNode) {
            let hideTime = longFade
            SCNTransaction.begin()
            SCNTransaction.animationDuration = hideTime
            node.isHidden = true
            SCNTransaction.commit()
        }

        fade(cup, duration: shortFade)
        fade(ball, duration: longFade)
        hide(cup)
        hide(ball)
    }

    func playBallSunkSound(toNode node: SCNNode) {
        if !sunkCups.contains(node) {
            node.runAction(SCNAction.playAudio(ballSunkSound, waitForCompletion: true))
            sunkCups.append(node)
        }
    }

    private func addPhysics(to node: SCNNode) {
        addTablePhysics(to: node)
        addCupsPhysics(to: node)
        addFloorPhysics(to: node)
    }

    private func addTablePhysics(to node: SCNNode) {
        let tableRestitution = CGFloat(1.3)
        let legThickness = CGFloat(0.06)
        let legHeight = CGFloat(0.67)
        let tableTopHeight = CGFloat(0.06)
        let tableTopWidth = CGFloat(1.0)
        let tableTopLength = CGFloat(1.5)

        let tableNode = node.childNode(withName: "table", recursively: true)!

        let legs = tableNode.childNodes.filter({ ($0.name?.contains("leg"))! })
        let legShape = SCNPhysicsShape(geometry: SCNBox(width: legThickness, height: legHeight, length: legThickness, chamferRadius: 0))
        legs.forEach {
            (leg) in
            leg.physicsBody = SCNPhysicsBody(type: .static, shape: legShape)
            leg.physicsBody?.restitution = tableRestitution
        }

        let tableTopNode = node.childNode(withName: "top", recursively: true)!
        let tableTopShape = SCNPhysicsShape(geometry: SCNBox(width: tableTopWidth, height: tableTopHeight, length: tableTopLength, chamferRadius: 0))
        tableTopNode.physicsBody = SCNPhysicsBody(type: .static, shape: tableTopShape)
        tableTopNode.physicsBody?.restitution = tableRestitution
    }

    private func addCupsPhysics(to node: SCNNode) {
        let bottomRestitution = CGFloat(0.0)
        let sideRestitution = CGFloat(0.1)
        let cupsNode = node.childNode(withName: "cups", recursively: true)!
        for cup in cupsNode.childNodes {
            for child in cup.childNodes {
                let childShape = SCNPhysicsShape(node: child, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
                child.physicsBody = SCNPhysicsBody(type: .static, shape: childShape)
                if child.name == "bottom" {
                    child.physicsBody?.contactTestBitMask = (Ball().physicsBody?.categoryBitMask)!
                    child.physicsBody?.restitution = bottomRestitution
                }
                if child.name == "side" {
                    child.geometry?.materials.forEach({ $0.isDoubleSided = true })
                    child.physicsBody?.restitution = sideRestitution
                }
            }
        }
    }

    private func addFloorPhysics(to node: SCNNode) {
        let floorRollingFriction = CGFloat(0.05)
        let floorRestitutuion = CGFloat(1.1)

        let floorNode = node.childNode(withName: "floor", recursively: true)
        floorNode?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode?.physicsBody?.rollingFriction = floorRollingFriction
        floorNode?.physicsBody?.restitution = floorRestitutuion
    }



        return node
    }

    // MARK: - ARSCNViewDelegate

    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create an SNCPlane on the ARPlane
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }

        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))

        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 0, blue: 0, alpha: 0.5)
        plane.materials = [planeMaterial]

        let planeNode = SCNNode(geometry: plane)
        planeNode.name = "plane detector"
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)

        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)

        node.addChildNode(planeNode)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
