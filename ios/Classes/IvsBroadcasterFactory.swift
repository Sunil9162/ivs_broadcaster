import Foundation
import Flutter
import UIKit

public class IvsBroadcasterFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return IvsBroadcasterView(frame, viewId: viewId, args: args, messenger: messenger)
    } 
}
