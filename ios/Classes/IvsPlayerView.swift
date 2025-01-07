import UIKit
import AVFoundation
import Flutter
import AmazonIVSPlayer

class IvsPlayerView: NSObject, FlutterPlatformView, FlutterStreamHandler , IVSPlayer.Delegate{
    
    private var playerView: UIView
    private var _methodChannel: FlutterMethodChannel?
    private var _eventChannel: FlutterEventChannel?
    private var _eventSink: FlutterEventSink?
    private var players: [String: IVSPlayer] = [:] // Dictionary to manage multiple players
    private var playerViews: [String: IVSPlayerView] = [:]
    private var playerId: String?
    
    func view() -> UIView {
        return playerView;
    }
    
    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["state"] = state.rawValue
            self._eventSink!(dict)
        }
    }
    
    func player(_ player: IVSPlayer, didChangeDuration time: CMTime) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["duration"] = time.seconds
            self._eventSink!(dict)
        }
    }
    
    func player(_ player: IVSPlayer, didChangeSyncTime time: CMTime) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["syncTime"] = time.seconds
            self._eventSink!(dict)
        }
    }
    
    func player(_ player: IVSPlayer, didChangeQuality quality: IVSQuality?) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["quality"] = quality?.name
            self._eventSink!(dict)
        }
    }
    
    func player(_ player: IVSPlayer, didFailWithError error: any Error) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["error"] = error.localizedDescription
            self._eventSink!(dict)
        }
    }
    
    func player(_ player: IVSPlayer, didSeekTo time: CMTime) {
        if _eventSink != nil {
            var dict = [String: Any]()
            dict = [:]
            dict["seekedtotime"] = time.seconds
            self._eventSink!(dict)
        }
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self._eventSink = events;
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self._eventSink = nil
        return nil
    }
    
    init(_ frame: CGRect,
         viewId: Int64,
         args: Any?,
         messenger: FlutterBinaryMessenger
    ) {
        _methodChannel = FlutterMethodChannel(
            name: "ivs_player", binaryMessenger: messenger
        );
        _eventChannel = FlutterEventChannel(name: "ivs_player_event", binaryMessenger: messenger)
        playerView = UIView(frame: frame)
        super.init();
        _methodChannel?.setMethodCallHandler(onMethodCall)
        _eventChannel?.setStreamHandler(self)
    }
    
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method) {
        case "createPlayer":
            let args = call.arguments as? [String: Any]
            let playerId = args?["playerId"] as? String
            createPlayer(playerId: playerId!)
            result(true)
        case "multiPlayer":
            let args = call.arguments as? [String: Any]
            let urls = args?["urls"] as? [String]
            multiPlayer( urls!)
            result("Players created successfully")
        case "selectPlayer":
            let args = call.arguments as? [String: Any]
            let playerId = args?["playerId"] as? String
            selectPlayer(playerId: playerId!)
            result(true)
        case "startPlayer":
            let args = call.arguments as? [String: Any]
            let url = args?["url"] as? String
            let autoPlay = args?["autoPlay"] as? Bool
            startPlayer(  url: url!, autoPlay: autoPlay!)
            result(true)
        case "stopPlayer":
            let playerId = self.playerId
            stopPlayer(playerId: playerId!)
            result(true)
        case "mute":
            let playerId = self.playerId
            mutePlayer(playerId: playerId!)
            result(true)
        case "pause":
            let playerId = self.playerId
            pausePlayer(playerId: playerId!)
            result(true)
        case "resume":
            let playerId = self.playerId
            resumePlayer(playerId: playerId!)
            result(true)
        case "seek":
            let args = call.arguments as? [String: Any]
            let playerId = self.playerId
            let time = args?["time"] as? String
            seekPlayer(playerId: playerId!, time!)
            result(true)
        case "position":
            let playerId = self.playerId
            result(getPosition(playerId: playerId!))
        case "qualities":
            let playerId = self.playerId
            let qualities = getQualities(playerId: playerId!)
            result(qualities)
        case "setQuality":
            let args = call.arguments as? [String: Any]
            let playerId = self.playerId
            let quality = args?["quality"] as? String
            setQuality(playerId: playerId!, quality!)
            result(true)
        case "autoQuality":
            let playerId = self.playerId
            toggleAutoQuality(playerId: playerId!)
            result(true)
        case "isAuto":
            let playerId = self.playerId
            result(isAuto(playerId: playerId!))
        case "getScreenshot":
            let args = call.arguments as? [String: Any]
            let url = args?["url"] as? String
            result(getScreenShot(url: url!))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getScreenShot(url: String) -> [UInt8]? {
        // Ensure the URL is valid
        guard let videoURL = URL(string: url) else {
            print("Invalid URL")
            return nil
        }
        
        // Create an AVAsset from the URL
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Capture a frame at 1 second
        let time = CMTime(seconds: 1, preferredTimescale: 600)
        do {
            // Generate a CGImage from the video
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            
            // Convert the UIImage to PNG data
            if let imageData = uiImage.pngData() {
                // Convert the Data to [UInt8]
                let byteArray = [UInt8](imageData)
                return byteArray
            } else {
                print("Failed to convert UIImage to PNG data")
                return nil
            }
        } catch {
            print("Error generating image: \(error)")
            return nil
        }
    }
    
    func multiPlayer(_ urls:[String]) {
        for url in urls {
            let player = IVSPlayer()
            player.delegate = self
            let playerId = url
            players[playerId] = player
            playerViews[playerId] = IVSPlayerView()
            playerViews[playerId]?.player = player
            player.load(URL(string: url))
            player.volume = 0
        }
        // Play All Players and attach to the first player to preview
        for (index, player) in players.enumerated() {
            if index == 0 {
                player.value.play()
                player.value.volume = 1
                attachPreview(container: self.playerView, preview: playerViews[player.key]!)
            } else {
                player.value.play()
            }
        }
    }
    
    func selectPlayer(playerId: String) {
        guard let player = players[playerId] else { return }
        let previousPlayer = playerId == self.playerId ? nil : self.playerId
        if let previousPlayer {
            players[previousPlayer]?.delegate = nil
            players[previousPlayer]?.volume = 0
        }
        self.playerId = playerId
        let playerView = playerViews[playerId]!
        player.volume = 1
        player.delegate = self
        attachPreview(container: self.playerView, preview: playerView)
    }
    
    func stopPlayer(playerId: String) {
        guard let player = players[playerId] else { return }
        player.pause()
        players.removeValue(forKey: playerId)
        playerViews.removeValue(forKey: playerId)
    }
    
    func mutePlayer(playerId: String) {
        guard let player = players[playerId] else { return }
        player.volume = player.volume == 0 ? 1 : 0
    }
    
    func pausePlayer(playerId: String) {
        guard let player = players[playerId] else { return }
        player.pause()
    }
    
    func resumePlayer(playerId: String) {
        guard let player = players[playerId] else { return }
        player.play()
    }
    
    func seekPlayer(playerId: String, _ time: String) {
        guard let player = players[playerId] else { return }
        player.seek(to: CMTimeMake(value: Int64(time) ?? 0, timescale: 1))
    }
    
    func getPosition(playerId: String) -> String {
        guard let player = players[playerId] else { return "0" }
        return player.position.seconds.description
    }
    
    func getQualities(playerId: String) -> [String] {
        guard let player = players[playerId] else { return [] }
        return player.qualities.map { $0.name }
    }
    
    func setQuality(playerId: String, _ quality: String) {
        guard let player = players[playerId] else { return }
        let qualities = player.qualities
        let qualityToChange = qualities.first { $0.name == quality }
        player.setQuality(qualityToChange!, adaptive: true)
    }
    
    func toggleAutoQuality(playerId: String) {
        guard let player = players[playerId] else { return }
        player.autoQualityMode.toggle()
    }
    
    func isAuto(playerId: String) -> Bool {
        guard let player = players[playerId] else { return false }
        return player.autoQualityMode
    }
    
    func createPlayer(playerId: String) {
        let player = IVSPlayer()
        player.delegate = self
        self.playerId = playerId
        players[playerId] = player
        playerViews[playerId] = IVSPlayerView()
        playerViews[playerId]?.player = player
    }
    
    func startPlayer(url: String, autoPlay: Bool){
        guard let player = players[self.playerId!], let playerView = playerViews[playerId!] else {
            return
        }
        player.load(URL(string: url))
        if autoPlay {
            player.play()
        }
        attachPreview(container: self.playerView, preview: playerView)
      
    }
    
    func attachPreview(container: UIView, preview: UIView) {
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
     
}
