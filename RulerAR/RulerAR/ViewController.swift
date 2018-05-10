//
//  ViewController.swift
//  RulerAR
//
//  Created by Spencer Cawley on 5/10/18.
//  Copyright © 2018 Spencer Cawley. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ViewController: UIViewController {
    
    // Properties
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var trashImage: UIImageView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetImage: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var meterButton: UIButton!
    
    var session = ARSession()
    var sessionConfig = ARWorldTrackingConfiguration()
    var isMeasuring = false
    var vectorZero = SCNVector3()
    var startValue = SCNVector3()
    var endValue = SCNVector3()
    var lines: [Line] = []
    var currentLine: Line?
    var unit: DistanceUnit = .inch
    
    // IBActions
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        clearButton.isHidden = true
        trashImage.isHidden = true
        for line in lines {
            line.removeFromParentNode()
        }
        lines.removeAll()
    }
    
    @IBAction func meterButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Settings", message: "Select a distance unit option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: DistanceUnit.centimeter.title, style: .default, handler: { [weak self] _ in
            self?.unit = .centimeter
        }))
        alert.addAction(UIAlertAction(title: DistanceUnit.inch.title, style: .default, handler: { [weak self] _ in
            self?.unit = .inch
        }))
        alert.addAction(UIAlertAction(title: DistanceUnit.meter.title, style: .default, handler: { [weak self] _ in
            self?.unit = .meter
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared
        .isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // reset values
        isMeasuring = true
        targetImage.image = UIImage(named: "greenTarget")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMeasuring = false
        targetImage.image = UIImage(named: "redTarget")
        if let line = currentLine {
            lines.append(line)
            currentLine = nil
            clearButton.isHidden = false
            trashImage.isHidden = false
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.detectObjects()
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        messageLabel.text = "Error occured"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "Interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "Interruption ended"
    }
}

extension ViewController {
    func setupScene() {
        targetImage.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        messageLabel.text = "Detecting the world..."
        clearButton.isHidden = true
        trashImage.isHidden = true
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
    }
    
    func resetValues() {
        isMeasuring = false
        startValue = SCNVector3()
        endValue = SCNVector3()
    }
    
    func detectObjects() {
        guard let worldPosition = sceneView.realWorldVector(screenPosition: view.center) else { return }
        targetImage.isHidden = false
        meterButton.isHidden = false
        if lines.isEmpty {
            messageLabel.text = "Hold screen & move your iPhone..."
        }
        loadingView.stopAnimating()
        if isMeasuring {
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)
            messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating..."
        }
    }
}

