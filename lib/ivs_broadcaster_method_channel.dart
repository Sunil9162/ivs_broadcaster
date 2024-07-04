import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ivs_broadcaster_platform_interface.dart';

/// An implementation of [IvsBroadcasterPlatform] that uses method channels.
class MethodChannelIvsBroadcaster extends IvsBroadcasterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ivs_broadcaster');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
