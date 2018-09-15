import ARKit

class Ball: SCNNode {

    override init() {
        super.init()
        
        self.geometry = SCNSphere(radius: 0.2)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody?.restitution = 1.6
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func setPosition(_ sceneView: ARSCNView) {
        func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
            let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

            // Setup a translation matrix with the desired position
            var translationMatrix = matrix_identity_float4x4
            translationMatrix.columns.3.x = position.x
            translationMatrix.columns.3.y = position.y
            translationMatrix.columns.3.z = position.z

            // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
            let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
            node.transform = SCNMatrix4(updatedTransform)
        }

        let POV = sceneView.pointOfView
        let position = SCNVector3(x: 0, y: -0.5, z: -1.0)
        updatePositionAndOrientationOf(self, withPosition: position, relativeTo: POV!)
    }
    
    func addToRoot(_ sceneView: ARSCNView) {
        sceneView.scene.rootNode.addChildNode(self)
    }
    
    func applyForce(_ camera: ARCamera) {
        let force = simd_make_float4(-2.5, 0, -2, 0)
        let rotation = simd_mul(camera.transform, force)
        let forceVector = SCNVector3(x: rotation.x, y: rotation.y, z: rotation.z)
        self.physicsBody?.applyForce(forceVector, asImpulse: true)
    }
}
