//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast
import AVFoundation
import Flutter

class OldIvsBroadcasterView: NSObject , FlutterPlatformView, IVSBroadcastSession.Delegate , FlutterStreamHandler{
    func broadcastSession(_ session: IVSBroadcastSession, didChange state: IVSBroadcastSession.State) {
        DispatchQueue.main.async {
                    switch state {
                    case .invalid:
                        self._eventSender?("INVALID")
                    case .connecting:
                        self._eventSender?("CONNECTING")
                    case .connected:
                        self._eventSender?("CONNECTED")
                    case .disconnected:
                        self._eventSender?("DISCONNECTED")
                    case .error:
                        self._eventSender?("ERROR")
                    @unknown default:
                        self._eventSender?("INVALID")
                    }
                }
    }
    
    func broadcastSession(_ session: IVSBroadcastSession, didEmitError error: Error) {
        
    }
    
    func view() -> UIView {
        self.previewView
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self._eventSender = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self._eventSender = nil
        return nil
    }
    
    private var _channel: FlutterMethodChannel
    private var _messenger: FlutterBinaryMessenger
    private var _session: IVSBroadcastSession?
    private var _eventSender: FlutterEventSink?
    
    @IBOutlet private var previewView: UIView!
    @IBOutlet private var connectionView: UIView!
    
    init(_ frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        previewView = UIView(frame: frame)
        self._messenger = messenger
        _channel = FlutterMethodChannel(name: "ivs_broadcaster", binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "ivs_broadcaster_event", binaryMessenger: messenger)
        super.init()
        eventChannel.setStreamHandler(self)
        _channel.setMethodCallHandler(handle)
        self.checkAVPermissions { granted in
            if granted {
                self.setupSession()
            }
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "startBroadcast":
               let args = call.arguments as? [String: Any]
                startBroadcast(
                    key: args?["streamKey"] ?? "",
                    imgset:  args?["imgset"] as! String ,
                    cameraType: args?["cameraType"] ?? "1"
                )
            break;
            case "stopBroadcast":
                stopBroadcast()
            break;
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    func stopBroadcast() {
        self.broadcastSession?.stop()
        self.broadcastSession = nil
        previewView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    func startBroadcast(key: Any, imgset: String, cameraType: Any) {
                do {
                    try self.broadcastSession?.start(with: URL(string: imgset)!, streamKey: key as! String)
                } catch {
        
                }
    }
    
    private var attachedCamera: IVSDevice? {
        didSet {
            if let preview = try? (attachedCamera as? IVSImageDevice)?.previewView(with: .fill) {
                attachCameraPreview(container: previewView, preview: preview)
            } else {
                previewView.subviews.forEach { $0.removeFromSuperview() }
            }
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
    
    func checkAVPermissions(_ result: @escaping (Bool) -> Void) {
        // Make sure we have both audio and video permissions before setting up the broadcast session.
        checkOrGetPermission(for: .video) { granted in
            guard granted else {
                result(false)
                return
            }
            self.checkOrGetPermission(for: .audio) { granted in
                guard granted else {
                    result(false)
                    return
                }
                result(true)
            }
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
    
    private var broadcastSession: IVSBroadcastSession?
    
    private func chooseDevice(_ sender: UIButton, type: IVSDeviceType, deviceName: String, deviceSelected: @escaping (IVSDeviceDescriptor) -> Void) {
        let alert = UIAlertController(title: "Choose a \(deviceName)", message: nil, preferredStyle: .actionSheet)
        IVSBroadcastSession.listAvailableDevices()
            .filter { $0.type == type }
            .forEach { device in
                deviceSelected(device)
            }
    }
 


    private func setupSession() {
        do {
            IVSBroadcastSession.applicationAudioSessionStrategy = .playAndRecord
            let broadcastSession = try IVSBroadcastSession(configuration: IVSPresets.configurations().standardPortrait(),
                                                           descriptors: IVSPresets.devices().backCamera(),
                                                           delegate: self)
            broadcastSession.awaitDeviceChanges { [weak self] in
                let devices = broadcastSession.listAttachedDevices()
                let cameras = devices
                    .filter { $0.descriptor().type == .camera }
                    .compactMap { $0 as? IVSImageDevice }

                self?.attachedCamera = cameras.first
            }
            self.broadcastSession = broadcastSession
        } catch {
           
        }
    }

    private func setCamera(_ device: IVSDeviceDescriptor) {
        guard let broadcastSession = self.broadcastSession else { return }
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

    

    private func refreshAttachedDevices() {
        guard let session = broadcastSession else { return }
        let attachedDevices = session.listAttachedDevices()
        let cameras = attachedDevices.filter { $0.descriptor().type == .camera }
        let microphones = attachedDevices.filter { $0.descriptor().type == .microphone }
        attachedCamera = cameras.first
    }

}
