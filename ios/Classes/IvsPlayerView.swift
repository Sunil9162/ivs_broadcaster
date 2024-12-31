import UIKit
import AVFoundation
import Flutter
import AmazonIVSPlayer

class IvsPlayerView: NSObject, FlutterPlatformView, FlutterStreamHandler , IVSPlayer.Delegate{
    
    private var playerView: UIView
    private var _methodChannel: FlutterMethodChannel?
    private var _eventChannel: FlutterEventChannel?
    private var _eventSink: FlutterEventSink?
    let player =  IVSPlayer()
    private var _ivsPlayerView: IVSPlayerView?
    
    
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
        playerView =  UIView(frame: frame)
        super.init();
        player.delegate = self
        _methodChannel?.setMethodCallHandler(onMethodCall)
        _eventChannel?.setStreamHandler(self)
    }
    
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch(call.method){
        case "startPlayer":
            let args = call.arguments as? [String: Any]
            let url = args?["url"] as? String
            let autoPlay = args?["autoPlay"] as? Bool
            startPlayer(url!, autoPlay!)
            result(true)
        case "stopPlayer":
            stopPlayer()
            result(true)
        case "mute":
            mutePlayer()
            result(true)
        case "pause":
            pausePlayer()
            result(true)
        case "resume":
            resumePlayer()
            result(true)
        case "seek":
            let args = call.arguments as? [String: Any]
            let time = args?["time"] as? String
            seekPlayer(time!)
            result(true)
        case "position":
            result(getPosition())
        case "qualities":
            let qualities = getQualities()
            print(qualities)
            result(qualities)
        case "setQuality":
            let args = call.arguments as? [String: Any]
            let quality = args?["quality"] as? String
            setQuality(quality!)
            result(true)
        case "autoQuality":
            toggleAutoQuality()
            result(true)
        case "isAuto":
            result(isAuto())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func isAuto()-> Bool{
        if _ivsPlayerView != nil {
            return  _ivsPlayerView?.player?.autoQualityMode ?? false
        }
        return false
    }
    
    func toggleAutoQuality(){
        if _ivsPlayerView != nil {
            _ivsPlayerView?.player?.autoQualityMode.toggle()
        }
    }
    
    func setQuality(_ quality: String) {
        if _ivsPlayerView != nil {
            let qualities = _ivsPlayerView?.player?.qualities
            let qualitytobechange = qualities?.first(
                where: { $0.name == quality
                } )
            _ivsPlayerView?.player?.setQuality(qualitytobechange!, adaptive: true)
        }
    }
    
    func getQualities() -> Array<String> {
        if _ivsPlayerView != nil {
            return _ivsPlayerView?.player?.qualities.map{$0.name} as! Array<String>
        }
        return []
    }
    
    func getPosition ()-> String {
        if _ivsPlayerView != nil {
            return _ivsPlayerView?.player?.position.seconds.description ?? "0"
        }
        return "0";
    }
    
    
    func seekPlayer(_ time: String){
        if _ivsPlayerView != nil {
            _ivsPlayerView?.player?.seek(to:  CMTimeMake(value: Int64(time) ?? 0, timescale: 1))
        }
    }
    
    func startPlayer(_ url:String, _ autoPlay:Bool){
        do{
            _ivsPlayerView = IVSPlayerView()
            _ivsPlayerView?.player = player
            player.load(URL(string: url))
            if autoPlay {
                player.play()
            }
            attachPreview(container: playerView, preview: _ivsPlayerView!)
        }
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
    
    func stopPlayer(){
        player.pause()
        _ivsPlayerView?.player = nil
    }
    
    func mutePlayer(){
        do {
            if player.volume == 0 {
                player.volume = 1
            }else{
                player.volume = 0
            }
        }
    }
    
    func pausePlayer(){
        if _ivsPlayerView != nil {
            _ivsPlayerView?.player?.pause()
        }
    }
    
    func resumePlayer(){
        if _ivsPlayerView != nil {
            _ivsPlayerView?.player?.play()
        }
    }
}
