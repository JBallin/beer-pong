//
//  ViewController.swift
//  beer-pong
//
//  Created by Jonathan Pilovsky on 9/11/18.
//  Copyright © 2018 Jonathan Pilovsky. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/pingPongBall.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // floor position + physics
        let floorNode = scene.rootNode.childNode(withName: "floor", recursively: true)
        floorNode?.position = SCNVector3(0, -3, 0)
        floorNode?.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

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
        let ballNode = sceneView.scene.rootNode.childNode(withName: "ball", recursively: true)
        ballNode?.position = SCNVector3(0, -0.7, -1)
        ballNode?.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode?.physicsBody?.restitution = 1
        ballNode?.physicsBody?.applyForce(SCNVector3Make(0, 2, -2.3), asImpulse: true)
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
