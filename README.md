# VisionHandPose 
**Description**
Setting up the camera for accessing the Hand Gesture by using Vision framework. 
Basically the Vision framework combines machine learning technologies and Swift's concurrency features to perform computer vision tasks in your app. Use the Vision framework to analyze images for a variety of purposes: Tracking human body poses. 

**Requirements**
Xcode Version - 16
IOS Version - 17.0 (Deployment Target)

**Permission**
Camera - Provided camera access

### Gesture Recognition : 

**Note -:** OSC library for Objective-C.


**Explanation:**
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
