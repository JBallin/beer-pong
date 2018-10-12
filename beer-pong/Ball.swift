import ARKit

class Ball: SCNNode {
    private let ballRadius = CGFloat(0.02)
    private let ballColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.995)
    private let ballRollingFriction = CGFloat(0.05)
    private let ballStartPosition = SCNVector3(x: 0, y: -0.05, z: -0.2)
    private let appliedForce = simd_make_float4(-2.2, 0, -1.0, 0)
    weak var hostViewController: ViewController?

    override init() {
        super.init()
        createPhysicalBall()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    // MARK: - Create Ball

    private func createPhysicalBall() {
        self.name = "ball"

        let geometry = SCNSphere(radius: ballRadius)
        let material = SCNMaterial()
        material.diffuse.contents = ballColor
        geometry.firstMaterial = material
        self.geometry = geometry

        let physicsShape = SCNPhysicsShape(geometry: geometry)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.rollingFriction = ballRollingFriction
        self.physicsBody = physicsBody
    }

    // MARK: - Add Ball to Scene

    public func position(in sceneView: ARSCNView) {
        if let pov = sceneView.pointOfView {
            updatePositionAndOrientationOf(node: self, withPosition: ballStartPosition, relativeTo: pov)
        } else if let host = self.hostViewController {
            host.alertError(title: "Error getting point of view")
        }
    }

    public func addTo(_ sceneView: ARSCNView) {
        sceneView.scene.rootNode.addChildNode(self)
    }

    // MARK: - Throw Ball

    public func applyForce(_ camera: ARCamera) {
        let force = appliedForce
        let rotation = simd_mul(camera.transform, force)
        let forceVector = SCNVector3(x: rotation.x, y: rotation.y, z: rotation.z)
        if let ballPhysics = self.physicsBody {
            ballPhysics.applyForce(forceVector, asImpulse: true)
        } else if let host = self.hostViewController {
            host.alertError(title: "Error getting ball physics")
        }
    }

    // MARK: - Calculate Position and Orientation

    private func updatePositionAndOrientationOf(node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = transform(for: referenceNode)
        let translationMatrix = createTranslationMatrix(at: position)
        let translatedPositionAndOrientation = combine(referenceNodeTransform, translationMatrix)
        updateTransform(of: node, with: translatedPositionAndOrientation)
    }

    private func createTranslationMatrix(at position: SCNVector3) -> simd_float4x4 {
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = position.x
        translationMatrix.columns.3.y = position.y
        translationMatrix.columns.3.z = position.z
        return translationMatrix
    }

    private func transform(for referenceNode: SCNNode) -> matrix_float4x4 {
        return matrix_float4x4(referenceNode.transform)
    }

    private func combine(_ transform: simd_float4x4, _ translation: matrix_float4x4) -> simd_float4x4 {
        return matrix_multiply(transform, translation)
    }

    private func updateTransform(of node: SCNNode, with transform: simd_float4x4) {
        node.transform = SCNMatrix4(transform)
    }
}
