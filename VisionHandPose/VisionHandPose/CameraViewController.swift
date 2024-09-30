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
// import F53OSC


class CameraViewController: UIViewController {

    private var cameraView: CameraView{ view as! CameraView }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    
    // Add AVAudioPlayer property
    private var audioPlayer: AVAudioPlayer?
    
   
    /*
    // OSC Client instance
    private var oscClient = F53OSCClient()
    private let oscHost = "192.168.1.100"  // Target IP
    private let oscPort: UInt16 = 8000     // Target port
     */

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize AVAudioPlayer
        setupAudioPlayer()
        
        // Setup OSC Client
        // setupOSCClient()

        // This sample app detects one hand only.
        handPoseRequest.maximumHandCount = 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        /*
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
         */
        
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
        guard let soundURL = Bundle.main.url(forResource: "mysound", withExtension: "mp3") else {
                    print("Sound file not found")
                    return
                }

                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.prepareToPlay()  // Preload the sound
                } catch {
                    print("Error initializing audio player: \(error.localizedDescription)")
                }
    }
    
    //  Function to play the sound
    private func playSound() {
        audioPlayer?.stop() // Stop the sound if already playing
        audioPlayer?.play()
    }
    
    /*
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
                     addressPattern: "/hand/point\(index)",
                     arguments: [Float(point.x), Float(point.y)]
                 )
                 
                 // Send the OSC message
                 oscClient.send(oscMessage)
             }
    }
     */

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
        
        // Play sound when hand is detected
                if !pointsConverted.isEmpty {
                    playSound()  // Play sound if hand points are detected
                }
        
        /*
        // Send converted points over OSC
        sendOSCMessage(pointsConverted)
         */
        
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

        // First step to Create a Request Handler - which is ImageRequestHandler
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



/**
 
 Explanation:
 OSC Client Setup (setupOSCClient):

 Here, we set up the F53OSCClient instance. The IP and port are set to the target OSC receiver (you mentioned using IP 192.168.1.100 and port 8000).
 Sending OSC Messages (sendOSCMessage):

 In sendOSCMessage, each CGPoint (representing a finger joint position) is sent as an OSC message. Each OSC message contains an address pattern (e.g., /hand/point0) and arguments (the X and Y positions of the joint).
 For each point, a message like /hand/point0, /hand/point1, etc., is sent.
 Modifying processPoints:

 In processPoints, once points are processed and converted to UIKit coordinates, we send these points via OSC by calling sendOSCMessage.
 The gesture data is still shown on the camera preview using cameraView.showPoints(pointsConverted).
 Testing:
 You can test this setup by running the app and monitoring the OSC messages using a tool like Pure Data or any other OSC listener on IP 192.168.1.100 and port 8000.
 
 */
