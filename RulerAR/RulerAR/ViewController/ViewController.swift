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
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetImage: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var rulerImage: UIImageView!
    @IBOutlet weak var meterButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var toolbarView: UIView!
    
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
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        let image = sceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
//        captureScreen()
        
        let alert = UIAlertController(title: "Saved!", message: "Your image has been saved", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
//    func captureScreen() -> UIImage {
//        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0);
//        self.sceneView.drawHierarchy(in: sceneView.bounds, afterScreenUpdates: true)
//
//        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
//        UIGraphicsEndImageContext()
//        return image
//    }
    
    
    @IBAction func clearButtonTapped(_ sender: UIButton) {
        
        unitLabel.isHidden = true
        cameraButton.isHidden = true
        clearButton.isHidden = true
        unitLabel.text = ""
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
        alert.addAction(UIAlertAction(title: DistanceUnit.feet.title, style: .default, handler: { [weak self] _ in
            self?.unit = .feet
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetValues()
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
            cameraButton.isHidden = false
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
//        messageLabel.text = "Interruption ended"
        if lines.isEmpty {
             messageLabel.text = "Hold screen & move your iPhone..."
        }
    }
}

extension ViewController {
    func setupScene() {
        targetImage.isHidden = true
        cameraButton.isHidden = true
        sceneView.delegate = self
        sceneView.session = session
        loadingView.startAnimating()
        messageLabel.text = "Detecting the world..."
        clearButton.isHidden = true
        rulerImage.isHidden = true
        unitLabel.isHidden = true
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
        rulerImage.isHidden = false
        loadingView.isHidden = true
        
        if lines.isEmpty {
            messageLabel.text = "Hold screen & move your iPhone..."
        }
        loadingView.stopAnimating()
        if isMeasuring {
            unitLabel.isHidden = false
            if startValue == vectorZero {
                startValue = worldPosition
                currentLine = Line(sceneView: sceneView, startVector: startValue, unit: unit)
            }
            endValue = worldPosition
            currentLine?.update(to: endValue)
            messageLabel.text = currentLine?.distance(to: endValue) ?? "Calculating..."
            unitLabel.text = messageLabel.text
        }
    }
}

