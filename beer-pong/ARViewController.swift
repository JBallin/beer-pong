import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var tablePlaced = false
    private var ballSunkSound: SCNAudioSource!
    private var sunkCups = [SCNNode]()
    private var planeNode: SCNNode?
    private let planeColor = UIColor(red: 255/255, green: 0, blue: 0, alpha: 0.5)
    private let planeDetectorName = "plane detector"

    // MARK: - Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        initScene()
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

    // Mark: - Scene

    private func initScene() {
        sceneView.delegate = self
        sceneView.scene = SCNScene()
    }

    private func addLighting() {
        sceneView.autoenablesDefaultLighting = true
    }

    private func loadSound() {
        let sunkSoundPath = "art.scnassets/sunk.wav"
        ballSunkSound = SCNAudioSource(fileNamed: sunkSoundPath)
        ballSunkSound.load()
    }

    // Mark: - Physics

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
        let tableName = "table"
        let tableTopName = "top"
        let legName = "leg"

        if let tableNode = node.childNode(withName: tableName, recursively: true) {
            let legs = tableNode.childNodes.filter {
                if let name = $0.name {
                    return name.contains(legName)
                } else {
                    return false
                }
            }
            let legGeometry = SCNBox(width: legThickness, height: legHeight, length: legThickness, chamferRadius: 0)
            let legShape = SCNPhysicsShape(geometry: legGeometry)
            legs.forEach {
                let physics = SCNPhysicsBody(type: .static, shape: legShape)
                physics.restitution = tableRestitution
                $0.physicsBody = physics
            }

            if let tableTopNode = node.childNode(withName: tableTopName, recursively: true) {
                let tableTopShape = SCNPhysicsShape(geometry: SCNBox(width: tableTopWidth, height: tableTopHeight, length: tableTopLength, chamferRadius: 0))
                let tableTopPhysics = SCNPhysicsBody(type: .static, shape: tableTopShape)
                tableTopPhysics.restitution = tableRestitution
                tableTopNode.physicsBody = tableTopPhysics
            } else {
                alertError(title: "Error finding table-top")
            }
        } else {
            alertError(title: "Error finding table")
        }
    }

    private func addCupsPhysics(to node: SCNNode) {
        let bottomRestitution = CGFloat(0.0)
        let sideRestitution = CGFloat(0.1)
        let cupsName = "cups"
        let cupBottomName = "bottom"
        let cupSideName = "side"

        if let cupsNode = node.childNode(withName: cupsName, recursively: true) {
            for cup in cupsNode.childNodes {
                for child in cup.childNodes {
                    let shapeOptions = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
                    let childShape = SCNPhysicsShape(node: child, options: shapeOptions)
                    let childPhysics = SCNPhysicsBody(type: .static, shape: childShape)
                    if child.name == cupBottomName {
                        childPhysics.contactTestBitMask = Ball().categoryBitMask
                        childPhysics.restitution = bottomRestitution
                    } else if child.name == cupSideName {
                        if let geometry = child.geometry {
                            geometry.materials.forEach({ $0.isDoubleSided = true })
                        } else {
                            alertError(title: "Error with cup child geometry")
                        }
                        childPhysics.restitution = sideRestitution
                    } else {
                        alertError(title: "Error with cup child name")
                    }
                    child.physicsBody = childPhysics
                }
            }
        } else {
            alertError(title: "Error finding cups")
        }
    }

    private func addFloorPhysics(to node: SCNNode) {
        let floorRollingFriction = CGFloat(0.05)
        let floorRestitutuion = CGFloat(1.1)
        let floorName = "floor"

        if let floorNode = node.childNode(withName: floorName, recursively: true) {
            let floorPhysics = SCNPhysicsBody(type: .static, shape: nil)
            floorPhysics.rollingFriction = floorRollingFriction
            floorPhysics.restitution = floorRestitutuion
            floorNode.physicsBody = floorPhysics
        } else {
            alertError(title: "Error finding floor")
        }
    }

    // MARK: - Collision Notifications

    private func addPhysicsContactDelegate() {
        sceneView.scene.physicsWorld.contactDelegate = self
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let cupBottom = contact.nodeB
        if let cup = cupBottom.parent {
            playBallSunkSound(toNode: cup)

            let ball = contact.nodeA
            if let ballPhysics = ball.physicsBody {
                ballPhysics.restitution = 0.0
            } else {
                alertError(title: "Error loading ball physics")
            }

            fadeOut(cup, ball)
        } else {
            alertError(title: "Error loading cup bottom parent")
        }
    }

    // MARK: - Cup Animation & Sound

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

    // MARK: - Gestures
    
    @IBAction func onViewTapped(_ sender: UITapGestureRecognizer) {
        if tablePlaced {
            let ball = Ball()
            ball.hostViewController = self
            if let currFrame = sceneView.session.currentFrame {
                let camera = currFrame.camera
                ball.position(in: sceneView)
                ball.addTo(sceneView)
                ball.applyForce(camera)
            } else {
                alertError(title: "Error loading current frame")
            }
        } else {
            let tapLocation = sender.location(in: sceneView)
            let hits = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            if let hit = hits.first {
                placeTable(hit)
                tablePlaced = true
                disablePlaneScanning()
            }
        }
    }

    // MARK: - Place Table

    private func placeTable(_ hit: ARHitTestResult) {
        let planePosition = calcPlanePosition(from: hit)
        addTableToScene(at: planePosition)
    }

    private func calcPlanePosition(from hit: ARHitTestResult) -> SCNVector3 {
        let transform = hit.worldTransform
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }

    private func addTableToScene(at position: SCNVector3) {
        if let tableNode = createTableFromScene(at: position) {
            sceneView.scene.rootNode.addChildNode(tableNode)
        } else {
            alertError(title: "Error creating table from scene")
        }
    }

    private func createTableFromScene(at position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "table", withExtension: "scn", subdirectory: "art.scnassets") else {
            alertError(title: "Error finding table scene")
            return nil
        }
        guard let tableScene = SCNReferenceNode(url: url) else {
            alertError(title: "Error loading table scene")
            return nil
        }

        tableScene.load()
        tableScene.position = position
        addPhysics(to: tableScene)
        return tableScene
    }

    // MARK: - Plane Detection

    private func addHorizontalPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    private func disablePlaneScanning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        sceneView.session.run(configuration)
        sceneView.scene.rootNode.enumerateChildNodes() {
            node, stop in
            if node.name == planeDetectorName {
                node.removeFromParentNode()
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))

        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = planeColor
        plane.firstMaterial = planeMaterial

        let planeNode = SCNNode(geometry: plane)
        planeNode.name = planeDetectorName
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)

        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)

        node.addChildNode(planeNode)
    }

    // MARK: - Error Handling

    public func alertError(title: String) {
        let message = "Please try restarting the app"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
        self.present(alertController, animated: true, completion: nil)
    }
}
