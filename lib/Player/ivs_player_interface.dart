import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ivs_player_method_channel.dart';

abstract class IvsPlayerInterface extends PlatformInterface {
  IvsPlayerInterface() : super(token: _token);

  static final Object _token = Object();

  static IvsPlayerInterface _instance = IvsPlayerMethodChannel();
  static IvsPlayerInterface get instance => _instance;

  static set instance(IvsPlayerInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void startPlayer(
    String url, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });
  void resume();
  void pause();
  void muteUnmute();
  void stopPlayer();

  Future<List<String>> getQualities();

  Future<void> setQuality(String value);

  Future<void> toggleAutoQuality();

  Future<bool> isAutoQuality();

  Future<void> seekTo(Duration duration);

  Future<Duration> getPosition();
}
