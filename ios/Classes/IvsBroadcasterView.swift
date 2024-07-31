//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast
import AVFoundation
import Flutter

class IvsBroadcasterView: NSObject , FlutterPlatformView , FlutterStreamHandler , IVSBroadcastSession.Delegate,IVSCameraDelegate  {
   
    
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
//    private func setFocusPoint(_ point: CGPoint) {
//          guard let camera = attachedCamera as? IVSCamera else { return }
//          camera.setFocusPointOfInterest(point)
//          camera.setFocusMode(.continuousAutoFocus)
//      }
//    private func disableAutoFocus() {
//        guard let camera = attachedCamera as? IVSCamera else { return }
//        camera.setFocusMode(.locked)
//    }

    func onZoomCamera(value: Double) -> [String: Any] {
        guard let camera = attachedCamera as? IVSCamera else {
            // Handle the case where the camera is not available or not of type IVSCamera
            return ["min": NSNull(), "max": NSNull()]
        }

        // Set the video zoom factor
        camera.setVideoZoomFactor(CGFloat(value))

        // Retrieve the minimum and maximum zoom factors
        let minZoomFactor = camera.minAvailableVideoZoomFactor
        let maxZoomFactor = camera.maxAvailableVideoZoomFactor

        // Return the minimum and maximum zoom factors in a dictionary
        return ["min": minZoomFactor, "max": maxZoomFactor]
    }

    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
            switch(call.method){
            case "startPreview":
                let args = call.arguments as? [String: Any]
                let url = args?["imgset"] as? String
                let key = args?["streamKey"] as? String
                setupSession(url!, key!)
                result(true)
            case "startBroadcast":
                startBroadcast()
                result(true)
            case "zoomCamera":
                let args = call.arguments as? [String: Any]
               
                result( onZoomCamera(value:args?["zoom"] as? Double ?? 0.0))
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

    
    private func setupSession(
        _ url: String,
        _ key: String
    ) {
        
        do {
            self.streamKey = key
            self.rtmpsKey = url
            // Create the session with a preset config and camera/microphone combination.
            
            IVSBroadcastSession.applicationAudioSessionStrategy = .playAndRecord
            let broadcastSession = try IVSBroadcastSession(configuration: IVSPresets.configurations().standardLandscape(),
                                                           descriptors: IVSPresets.devices().backCamera(),
                                                           delegate: self)
            
            broadcastSession.awaitDeviceChanges { [weak self] in
                let devices = broadcastSession.listAttachedDevices()
                let cameras = devices
                    .filter { $0.descriptor().type == .camera }
                    .compactMap { $0 as? IVSImageDevice }

                self?.attachedCamera = cameras.first
                self?.attachedMicrophone = devices.first(where: { $0.descriptor().type == .microphone })
            }
            self.broadcastSession = broadcastSession
        } catch {
            print("Unable to setup session")
        }
        
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
            case .connecting:
                data = ["state":"CONNECTING"]
            case .connected:
                data = ["state":"CONNECTED"]
            case .disconnected:
                data = ["state":"DISCONNECTED"]
            case .error:
                data = ["state":"ERROR"]
            @unknown default:
                data = ["state":"INVALID"]
            }
            self._eventSink!(data)
        }
    }

    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        DispatchQueue.main.async {
        }
    }

    func broadcastSession(_ session: IVSBroadcastSession, transmissionStatisticsChanged statiscs: IVSTransmissionStatistics) {
        var data = [String:Any]()
        var quality = statiscs.broadcastQuality.rawValue
        var health = statiscs.networkHealth.rawValue
        data = ["quality":quality,"network":health]
        self._eventSink?(data) 
    }
}

extension IvsBroadcasterView: IVSMicrophoneDelegate {
    func underlyingInputSourceChanged(for microphone: IVSMicrophone, toInputSource inputSource: IVSDeviceDescriptor?) {
        self.attachedMicrophone = microphone
    }
}
