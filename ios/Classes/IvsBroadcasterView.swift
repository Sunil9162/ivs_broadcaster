//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast
import AVFoundation
import Flutter

class IvsBroadcasterView: NSObject , FlutterPlatformView , FlutterStreamHandler , IVSBroadcastSession.Delegate,IVSCameraDelegate, AVCaptureVideoDataOutputSampleBufferDelegate  {
    
    
    //    ivs broadcatersession =>
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
        
        _methodChannel.setMethodCallHandler(onMethodCall)
        _eventChannel.setStreamHandler(self)
        
        
    }
    
    private var queue = DispatchQueue(label: "media-queue")
    private var captureSession: AVCaptureSession?
    
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            connection.videoOrientation = .portrait
            
            // Send the sample buffer to the IVS custom image source
            customImageSource?.onSampleBuffer(sampleBuffer)
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
    
    
    func onZoomCamera(value: Double) -> [String: Any] {
        //        guard let camera = attachedCamera as? IVSCamera else {
        //            // Handle the case where the camera is not available or not of type IVSCamera
        //            return ["min": NSNull(), "max": NSNull()]
        //        }
        //
        //        // Set the video zoom factor
        //        camera.setVideoZoomFactor(CGFloat(value))
        
        guard let captureSession = self.captureSession, captureSession.isRunning else { return ["min": 0 as Any, "max": 0 as Any]}
        do {
            try videoDevice?.lockForConfiguration()
        } catch {
            // Handle the error
            print("Failed to lock configuration: \(error)")
        }
        
        let zoom = max(1.0, min(value, self.videoDevice?.activeFormat.videoMaxZoomFactor ?? 0))
        self.videoDevice?.videoZoomFactor = zoom
        self.videoDevice?.unlockForConfiguration()
        // Retrieve the minimum and maximum zoom factors
        let minZoomFactor = self.videoDevice?.minAvailableVideoZoomFactor
        let maxZoomFactor = self.videoDevice?.maxAvailableVideoZoomFactor
        
        // Return the minimum and maximum zoom factors in a dictionary
        return ["min": minZoomFactor as Any, "max": maxZoomFactor as Any]
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
        case "zoomCamera":
            let args = call.arguments as? [String: Any]
            result( onZoomCamera(value:args?["zoom"] as? Double ?? 0.0))
        case "updateCameraLens":
            let args = call.arguments as? [String: Any]
            let data = updateCameraType(args?["lens"] as? String ?? "0")
            print("CamerUpdate: \(data)")
            result(data)
        case "mute":
            applyMute()
            result(true)
        case "changeCamera":
            let args = call.arguments as? [String: Any]
            let type = args?["type"] as? String
            changeCamera(type: type!)
            result(true)
        case "stopBroadcast":
            stopBroadCast()
            result(true)
                
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
    
    func changeCamera(type: String){
        let devices = IVSBroadcastSession.listAvailableDevices()
        if(type == "0"){
            for device in devices {
                if(device.type == .camera && device.friendlyName == "Front Camera"){
                    setCamera(device)
                }
            }
        }else{
            for device in devices {
                if(device.type == .camera && device.friendlyName == "Back Camera"){
                    setCamera(device)
                }
            }
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
        previewView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func applyMute() {
        let gain: Float = isMuted ? 0 : 1
        let muteAll = true
        broadcastSession?.awaitDeviceChanges { [weak self] in
            guard let `self` = self else { return }
            if (muteAll) {
                self.broadcastSession?.listAttachedDevices()
                    .compactMap { $0 as? IVSAudioDevice }
                    .forEach { $0.setGain(gain) }
            } else {
                (self.attachedMicrophone as? IVSAudioDevice)?.setGain(gain)
            }
        }
    }
    
    private var videoOutput: AVCaptureOutput?
    private var customImageSource: IVSCustomImageSource?
    private var videoDevice: AVCaptureDevice?
    
    private func setupSession(
        _ url: String,
        _ key: String,
        _ quality: String
    ) {
        
        do {
            self.streamKey = key
            self.rtmpsKey = url
            // Create the session with a preset config and camera/microphone combination.
            
            IVSBroadcastSession.applicationAudioSessionStrategy = .playAndRecord
            
            
            let config = try createBroadcastConfiguration(for: quality )
            let customSlot = IVSMixerSlotConfiguration()
            customSlot.size = config.video.size
            customSlot.position = CGPoint(x: 0, y: 0)
            customSlot.preferredAudioInput = .userAudio
            customSlot.preferredVideoInput = .userImage
            try customSlot.setName("custom-slot")
            
            config.mixer.slots = [customSlot]
            
            // Our AVCaptureSession will be managing the AVAudioSession independently
            IVSBroadcastSession.applicationAudioSessionStrategy = .noAction
            let broadcastSession = try IVSBroadcastSession(configuration: config,
                                                           descriptors: nil,
                                                           delegate: self)
            
            let customImageSource = broadcastSession.createImageSource(withName: "custom-image")
            broadcastSession.attach(customImageSource, toSlotWithName: "custom-slot")
            self.customImageSource = customImageSource
            //            broadcastSession.awaitDeviceChanges { [weak self] in
            //                let devices = broadcastSession.listAttachedDevices()
            //                let cameras = devices
            //                    .filter { $0.descriptor().type == .camera }
            //                    .compactMap { $0 as? IVSImageDevice }
            //
            //                self?.attachedCamera = cameras.first
            //                self?.attachedMicrophone = devices.first(where: { $0.descriptor().type == .microphone })
            //            }
            self.broadcastSession = broadcastSession
            startCamera()
        } catch {
            print("Unable to setup session")
        }
        
    }
    
    func updateCameraType(_ cameraType: String)->String{
        guard let captureSession = self.captureSession, captureSession.isRunning else { return "Session Not Running"}
        do {
            try videoDevice?.lockForConfiguration()
        } catch {
            
            print("Failed to lock configuration: \(error)")
            return "Failed to lock configuration: \(error)"
        }
        self.captureSession?.beginConfiguration()
        guard let currentCameraInput =  self.captureSession?.inputs.first as? AVCaptureDeviceInput else { return "Unable to get current Camera"}
        let _: AVCaptureDevice?
        do {
            if cameraType == "0" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInDualCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                }else {
                    return("Device is not compatible to set dual camera")
                }
            }
            if cameraType == "1" {
                if #available(iOS 10.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                }else{
                    return("Device is not compatible to set wideangle camera")
                }
            }
            if cameraType == "2" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTripleCamera,for: .video,position: .back)
                    try addInputDevice(videoDevice, currentCameraInput)
                } else {
                   return("Device is not compatible to set triple camera")
                }
               
            }
            if cameraType == "3" {
                if #available(iOS 10.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTelephotoCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set tele photo camera")
                }
            }
            if cameraType == "4" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set dual wide camera")
                }
            }
            if cameraType == "5" {
                if #available(iOS 11.1, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                }else{
                    return("Device is not compatible to set truedepth camera")
                }
            }
            if cameraType == "6" {
                if #available(iOS 13.0, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInUltraWideCamera,for: .video,position: .back)
                    try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set utra wide camera")
                }
            }
            if cameraType == "7" {
                if #available(iOS 15.4, *) {
                    let videoDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera,for: .video,position: .back)
                  try  addInputDevice(videoDevice, currentCameraInput)
                } else {
                    return("Device is not compatible to set lidardepthCamera")
                }
                
            }
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
        // Add the new input to the session
        if ((self.captureSession?.canAddInput(newCameraInput)) != nil) {
            self.captureSession?.removeInput(currentCameraInput)
            self.captureSession?.addInput(newCameraInput)
            self.videoDevice = device
        }
        self.captureSession?.commitConfiguration()
    }
    
    func startCamera(){
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        if
            let videoDevice = AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoInput)
        {
            self.videoDevice = videoDevice
            captureSession.addInput(videoInput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                self.videoOutput = videoOutput
            }
        }
        
        captureSession.commitConfiguration()
        self.captureSession = captureSession
        attachPreviewLayer(to: previewView)
        DispatchQueue.global().async {
            captureSession.startRunning()
        }
    }
    
    func attachPreviewLayer(to view: UIView) {
        guard let captureSession = self.captureSession else { return }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }
    
    
    private func setCamera(_ device: IVSDeviceDescriptor) {
        guard let broadcastSession = self.broadcastSession else { return }
        
        // either attach or exchange based on current state.
        if attachedCamera == nil {
            broadcastSession.attach(device, toSlotWithName: nil) { newDevice, _ in
                self.attachedCamera = newDevice
            }
        } else if let currentCamera = self.attachedCamera, currentCamera.descriptor().urn != device.urn {
            broadcastSession.exchangeOldDevice(currentCamera, withNewDevice: device) { newDevice, _ in
                self.attachedCamera = newDevice
            }
        }
    }
    
    func setMicrophone(_ device: IVSDeviceDescriptor) {
        guard let broadcastSession = self.broadcastSession else { return }
        
        // either attach or exchange based on current state.
        if attachedMicrophone == nil {
            broadcastSession.attach(device, toSlotWithName: nil) { newDevice, _ in
                self.attachedMicrophone = newDevice
            }
        } else if let currentMic = self.attachedMicrophone, currentMic.descriptor().urn != device.urn {
            broadcastSession.exchangeOldDevice(currentMic, withNewDevice: device) { newDevice, _ in
                self.attachedMicrophone = newDevice
            }
        }
    }
    
    private func refreshAttachedDevices() {
        guard let session = broadcastSession else { return }
        let attachedDevices = session.listAttachedDevices()
        let cameras = attachedDevices.filter { $0.descriptor().type == .camera }
        let microphones = attachedDevices.filter { $0.descriptor().type == .microphone }
        attachedCamera = cameras.first
        attachedMicrophone = microphones.first
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
}

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
