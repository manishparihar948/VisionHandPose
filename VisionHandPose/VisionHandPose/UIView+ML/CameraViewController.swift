//
//  ViewController.swift
//  VisionHandPose
//
//  Created by Manish Parihar on 29.09.24.
//

import UIKit
import AVFoundation
import Vision
// Add F53OSC for OSC communication
import OSCKit


class CameraViewController: UIViewController {
    
    private var cameraView: CameraView{ view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    // Add AVAudioPlayer property
    private var audioPlayer: AVAudioPlayer?
    
    // Track if the hand is currently detected
    private var isHandVisible = false
    
    // OSC Client instance
    private var oscClient = F53OSCClient()
    // private var oscClient = Endpoint.oscHandGesture // Future Scope
    private let oscHost =  "192.168.1.100"  // Target IP
    private let oscPort: UInt16 = 8000     // Target port
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize AVAudioPlayer
        setupAudioPlayer()
        
        // Setup OSC Client
        setupOSCClient()
        
        // This sample app detects one hand only.
        handPoseRequest.maximumHandCount = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                if self.cameraFeedSession == nil {
                    self.cameraView.previewLayer.videoGravity = .resizeAspectFill
                    try self.setupAVSession()
                    self.cameraView.previewLayer.session = self.cameraFeedSession
                }
                self.cameraFeedSession?.startRunning()
            } catch {
                AppError.display(error, inViewController: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    // Setup AVAudioPlayer
    private func setupAudioPlayer() {
        guard let soundURL = Bundle.main.url(forResource: "bird", withExtension: "wav") else {
            print("Sound file not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()  // Preload the sound
            //audioPlayer?.numberOfLoops = -1 // This makes the sound loop indefinitely
            
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    //  Function to play the sound
    private func playSound() {
        //audioPlayer?.stop() // Stop the sound if already playing
        audioPlayer?.currentTime = 0 // Reset the sound to the beginning
        audioPlayer?.play()
    }
    
    // Function to stop the sound
    private func stopSound() {
        audioPlayer?.stop()
    }
    
    
    // Setup the OSC Client
    func setupOSCClient() {
        oscClient.host = oscHost
        oscClient.port = oscPort
    }
    
    // Function to send points data over OSC
    func sendOSCMessage(_ points: [CGPoint]) {
        for (index, point) in points.enumerated() {
            // Create an OSC message for each point (finger joint)
            let oscMessage = F53OSCMessage(
                addressPattern: "/hand/point\(index)",  // Sends /hand/point0, /hand/point1, etc.
                arguments: [Float(point.x), Float(point.y)]  // Sends X and Y coordinates as floats
            )
            
            // Send the OSC message
            oscClient.send(oscMessage)
        }
    }
    
    func setupAVSession() throws {
        // Select a front-facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front-facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    //
    func processPoints(_ points: [CGPoint?]) {
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        var pointsConverted: [CGPoint] = []
        for point in points {
            if let point = point {
                pointsConverted.append(previewLayer.layerPointConverted(fromCaptureDevicePoint: point))
            }
        }
        
        // Check if hand points are detected
        // Hand Detection Logic
        if !pointsConverted.isEmpty {
            // Hand is detected
            if isHandVisible == false {
                // Hand was not visible before, now it's detected, play the sound
                playSound()
                isHandVisible = true // Update the state to reflect that the hand is now visible
            }
        } else {
            // No hand detected
            if isHandVisible == true  {
                // Hand was visible before, now it's removed, stop the sound
                stopSound()
                isHandVisible = false // Update the state to reflect that the hand is no longer visible
            }
        }
        
        // Send converted points over OSC
        sendOSCMessage(pointsConverted)
        
        // Show the points on the screen
        cameraView.showPoints(pointsConverted)
    }
}


extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        var thumbTip: CGPoint?
        var thumbIp: CGPoint?
        var thumbMp: CGPoint?
        var thumbCmc: CGPoint?
        var indexTip: CGPoint?
        var indexDip: CGPoint?
        var indexPip: CGPoint?
        var indexMcp: CGPoint?
        var middleTip: CGPoint?
        var middleDip: CGPoint?
        var middlePip: CGPoint?
        var middleMcp: CGPoint?
        var ringTip: CGPoint?
        var ringDip: CGPoint?
        var ringPip: CGPoint?
        var ringMcp: CGPoint?
        var littleTip: CGPoint?
        var littleDip: CGPoint?
        var littlePip: CGPoint?
        var littleMcp: CGPoint?
        var wrist: CGPoint?
        
        // First step to Create a Request Handler - which is VNImageRequestHandler
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            // Second Step - Perform VNDetectHumanHandPoseRequest
            // Third Step - Write a request to the handler
            try handler.perform([handPoseRequest])
            
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            print("Time: \(timeElapsed) s. FPS: \(1/timeElapsed)")
            
            // If above steps work well then we perform well then we will have Points Observations - In this case VNRecognizedPointsObservation returns
            
            // Continue only when a hand was detected in the frame.
            guard let observation = handPoseRequest.results?.first as? VNHumanHandPoseObservation else {
                cameraView.showPoints([])
                return
            }
            
            // Total - 21 points
            // TIP - Tip of thumb
            // IP - Interphalangeal joint
            // MP - Metacarpophalangeal joint
            // CMC - Carpometacarpal joint
            // Access the hand joints using VNHumanHandPoseObservation's jointName
            let thumbTipPoint = try observation.recognizedPoint(.thumbTip)
            let thumbIpPoint = try observation.recognizedPoint(.thumbIP)
            let thumbMpPoint = try observation.recognizedPoint(.thumbMP)
            let thumbCmcPoint = try observation.recognizedPoint(.thumbCMC)
            
            // TIP - Tip of the finger
            // DIP - Distal interphalangeal joint
            // PIP - Proximal interphalangeal joint
            // MCP - Metacarpophalangeal joint
            let indexTipPoint = try observation.recognizedPoint(.indexTip)
            let indexDipPoint = try observation.recognizedPoint(.indexDIP)
            let indexPipPoint = try observation.recognizedPoint(.indexPIP)
            let indexMcpPoint = try observation.recognizedPoint(.indexMCP)
            
            let middleTipPoint = try observation.recognizedPoint(.middleTip)
            let middleDipPoint = try observation.recognizedPoint(.middleDIP)
            let middlePipPoint = try observation.recognizedPoint(.middlePIP)
            let middleMcpPoint = try observation.recognizedPoint(.middleMCP)
            
            let ringTipPoint = try observation.recognizedPoint(.ringTip)
            let ringDipPoint = try observation.recognizedPoint(.ringDIP)
            let ringPipPoint = try observation.recognizedPoint(.ringPIP)
            let ringMcpPoint = try observation.recognizedPoint(.ringMCP)
            
            let littleTipPoint = try observation.recognizedPoint(.littleTip)
            let littleDipPoint = try observation.recognizedPoint(.littleDIP)
            let littlePipPoint = try observation.recognizedPoint(.littlePIP)
            let littleMcpPoint = try observation.recognizedPoint(.littleMCP)
            
            let wristPoint = try observation.recognizedPoint(.wrist)
            
            // Confidence threshold to filter low confidence points.
            let confidenceThreshold: Float = 0.3
            guard thumbTipPoint.confidence > confidenceThreshold &&
                    thumbIpPoint.confidence > confidenceThreshold &&
                    thumbMpPoint.confidence > confidenceThreshold &&
                    thumbCmcPoint.confidence > confidenceThreshold &&
                    indexTipPoint.confidence > confidenceThreshold &&
                    indexDipPoint.confidence > confidenceThreshold &&
                    indexPipPoint.confidence > confidenceThreshold &&
                    indexMcpPoint.confidence > confidenceThreshold &&
                    middleTipPoint.confidence > confidenceThreshold &&
                    middleDipPoint.confidence > confidenceThreshold &&
                    middlePipPoint.confidence > confidenceThreshold &&
                    middleMcpPoint.confidence > confidenceThreshold &&
                    ringTipPoint.confidence > confidenceThreshold &&
                    ringDipPoint.confidence > confidenceThreshold &&
                    ringPipPoint.confidence > confidenceThreshold &&
                    ringMcpPoint.confidence > confidenceThreshold &&
                    littleTipPoint.confidence > confidenceThreshold &&
                    littleDipPoint.confidence > confidenceThreshold &&
                    littlePipPoint.confidence > confidenceThreshold &&
                    littleMcpPoint.confidence > confidenceThreshold &&
                    wristPoint.confidence > confidenceThreshold else {
                cameraView.showPoints([])
                return
            }
            
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            thumbIp = CGPoint(x: thumbIpPoint.location.x, y: 1 - thumbIpPoint.location.y)
            thumbMp = CGPoint(x: thumbMpPoint.location.x, y: 1 - thumbMpPoint.location.y)
            thumbCmc = CGPoint(x: thumbCmcPoint.location.x, y: 1 - thumbCmcPoint.location.y)
            indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
            indexDip = CGPoint(x: indexDipPoint.location.x, y: 1 - indexDipPoint.location.y)
            indexPip = CGPoint(x: indexPipPoint.location.x, y: 1 - indexPipPoint.location.y)
            indexMcp = CGPoint(x: indexMcpPoint.location.x, y: 1 - indexMcpPoint.location.y)
            middleTip = CGPoint(x: middleTipPoint.location.x, y: 1 - middleTipPoint.location.y)
            middleDip = CGPoint(x: middleDipPoint.location.x, y: 1 - middleDipPoint.location.y)
            middlePip = CGPoint(x: middlePipPoint.location.x, y: 1 - middlePipPoint.location.y)
            middleMcp = CGPoint(x: middleMcpPoint.location.x, y: 1 - middleMcpPoint.location.y)
            ringTip = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
            ringDip = CGPoint(x: ringDipPoint.location.x, y: 1 - ringDipPoint.location.y)
            ringPip = CGPoint(x: ringPipPoint.location.x, y: 1 - ringPipPoint.location.y)
            ringMcp = CGPoint(x: ringMcpPoint.location.x, y: 1 - ringMcpPoint.location.y)
            littleTip = CGPoint(x: littleTipPoint.location.x, y: 1 - littleTipPoint.location.y)
            littleDip = CGPoint(x: littleDipPoint.location.x, y: 1 - littleDipPoint.location.y)
            littlePip = CGPoint(x: littlePipPoint.location.x, y: 1 - littlePipPoint.location.y)
            littleMcp = CGPoint(x: littleMcpPoint.location.x, y: 1 - littleMcpPoint.location.y)
            wrist = CGPoint(x: wristPoint.location.x, y: 1 - wristPoint.location.y)
            
        } catch {
            cameraFeedSession?.stopRunning()
            AppError.display(error, inViewController: self)
        }
        
        DispatchQueue.main.sync {
            self.processPoints([thumbTip, thumbIp, thumbMp, thumbCmc,
                                indexTip, indexDip, indexPip, indexMcp,
                                middleTip, middleDip, middlePip, middleMcp,
                                ringTip, ringDip, ringPip, ringMcp,
                                littleTip, littleDip, littlePip, littleMcp,
                                wrist])
        }
    }
}



// MARK: - CGPoint helpers

extension CGPoint {
    
    static func midPoint(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
    }
    
    func distance(from point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}

