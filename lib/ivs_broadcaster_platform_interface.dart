import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ivs_broadcaster_method_channel.dart';

abstract class IvsBroadcasterPlatform extends PlatformInterface {
  /// Constructs a IvsBroadcasterPlatform.
  IvsBroadcasterPlatform() : super(token: _token);

  static final Object _token = Object();

  static IvsBroadcasterPlatform _instance = MethodChannelIvsBroadcaster();

  /// The default instance of [IvsBroadcasterPlatform] to use.
  ///
  /// Defaults to [MethodChannelIvsBroadcaster].
  static IvsBroadcasterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IvsBroadcasterPlatform] when
  /// they register themselves.
  static set instance(IvsBroadcasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
