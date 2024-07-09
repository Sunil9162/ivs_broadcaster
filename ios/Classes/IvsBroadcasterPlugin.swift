import Flutter
import UIKit

public class IvsBroadcasterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    //  Register the ViewFactory
    registrar.register(
        IvsBroadcasterFactory(messenger: registrar.messenger()),
        withId: "ivs_broadcaster"
    )
    
      // registrar.register(
      //     IvsPlayerFactory(messenger: registrar.messenger()),
      //     withId: "ivs_player"
      // )
  }
}


