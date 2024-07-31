import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/enums.dart';
import 'ivs_broadcaster_method_channel.dart';

abstract class IvsBroadcasterPlatform extends PlatformInterface {
  /// Constructs a IvsBroadcasterPlatform.
  IvsBroadcasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static IvsBroadcasterPlatform _instance = MethodChannelIvsBroadcaster();
  static IvsBroadcasterPlatform get instance => _instance;

  static set instance(IvsBroadcasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> requestPermissions();

  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });

  Future<void> startBroadcast();
  Future<void> stopBroadcast();
  Future<dynamic> zoomCamera(double zoomValue);
  Future<void> changeCamera(CameraType cameraType);
  Future<void> fetchNetwork();
}
