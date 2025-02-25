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
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["state": state.rawValue]
        print(dict)
        eventSink(dict)
    }

    func player(_ player: IVSPlayer, didChangeDuration time: CMTime) {
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["duration": time.seconds]
        print(dict)
        eventSink(dict)
    }

    func player(_ player: IVSPlayer, didChangeSyncTime time: CMTime) {
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["syncTime": time.seconds]
        print(dict)
        eventSink(dict)
    }

    func player(_ player: IVSPlayer, didChangeQuality quality: IVSQuality?) {
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["quality": quality?.name ?? ""]
        print(dict)
        eventSink(dict)
    }
    
    func player(_ player: IVSPlayer, didOutputCue cue: IVSCue) {
        if let textMetadataCue = cue as? IVSTextMetadataCue {
            let dict: [String: Any] = [
                "metadata": textMetadataCue.text,
                "startTime": textMetadataCue.startTime.epoch,
                "endTime": textMetadataCue.endTime.epoch,
            ]
            _eventSink?(dict)
        }
    }

    func player(_ player: IVSPlayer, didFailWithError error: any Error) {
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["error": error.localizedDescription]
        print(dict)
        eventSink(dict)
    }

    func player(_ player: IVSPlayer, didSeekTo time: CMTime) {
        guard let eventSink = _eventSink else { return }
        let dict: [String: Any] = ["seekedToTime": time.seconds]
        print(dict)
        eventSink(dict)
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
        print(call.method)
        switch(call.method) {
        case "createPlayer":
            let args = call.arguments as? [String: Any]
            let playerId = args?["playerId"] as? String
            createPlayer(playerId: playerId!)
            result(true)
        case "multiPlayer":
            let args = call.arguments as? [String: Any]
            let urls = args?["urls"] as? [String]
            multiPlayer(urls!)
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
            if (playerId != nil){
                stopPlayer(playerId: playerId!)
            }
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
            if(playerId != nil){
                let qualities = getQualities(playerId: playerId!)
                result(qualities)
            }else {
                result([])
            }
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
        guard let videoURL = URL(string: url) else {
            print("Invalid URL")
            return nil
        }
        
        // Create an AVAsset and AVAssetImageGenerator
        let asset = AVAsset(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true // Adjust for orientation
        
        // Define the time for the screenshot (e.g., at the 1-second mark)
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        do {
            // Generate the CGImage
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            // Convert to UIImage
            let image =  UIImage(cgImage: cgImage)
            guard let imageData = image.pngData() else { return nil }
            return [UInt8](imageData)
        } catch {
            print("Failed to generate screenshot: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    func multiPlayer(_ urls:[String]) {
        self.playerId = urls.first!
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
        UIView.animate(withDuration: 0.1, animations: {
            self.playerView.alpha = 0
        }) { _ in
            // Update the preview
            self.attachPreview(container: self.playerView, preview: playerView)
            
            // Fade in the new preview
            UIView.animate(withDuration: 0.5) {
                self.playerView.alpha = 1
            }
        }
        updateEventsOfCurrentPlayer()
    }
    
    func updateEventsOfCurrentPlayer() {
        guard let player = players[self.playerId!] else { return }
        player.delegate = self 
        let dict: [String: Any] = ["state": player.state.rawValue, "duration": player.duration.seconds, "syncTime": player.syncTime.seconds, "quality": player.quality?.name ?? ""]
        print(dict)
        _eventSink?(dict)
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
        if( players[playerId] != nil ){
            return
        }
        let player = IVSPlayer()
        player.delegate = self
        self.playerId = playerId
        players[playerId] = player
        playerViews[playerId] = IVSPlayerView()
        playerViews[playerId]?.player = player
        player.load(URL(string: playerId))
    }
    
    func startPlayer(url: String, autoPlay: Bool){
        guard let player = players[url], let _ = playerViews[url] else {
            return
        }
        self.playerId = url
        if autoPlay {
            player.play()
        }
        selectPlayer(playerId: self.playerId!)
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
