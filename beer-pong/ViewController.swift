import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var tablePlaced = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        // Set the scene
        sceneView.scene = SCNScene()

        // Add physics contact delegate for collision notifications
        sceneView.scene.physicsWorld.contactDelegate = self

        // Add lighting
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @IBAction func onViewTapped(_ sender: UITapGestureRecognizer) {
        if tablePlaced == true {
            let ball = Ball()
            let camera = sceneView.session.currentFrame?.camera

            ball.setPosition(sceneView)
            ball.addToRoot(sceneView)
            ball.applyForce(camera!)
        } else {
            // Get tap location
            let tapLocation = sender.location(in: sceneView)

            // Perform hit test
            let results = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

            // If a hit was received, get position of
            if let result = results.first {
                placeTable(result)
                tablePlaced = true
            }
        }
    }

    private func placeTable(_ result: ARHitTestResult) {
        // Get transform of result
        let transform = result.worldTransform

        // Get position from transform
        let planePosition = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)

        // Add table
        let tableNode = createTableFromScene(planePosition)!
        sceneView.scene.rootNode.addChildNode(tableNode)
    }

    private func createTableFromScene(_ position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "table", withExtension: "scn", subdirectory: "art.scnassets") else {
            NSLog("Could not find table scene")
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else { return nil }

        node.load()

        // Position scene
        node.position = position


        /* PHYSICS */

        /* Table */
        let tableNode = node.childNode(withName: "table", recursively: true)!
        // legs
        let legs = tableNode.childNodes.filter({ ($0.name?.contains("leg"))! })
        let legShape = SCNPhysicsShape(geometry: SCNBox(width: 0.06, height: 0.67, length: 0.06, chamferRadius: 0))
        legs.forEach { (leg) in
            leg.physicsBody = SCNPhysicsBody(type: .static, shape: legShape)
            leg.physicsBody?.restitution = 1.3
        }
        // top
        let tableTopNode = node.childNode(withName: "top", recursively: true)!
        let tableTopShape = SCNPhysicsShape(geometry: SCNBox(width: 1.0, height: 0.06, length: 1.5, chamferRadius: 0))
        tableTopNode.physicsBody = SCNPhysicsBody(type: .static, shape: tableTopShape)
        tableTopNode.physicsBody?.restitution = 1.3

        /* Cups */
        let cupsNode = node.childNode(withName: "cups", recursively: true)!
        for cup in cupsNode.childNodes {
            for child in cup.childNodes {
                let childShape = SCNPhysicsShape(node: child, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron])
                child.physicsBody = SCNPhysicsBody(type: .static, shape: childShape)
                child.physicsBody?.restitution = 0.1
                if child.name == "bottom" {
                    child.physicsBody?.contactTestBitMask = (Ball().physicsBody?.categoryBitMask)!
                }
            }
        }

        /* Floor */
        let floorNode = node.childNode(withName: "floor", recursively: true)
        floorNode?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorNode?.physicsBody?.rollingFriction = 0.05
        floorNode?.physicsBody?.restitution = 1.1


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
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        plane.materials = [planeMaterial]

        let planeNode = SCNNode(geometry: plane)
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
