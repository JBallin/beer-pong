//
//  Ball.swift
//  beer-pong
//
//  Created by Jonathan Pilovsky on 9/14/18.
//  Copyright © 2018 Jonathan Pilovsky. All rights reserved.
//

import ARKit

class Ball: SCNNode {

    override init() {
        super.init()
        
        self.geometry = SCNSphere(radius: 0.2)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        self.physicsBody?.restitution = 1
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func setPosition(_ camera: ARCamera) {
        self.simdTransform = camera.transform
    }
    
    func addToRoot(_ sceneView: ARSCNView) {
        sceneView.scene.rootNode.addChildNode(self)
    }
    
    func applyForce(_ camera: ARCamera) {
        let force = simd_make_float4(-2, 0, -3, 0)
        let rotation = simd_mul(camera.transform, force)
        let forceVector = SCNVector3(x: rotation.x, y: rotation.y, z: rotation.z)
        self.physicsBody?.applyForce(forceVector, asImpulse: true)
    }
}
