import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Player/ivs_player_interface.dart';

class IvsPlayerMethodChannel extends IvsPlayerInterface {
  final _methodChannel = const MethodChannel("ivs_player");
  final _eventChannel = const EventChannel('ivs_player_event');

  StreamSubscription? playerStateSubscription;

  @override
  void muteUnmute() {
    try {
      _methodChannel.invokeMethod("mute");
    } catch (e) {
      throw Exception("Unable to Stop");
    }
  }

  @override
  void pause() async {
    try {
      await _methodChannel.invokeMethod("pause");
    } catch (e) {
      throw Exception("Unable to pause [Pause]");
    }
  }

  @override
  void resume() async {
    try {
      await _methodChannel.invokeMethod("resume");
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to resume [Resume]");
    }
  }

  @override
  void startPlayer(
    String url, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  }) async {
    try {
      await _methodChannel
          .invokeMethod("startPlayer", {"url": url, "autoPlay": autoPlay});
      if (playerStateSubscription != null) {
        playerStateSubscription?.cancel();
      }
      playerStateSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(onData, onError: onError);
    } catch (e) {
      throw Exception("Unable to Load Url [Start Player]");
    }
  }

  @override
  void stopPlayer() async {
    try {
      await _methodChannel.invokeMethod("stopPlayer");
      playerStateSubscription?.cancel();
      playerStateSubscription = null;
    } catch (e) {
      throw Exception("Unable to Stop [Stop Player]");
    }
  }

  @override
  Future<List<String>> getQualities() async {
    try {
      final data = await _methodChannel.invokeMethod("qualities");

      return List<String>.from(data);
    } catch (e) {
      throw Exception("Unable to Get Qualities [Get Qualities]");
    }
  }

  @override
  Future<void> setQuality(String value) async {
    try {
      return await _methodChannel.invokeMethod("setQuality", {
        "quality": value,
      });
    } catch (e) {
      throw Exception("Unable to set Quality [Set Quality]");
    }
  }

  @override
  Future<bool> isAutoQuality() async {
    try {
      return await _methodChannel.invokeMethod("isAuto");
    } catch (e) {
      log(e.toString());
      throw Exception("Error in getting Auto Quality [isAuto Quality]");
    }
  }

  @override
  Future<void> toggleAutoQuality() async {
    try {
      return await _methodChannel.invokeMethod("autoQuality");
    } catch (e) {
      throw Exception("Unable to toggle AutoQuality [toggleAuto Quality]");
    }
  }

  @override
  Future<void> seekTo(Duration duration) async {
    try {
      return await _methodChannel.invokeMethod("seek", {
        "time": duration.inSeconds.toString(),
      });
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to Seek [SeekTo]");
    }
  }

  @override
  Future<Duration> getPosition() async {
    try {
      return Duration(
        seconds: int.parse(
            ((await _methodChannel.invokeMethod("position")).toString())
                .split(".")
                .first),
      );
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to Seek [SeekTo]");
    }
  }
}
