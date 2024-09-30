# VisionHandPose 
**Description**
Setting up the camera for accessing the Hand Gesture by using Vision framework. 
Basically the Vision framework combines machine learning technologies and Swift's concurrency features to perform computer vision tasks in your app. Use the Vision framework to analyze images for a variety of purposes: Tracking human body poses. 

**Requirements**
Mac OS - 10.15 Catalina
Xcode Version - 16
IOS Version - 17.0 (Deployment Target)

**Permission**
Camera - Provided camera access.

**Testing Device**
Device - iPhone 12 Pro (Physical Device)

**End User Permissions**
Privacy Access - Camera usage description

**Dependency**
1. Add Vision Framework and AVFoundation Framework
2. Install OSCKit and F53OSC  
3. Only workin on physical/real device - iPhone and iPad

### Gesture Recognition : Hand Gesture recognized by Vision Framework 
Access the hand gesture by creating a request handing using - VNImageRequestHandler. And the VNImageRequestHandler detects VNDetectHumanHandPoseRequest.
Next step to provide the request to the handler via a call to performRequests. Once its complete successfully. It contains VNHumanHandPoseObservation and this observations contains locations for all the found landmarks for the hand. And this class are given in new classes meant to represent 2D point.
There is total 21 landmarks points.

![image](https://github.com/user-attachments/assets/9993d16f-e2c3-4c2b-93ba-45d62e7c44de)


### OSC Communication ###
**Note -:** OSC library for Objective-C but its not available for Swift / SwiftUI.
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

 ## Basic UI ## 
 Only camera is showing in  UI once you grant permission to the Camera view inside the app.

 ## Pure Data Integration (Optional) ## 
 Its directly linked with the OSC - We have install the OSCKit and F53OSC. 
 We need to ensure that Pure Data can listen and process the OSC message sent from the app.
 In our exiting code we have setup F53OSCClient to send hand gesture data (finger joints position) as OSC messages.
 To Test the Pure Data setup - Run the PureData patch and ensure its actively listening on port 8000
 Run the ios app with hand gesture data being captured.
 Monitor the Pure Data console to verify that the incoming OSC messsages are being correcly received and processed.

 ## App WorkFlow ## 
 1. User clicks on app icon and it will launch an application
 2. Camera Permission required by user
 3. Once its launch camera and when you place hand in front of the front camera, its start detecting and create a pattern by dashed line
 4. If the hand placed it will play sound of bird audio and when you move hand from the front of the camera its stop playing audio.
    (At this moment Hand Pose/Gesture Image is not fetching audio for pure data - its due to framework dependency which is not available appropriately.
    But code for OSC and PureData logic is available in the code repository)
5. Network Management and Endpoint is also available in the code repository.
    
    

** How the gesture data is sent via OSC.**
Hand Gesture data is sentt via OSC:
1. First we had setup F53OSCClient to connect to the target IP and port.
2. Each finger joint position, show as a CGPoint
3. Then the CGPoint sent to OSC message in the sendOSCMessage method.
4. And this message contains an address pattern like /hand/point0 and /hand/point1 etc.
5. And In processPoint method, the points are converted to screen coordinates, then sent through OSC.
6. At same time its displayed on the camera .

 **Limitations**
1. Not working on ios simulators because of the camera access.
2. Also its available for front camera as of now. (which we can improve in future)
3. Cannot test the PureData we dont have access the the framework or library of OSC directly

**Future Scope**
1. Integrate CI/CD
2. Network Management
3. Fastlane for build version
4. XCTestCase for UnitTest, UITest and Integration Test
5. Crashalytics - Analytic for Tracking Enduser activity
