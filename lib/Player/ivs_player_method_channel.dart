import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Player/ivs_player_interface.dart';

/// [IvsPlayerMethodChannel] is a platform-specific implementation of the [IvsPlayerInterface]
/// using the MethodChannel and EventChannel to communicate with native code.
class IvsPlayerMethodChannel extends IvsPlayerInterface {
  /// [MethodChannel] used to invoke methods on the native platform.
  final _methodChannel = const MethodChannel("ivs_player");

  /// [EventChannel] used to receive events from the native platform.
  final _eventChannel = const EventChannel('ivs_player_event');

  /// StreamSubscription for listening to player state changes.
  StreamSubscription? playerStateSubscription;

  /// Toggles mute/unmute for the player.
  @override
  void muteUnmute() {
    try {
      _methodChannel.invokeMethod("mute");
    } catch (e) {
      throw Exception("Unable to mute/unmute the player [Mute/Unmute]");
    }
  }

  /// Pauses the player.
  @override
  void pause() async {
    try {
      await _methodChannel.invokeMethod("pause");
    } catch (e) {
      throw Exception("Unable to pause the player [Pause]");
    }
  }

  /// Resumes playback on the player.
  @override
  void resume() async {
    try {
      await _methodChannel.invokeMethod("resume");
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to resume the player [Resume]");
    }
  }

  /// Starts the player with a given [url] and optional [autoPlay] flag.
  ///
  /// This method initializes the player and begins streaming the content from the specified URL.
  /// It listens for various events such as player state changes and errors, and triggers the provided callbacks.
  @override
  void startPlayer(
    String url, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  }) async {
    try {
      await _methodChannel.invokeMethod("startPlayer", {
        "url": url,
        "autoPlay": autoPlay,
      });

      // Cancel any existing subscription before creating a new one.
      playerStateSubscription?.cancel();
      playerStateSubscription = _eventChannel
          .receiveBroadcastStream()
          .listen(onData, onError: onError);
    } catch (e) {
      throw Exception(
          "Unable to start the player with the provided URL [Start Player]");
    }
  }

  /// Stops the player and cancels the player state subscription.
  @override
  void stopPlayer({String? url}) async {
    try {
      await _methodChannel.invokeMethod("stopPlayer");

      // Cancel the player state subscription if it exists.
      playerStateSubscription?.cancel();
      playerStateSubscription = null;
    } catch (e) {
      throw Exception("Unable to stop the player [Stop Player]");
    }
  }

  /// Retrieves the list of available streaming qualities.
  @override
  Future<List<String>> getQualities({String? url}) async {
    try {
      final data = await _methodChannel.invokeMethod("qualities");

      // Convert the received data to a List of Strings.
      return List<String>.from(data);
    } catch (e) {
      throw Exception(
          "Unable to retrieve available streaming qualities [Get Qualities]");
    }
  }

  /// Sets the streaming quality to the specified [value].
  @override
  Future<void> setQuality(String value) async {
    try {
      return await _methodChannel.invokeMethod("setQuality", {
        "quality": value,
      });
    } catch (e) {
      throw Exception("Unable to set the streaming quality [Set Quality]");
    }
  }

  /// Checks if the player is set to auto-quality adjustment mode.
  @override
  Future<bool> isAutoQuality() async {
    try {
      return await _methodChannel.invokeMethod("isAuto");
    } catch (e) {
      log(e.toString());
      throw Exception("Error retrieving auto-quality status [isAuto Quality]");
    }
  }

  /// Toggles the auto-quality adjustment setting.
  @override
  Future<void> toggleAutoQuality() async {
    try {
      return await _methodChannel.invokeMethod("autoQuality");
    } catch (e) {
      throw Exception(
          "Unable to toggle auto-quality adjustment [Toggle Auto Quality]");
    }
  }

  /// Seeks the player to the specified [duration].
  @override
  Future<void> seekTo(Duration duration) async {
    try {
      return await _methodChannel.invokeMethod("seek", {
        "time": duration.inSeconds.toString(),
      });
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to seek to the specified duration [Seek To]");
    }
  }

  /// Retrieves the current playback position of the player.
  @override
  Future<Duration> getPosition() async {
    try {
      // Convert the retrieved position to a Duration object.
      return Duration(
        seconds: int.parse(
            ((await _methodChannel.invokeMethod("position")).toString())
                .split(".")
                .first),
      );
    } catch (e) {
      log(e.toString());
      throw Exception(
          "Unable to retrieve the current playback position [Get Position]");
    }
  }

  @override
  void createPlayer(String url) async {
    await _methodChannel.invokeMethod("createPlayer", {
      "playerId": url,
    });
  }

  @override
  void selectPlayer(String url) async {
    await _methodChannel.invokeMethod("selectPlayer", {
      "playerId": url,
    });
  }

  @override
  void multiPlayer(List<String> urls) {
    _methodChannel.invokeMethod("multiPlayer", {
      "urls": urls,
    });
  }

  @override
  Future<Uint8List> getThumbnail({
    String? url,
  }) async {
    try {
      final data = await _methodChannel.invokeMethod("getScreenshot", {
        "url": url,
      });
      return data;
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to get the screenshot [Get Screenshot]");
    }
  }
}
