//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast
import AVFoundation
import Flutter

class IvsBroadcasterView: NSObject , FlutterPlatformView , FlutterStreamHandler , IVSBroadcastSession.Delegate, IVSCameraDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate  {
    
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }
    
    func view() -> UIView {
        return previewView
    }
    
    private var _methodChannel: FlutterMethodChannel
    private var _eventChannel: FlutterEventChannel
    var _eventSink: FlutterEventSink?
    private var previewView: UIView
    private var broadcastSession: IVSBroadcastSession?
    
    private var streamKey : String?
    private var rtmpsKey : String?
    
    
    init(_ frame: CGRect,
         viewId: Int64,
         args: Any?,
         messenger: FlutterBinaryMessenger
    ) {
        _methodChannel = FlutterMethodChannel(name: "ivs_broadcaster"
                                              , binaryMessenger: messenger);
        _eventChannel = FlutterEventChannel(name: "ivs_broadcaster_event", binaryMessenger: messenger)
        previewView =  UIView(frame: frame)
        super.init();
        NotificationCenter.default.addObserver(self, selector: #selector(handleOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        _methodChannel.setMethodCallHandler(onMethodCall)
        _eventChannel.setStreamHandler(self)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(setFocusPoint(_:)))
        previewView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private var queue = DispatchQueue(label: "media-queue")
    private var captureSession: AVCaptureSession?
    
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            if #available(iOS 13.0, *) {
                connection.preferredVideoStabilizationMode = .cinematicExtended
            }
            customImageSource?.onSampleBuffer(sampleBuffer)
        } else if output == audioOutput {
            customAudioSource?.onSampleBuffer(sampleBuffer)
        }
    }
    
    
    func checkOrGetPermission(for mediaType: AVMediaType, _ result: @escaping (Bool) -> Void) {
        func mainThreadResult(_ success: Bool) {
            DispatchQueue.main.async { result(success) }
        }
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: mainThreadResult(true)
        case .notDetermined: AVCaptureDevice.requestAccess(for: mediaType) { mainThreadResult($0) }
        case .denied, .restricted: mainThreadResult(false)
        @unknown default: mainThreadResult(false)
        }
    }
    
    func attachCameraPreview(container: UIView, preview: UIView) {
        // Clear current view, and then attach the new view.
        container.subviews.forEach { $0.removeFromSuperview() }
        preview.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.topAnchor.constraint(equalTo: container.topAnchor, constant: 0),
            preview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0),
            preview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 0),
            preview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
        ])
    }
    
    
    func onZoomCamera(value: Double)  {
        guard let captureSession = self.captureSession, captureSession.isRunning else { return  }
        do {
            try videoDevice?.lockForConfiguration()
        } catch {
            print("Failed to lock configuration: \(error)")
            self.videoDevice?.unlockForConfiguration()
            return
        }
        let zoom = max(1.0, min(value, self.videoDevice?.activeFormat.videoMaxZoomFactor ?? 0))
        self.videoDevice?.videoZoomFactor = zoom
        self.videoDevice?.unlockForConfiguration()
    }
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method){
        case "startPreview":
            let args = call.arguments as? [String: Any]
            let url = args?["imgset"] as? String
            let key = args?["streamKey"] as? String
            let quality = args?["quality"] as? String
            setupSession(url!, key!,quality!)
            result(true)
        case "startBroadcast":
            startBroadcast()
            result(true)
        case "getCameraZoomFactor":
            result(getCameraZoomFactor())
        case "zoomCamera":
            let args = call.arguments as? [String: Any]
            onZoomCamera(value:args?["zoom"] as? Double ?? 0.0)
            result("Success")
        case "updateCameraLens":
            let args = call.arguments as? [String: Any]
            let data = updateCameraType(args?["lens"] as? String ?? "0")
            result(data)
        case "mute":
            applyMute()
            result(true)
        case "changeCamera":
            let args = call.arguments as? [String: Any]
            let type = args?["type"] as? String
            changeCamera(type: type!)
            result(true)
        case "getAvailableCameraLens":
            if #available(iOS 13.0, *) {
                result(getAvailableCameraLens())
            } else {
                result([])
            }
        case "stopBroadcast":
            stopBroadCast()
            result(true)
        case "setFocusMode":
            let args = call.arguments as? [String: Any]
            let type = args?["type"] as? String
            result(setFocusMode(type!))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Start Broadcasting with rtmps and stream key
    func startBroadcast(){
        do  {
            try self.broadcastSession?.start(with: URL(string: rtmpsKey!)!, streamKey: streamKey!)
        } catch{
            print("Unable to Start Streaming")
        }
    }
    
    func normalizePoint(_ point: CGPoint, size: CGSize) -> CGPoint {
        return CGPoint(x: point.x / size.width, y:  point.y / size.height)
    }
    
    @objc func setFocusPoint(_ gestureRecognizer: UITapGestureRecognizer){
        guard let videoDevice = videoDevice else {
            print("No Video Device Available")
            return
        }
        if videoDevice.focusMode == .continuousAutoFocus {
            print("Camera is On \(videoDevice.focusMode) Set it to autoFocus")
            return
        }
        let tapPoint = gestureRecognizer.location(in: previewView)
         
        let originalPoint = CGPoint(x: tapPoint.x, y: tapPoint.y)
        let size = CGSize(width:self.previewView.frame.width, height: self.previewView.frame.height) // Replace with your actual size
        let normalizedPoint = normalizePoint(originalPoint, size: size)
        do {
            try videoDevice.lockForConfiguration()
            
            // Convert the focus point to a CGPoint
            // Check if the device supports focus point selection
            if videoDevice.isFocusPointOfInterestSupported {
                // Set the focus point
                videoDevice.focusPointOfInterest = normalizedPoint
                videoDevice.focusMode = .autoFocus
            } else {
                print("Focus point selection not supported")
                return
            }
            videoDevice.unlockForConfiguration()
            let data =  ["foucsPoint": "\(tapPoint.x)_\(tapPoint.y)"]
            self._eventSink!(data)
            
        } catch {
            print("Error setting focus point: \(error)")
            return
        }
    }
    
    func setFocusMode(_ type: String) -> Bool {
        guard let videoDevice = videoDevice else { return false }
        
        let focusMode: AVCaptureDevice.FocusMode
        switch type {
        case "0":
            focusMode = .locked
        case "1":
            focusMode = .autoFocus
        case "2":
            focusMode = .continuousAutoFocus
        default:
            print("Invalid type")
            return false
        }
        
        if videoDevice.isFocusModeSupported(focusMode) {
            do {
                try videoDevice.lockForConfiguration()
                videoDevice.focusMode = focusMode
                videoDevice.unlockForConfiguration()
                return true
            } catch {
                print("Error setting focus mode: \(error)")
                return false
            }
        } else {
            print("Focus mode not supported")
            return false
        }
    }
   
    
    func  getCameraZoomFactor() ->  [String: Any]{
        var max = 0
        var min = 0
        max = Int(self.videoDevice?.maxAvailableVideoZoomFactor ?? 0)
        min = Int(self.videoDevice?.minAvailableVideoZoomFactor ?? 0)
        return ["min": min, "max": max]
    }
    
    func changeCamera(type: String){
        if let cameraPosition = CameraPosition(string: type) {
            switch cameraPosition {
            case .front:
                updateToFrontCamera()
            case .back:
                updateToBackCamera()
            }
        } else {
            print("Invalid camera position string.")
        }
    }
    
    
    
    func updateToBackCamera(){
        do {
            guard let captureSession = self.captureSession, captureSession.isRunning else { return}
            self.captureSession?.beginConfiguration()
            guard let currentCameraInput =  self.captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
            let _: AVCaptureDevice?
            let videoDevice = AVCaptureDevice.default(for: .video)
            try addInputDevice(videoDevice, currentCameraInput)
            self.captureSession?.commitConfiguration()
            
        } catch {
            print("Failed to lock configuration: \(error)")
            return
        }
    }
    
    func updateToFrontCamera(){
        do {
            guard let captureSession = self.captureSession, captureSession.isRunning else { return}
           
            self.captureSession?.beginConfiguration()
            guard let currentCameraInput =  self.captureSession?.inputs.first as? AVCaptureDeviceInput else { return }
            let _: AVCaptureDevice?
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .front)
            try addInputDevice(videoDevice, currentCameraInput)
            self.captureSession?.commitConfiguration()
            
        } catch {
            print("Failed to lock configuration: \(error)")
            return
        }
    }
    
    private var isMuted = false {
        didSet {
            applyMute()
        }
    }
    
    //    provide camera to preview (attached camera)
    private var attachedCamera: IVSDevice? {
        didSet {
            if let preview = try? (attachedCamera as? IVSImageDevice)?.previewView(with: .fill) {
                
                attachCameraPreview(container: previewView, preview: preview)
            } else {
                previewView.subviews.forEach { $0.removeFromSuperview() }
            }
        }
    }
    
    
    private var attachedMicrophone: IVSDevice? {
        didSet {
            applyMute()
        }
    }
    
    
    func stopBroadCast() {
        broadcastSession?.stop()
        broadcastSession = nil
        if self._eventSink != nil {
            self._eventSink?(["state": "DISCONNECTED"]);
        }
        self.captureSession?.stopRunning()
        previewView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func applyMute() {
        guard let currentAudioInput = self.captureSession?.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.position == .unspecified }) as? AVCaptureDeviceInput else {
            print("Unable to get current Audio Input")
            return
        }
        if isMuted {
            self.captureSession?.addInput(currentAudioInput)
        }else{
            self.captureSession?.removeInput(currentAudioInput)
        }
    }
    
     
    
    private var videoOutput: AVCaptureOutput?
    private var audioOutput: AVCaptureOutput?
    private var customImageSource: IVSCustomImageSource?
    private var customAudioSource: IVSCustomAudioSource?
    private var videoDevice: AVCaptureDevice?
   
    private func setupSession(
        _ url: String,
        _ key: String,
        _ quality: String
    ) {
        
        do {
            self.streamKey = key
            self.rtmpsKey = url
            IVSBroadcastSession.applicationAudioSessionStrategy = .playAndRecord
            let config = try createBroadcastConfiguration(for: quality )
            let customSlot = IVSMixerSlotConfiguration()
            customSlot.size = config.video.size
            customSlot.position = CGPoint(x: 0, y: 0)
            customSlot.preferredAudioInput = .userAudio
            customSlot.preferredVideoInput = .userImage
            try customSlot.setName("custom-slot")
            config.mixer.slots = [customSlot]
            IVSBroadcastSession.applicationAudioSessionStrategy = .noAction
            let broadcastSession = try IVSBroadcastSession(configuration: config,
                                                           descriptors: nil,
                                                           delegate: self)
            let customAudioSource = broadcastSession.createAudioSource(withName: "custom-audio")
            broadcastSession.attach(customAudioSource, toSlotWithName: "custom-slot")
            self.customAudioSource = customAudioSource
            let customImageSource = broadcastSession.createImageSource(withName: "custom-image")
            broadcastSession.attach(customImageSource, toSlotWithName: "custom-slot")
            self.customImageSource = customImageSource
            self.broadcastSession = broadcastSession
            attachCameraPreview(container: previewView, preview: try customImageSource.previewView(with: .fill))
            startSession()
        } catch {
            print("Unable to setup session")
        }
    }
    
    @available(iOS 13.0, *)
    func getAvailableCameraLens()->Array<Int>{
        var lenses = [Int]()
        lenses.append(8)
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [
            .builtInWideAngleCamera,
            .builtInDualCamera,
            .builtInTelephotoCamera,
            .builtInTripleCamera,
            .builtInTrueDepthCamera,
            .builtInUltraWideCamera,
        ], mediaType: .video, position: .unspecified)
            for device in discoverySession.devices {
                switch device.deviceType {
                case .builtInWideAngleCamera:
                    lenses.append(1)
                    print("Device has a built-in wide-angle camera")
                case .builtInDualCamera:
                    lenses.append(0)
                    print("Device has a built-in dual camera")
                case .builtInTripleCamera:
                    lenses.append(2)
                    print("Device has a built-in triple camera")
                case .builtInTelephotoCamera:
                    lenses.append(3)
                    print("Device has a built-in telephoto camera")
                case .builtInTrueDepthCamera:
                    lenses.append(5)
                    print("Device has a built-in TrueDepth camera")
                case .builtInUltraWideCamera:
                    lenses.append(6)
                    print("Device has a built-in UltraWide camera")
                default: 
                    print("Device has an unknown camera type")
                }
            }
        lenses = Array(Set(lenses))
        return lenses
    }
    
    func updateCameraType(_ cameraType: String)->String{
        guard let captureSession = self.captureSession, captureSession.isRunning else { return "Session Not Running"}
      
        self.captureSession?.beginConfiguration()
        guard let currentCameraInput = self.captureSession?.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.position != .unspecified }) as? AVCaptureDeviceInput else {
            print("Unable to get current Audio Input")
            return ""
        }
        
        do {
            if cameraType == "0" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInDualCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                }else {
                    return("Device is not compatible to set dual camera")
                }
            }else
            if cameraType == "1" {
                if #available(iOS 10.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                }else{
                    return("Device is not compatible to set wideangle camera")
                }
            }else
            if cameraType == "2" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTripleCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set triple camera")
                }
                
            }else
            if cameraType == "3" {
                if #available(iOS 10.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTelephotoCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set tele photo camera")
                }
            }else
            if cameraType == "4" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set dual wide camera")
                }
            }else
            if cameraType == "5" {
                if #available(iOS 11.1, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                }else{
                    return("Device is not compatible to set truedepth camera")
                }
            }else
            if cameraType == "6" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set utra wide camera")
                }
            }else
            if cameraType == "7" {
                if #available(iOS 15.4, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set lidardepthCamera")
                }
                
            }else
            if cameraType == "8" {
                let videoDevice = AVCaptureDevice.default(for: .video)
                try addInputDevice(videoDevice, currentCameraInput)
            }
            return "Configuration Updated"
            
        } catch {
            return "Device is not compatible"
        }
    }
    
    enum CameraInputError: Error {
        case invalidDevice
    }
    
    func addInputDevice(_ device: AVCaptureDevice?,_ currentCameraInput: AVCaptureDeviceInput) throws {
        
        guard let validDevice = device else {
            self.captureSession?.commitConfiguration()
            throw CameraInputError.invalidDevice
        }
        // Create a new input with the new camera
        let newCameraInput = try AVCaptureDeviceInput(device: validDevice)
        self.captureSession?.removeInput(currentCameraInput)
        if self.captureSession?.canAddInput(currentCameraInput) ?? false {
            self.captureSession?.addInput(newCameraInput)
        } else {
            self.captureSession?.addInput(currentCameraInput)
        }
        self.videoDevice = device
        self.captureSession?.commitConfiguration()
    }
    
    func startSession(){
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        if
            let videoDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoInput)
        {
            self.videoDevice = videoDevice
            captureSession.addInput(videoInput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            if #available(iOS 13.0, *) {
                videoOutput.connections.first?.preferredVideoStabilizationMode = .cinematic
            }
          
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
                self.videoOutput?.connections.first?.videoOrientation = .landscapeRight
                self.videoOutput?.connections.first?.videoPreviewLayer?.videoGravity = .resizeAspectFill
                if #available(iOS 13.0, *) {
                    self.videoOutput?.connections.first?.preferredVideoStabilizationMode = .cinematicExtended
                }
            }
        }
        if
            let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            captureSession.canAddInput(audioInput)
        {
            captureSession.addInput(audioInput)
            
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: queue)
            if captureSession.canAddOutput(audioOutput) {
                captureSession.addOutput(audioOutput)
                self.audioOutput = audioOutput
            }
        }
        captureSession.commitConfiguration()
        self.captureSession = captureSession
        DispatchQueue.global().async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async {
                let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
            }
        }
    }
   
    
    func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        print("IVSBroadcastSession state did change to \(state.rawValue)")
        DispatchQueue.main.async {
            var data = [String: String]()
            switch state {
            case .invalid:
                data = ["state": "INVALID"]
                self._eventSink!(data)
            case .connecting:
                data = ["state":"CONNECTING"]
                self._eventSink!(data)
            case .connected:
                data = ["state":"CONNECTED"]
                self._eventSink!(data)
            case .disconnected:
                data = ["state":"DISCONNECTED"]
                self._eventSink!(data)
            case .error:
                data = ["state":"ERROR"]
                self._eventSink!(data)
            @unknown default:
                data = ["state":"INVALID"]
                self._eventSink!(data)
            }
            
        }
    }
    
    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        DispatchQueue.main.async {
        }
    }
    
    func broadcastSession(_ session: IVSBroadcastSession, transmissionStatisticsChanged statiscs: IVSTransmissionStatistics) {
        var data = [String:Any]()
        let quality = statiscs.broadcastQuality.rawValue
        let health = statiscs.networkHealth.rawValue
        data = ["quality":quality,"network":health]
        self._eventSink?(data)
    }
     
   
    @objc func handleOrientationChange() {
//        setVideoOrientation() // Handle orientation changes
    }
    
    func setVideoOrientation() {
        guard let connection = videoOutput?.connections.first else { return }
        self.captureSession?.beginConfiguration()
        
         
        self.captureSession?.commitConfiguration()
    }
    
    
    deinit {
        // Remove observer when the view controller is deallocated
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

 

// Store the last known orientation
var lastKnownOrientation: AVCaptureVideoOrientation?


extension IvsBroadcasterView: IVSMicrophoneDelegate {
    func underlyingInputSourceChanged(for microphone: IVSMicrophone, toInputSource inputSource: IVSDeviceDescriptor?) {
        self.attachedMicrophone = microphone
    }
    //    Create Broadcast Configuration that will set the configuration according to Quality
    func createBroadcastConfiguration(for resolution: String) throws -> IVSBroadcastConfiguration {
        let config = IVSBroadcastConfiguration()
        
        switch resolution {
        case "360":
            try config.video.setSize(CGSize(width: 640, height: 360))
            try config.video.setMaxBitrate(1000000) // 1 Mbps
            try config.video.setMinBitrate(500000) // 500 kbps
            try config.video.setInitialBitrate(800000) // 800 kbps
            try config.video.setTargetFramerate(30)
            try config.video.setKeyframeInterval(2)
            
        case "1080":
            try config.video.setSize(CGSize(width: 1920, height: 1080))
            try config.video.setMaxBitrate(6000000) // 6 Mbps
            try config.video.setMinBitrate(4000000) // 4 Mbps
            try config.video.setInitialBitrate(5000000) // 5 Mbps
            try config.video.setTargetFramerate(30)
            try config.video.setKeyframeInterval(2)
            
        case "720":
            try config.video.setSize(CGSize(width: 1280, height: 720))
            try config.video.setMaxBitrate(3500000) // 3.5 Mbps
            try config.video.setMinBitrate(1500000) // 1.5 Mbps
            try config.video.setInitialBitrate(2500000) // 2.5 Mbps
            try config.video.setTargetFramerate(30)
            try config.video.setKeyframeInterval(2)
            
        default:
            try config.video.setSize(CGSize(width: 1280, height: 720))
            try config.video.setMaxBitrate(3500000) // 3.5 Mbps
            try config.video.setMinBitrate(1500000) // 1.5 Mbps
            try config.video.setInitialBitrate(2500000) // 2.5 Mbps
            try config.video.setTargetFramerate(30)
            try config.video.setKeyframeInterval(2)
        }
        
        // Set audio bitrate
        try config.audio.setBitrate(128000) // 128 kbps
        
        return config
    }
}
