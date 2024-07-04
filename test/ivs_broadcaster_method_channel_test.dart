import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ivs_broadcaster/ivs_broadcaster_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIvsBroadcaster platform = MethodChannelIvsBroadcaster();
  const MethodChannel channel = MethodChannel('ivs_broadcaster');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
