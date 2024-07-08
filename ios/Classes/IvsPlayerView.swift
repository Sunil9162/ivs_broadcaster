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
    
    private var videoSize: CGFloat {
           let padding: CGFloat = 24
        var orientation = UIDevice.current.orientation
        var size = orientation.isPortrait ? UIScreen.main.bounds.width - padding : UIScreen.main.bounds.height - padding
           while size * 2 + padding > (orientation.isPortrait ? UIScreen.main.bounds.height : UIScreen.main.bounds.width) {
               size -= padding
           }
           return size
       }
    
    func view() -> UIView {
        return playerView;
    }
    
    func player(_ player: IVSPlayer, didChangeState state: IVSPlayer.State) {
        if _eventSink != nil {
            self._eventSink!(state.rawValue)
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
            startPlayer(url!)
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func startPlayer(_ url:String){
        do{
            _ivsPlayerView = IVSPlayerView() 
            _ivsPlayerView?.player = player
            player.load(URL(string: url))
            player.play()
            playerView.addSubview(_ivsPlayerView!)
        }
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
