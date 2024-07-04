import 'package:flutter_test/flutter_test.dart';
import 'package:ivs_broadcaster/ivs_broadcaster_method_channel.dart';
import 'package:ivs_broadcaster/ivs_broadcaster_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIvsBroadcasterPlatform
    with MockPlatformInterfaceMixin
    implements IvsBroadcasterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IvsBroadcasterPlatform initialPlatform =
      IvsBroadcasterPlatform.instance;

  test('$MethodChannelIvsBroadcaster is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIvsBroadcaster>());
  });
}
