//
//  Line.swift
//  RulerAR
//
//  Created by Spencer Cawley on 5/10/18.
//  Copyright © 2018 Spencer Cawley. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

enum DistanceUnit {
    case centimeter
    case inch
    case feet
    case meter
    
    var factor: Float {
        switch self {
        case .centimeter:
            return 100.0
        case .inch:
            return 39.3700787
        case .feet:
            return 3.280839895
        case .meter:
            return 1.0
        
        }
    }
    
    var unit: String {
        switch self {
        case .centimeter:
            return "cm"
        case .inch:
            return "in"
        case .feet:
            return "ft"
        case .meter:
            return "m"
        }
    }
    
    var title: String {
        switch self {
        case .centimeter:
            return "Centimeter"
        case .inch:
            return "Inch"
        case .feet:
            return "Feet"
        case .meter:
            return "Meter"
        }
    }
}

class Line {
    
    var startNode: SCNNode!
    var endNode: SCNNode!
    var text: SCNText!
    var textNode: SCNNode!
    var lineNode: SCNNode?
    
    let sceneView: ARSCNView!
    let startVector: SCNVector3!
    let unit: DistanceUnit!

    init(sceneView: ARSCNView, startVector: SCNVector3, unit: DistanceUnit) {
        self.sceneView = sceneView
        self.startVector = startVector
        self.unit = unit
        
        let dot = SCNSphere(radius: 1.0)
        dot.firstMaterial?.diffuse.contents = UIColor.blue
        dot.firstMaterial?.lightingModel = .constant
        dot.firstMaterial?.isDoubleSided = true
        startNode = SCNNode(geometry: dot)
        startNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        startNode.position = startVector
        sceneView.scene.rootNode.addChildNode(startNode)
        
        endNode = SCNNode(geometry: dot)
        endNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        
        text = SCNText(string: "", extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 10)
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode = kCAAlignmentCenter
        text.truncationMode = kCATruncationMiddle
        text.firstMaterial?.isDoubleSided = true
        
        let textWrapNode = SCNNode(geometry: text)
        textWrapNode.eulerAngles = SCNVector3Make(0, .pi, 0)
        textWrapNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        
        textNode = SCNNode()
        textNode.addChildNode(textWrapNode)
        let constraint = SCNLookAtConstraint(target: sceneView.pointOfView)
        constraint.isGimbalLockEnabled = true
        textNode.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    func update(to vector: SCNVector3) {
        lineNode?.removeFromParentNode()
        lineNode = startVector.line(to: vector, color: UIColor.white)
        sceneView.scene.rootNode.addChildNode(lineNode!)
        
        text.string = distance(to: vector)
        textNode.position = SCNVector3((startVector.x+vector.x)/2.0, (startVector.y+vector.y)/2.0, (startVector.z+vector.z)/2.0)
        
        endNode.position = vector
        if endNode.parent == nil {
            sceneView.scene.rootNode.addChildNode(endNode)
        }
        
    }
    
    func distance(to vector: SCNVector3) -> String {
        return String(format: "%.2f%@", startVector.distance(from: vector) * unit.factor, unit.unit)
    }
    
    func removeFromParentNode() {
        startNode.removeFromParentNode()
        endNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        textNode.removeFromParentNode()
    } 
}



















