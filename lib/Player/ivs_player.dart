// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Player/ivs_player_interface.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';
import 'package:ivs_broadcaster/helpers/strings.dart';

/// [IvsPlayer] is a singleton class that acts as an interface to control the IVS (Interactive Video Service) player.
/// It manages the playback, streaming quality, and state of the player, and provides various streams for tracking player status.
class IvsPlayer {
  // Private constructor for the singleton instance
  IvsPlayer._();

  /// The singleton instance of [IvsPlayer].
  static final IvsPlayer instance = IvsPlayer._();

  /// Factory constructor to return the singleton instance.
  factory IvsPlayer() {
    return instance;
  }

  /// Returns the appropriate view widget depending on the platform (Android or iOS).
  ///
  /// - For Android, it uses [AndroidView] to create a platform-specific view.
  /// - For iOS, it uses [UiKitView] to create a platform-specific view.
  /// - If the platform is not supported, a message is displayed.
  Widget _getView() {
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: 'ivs_player',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'ivs_player',
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const Center(
      child: Text(
        'Platform not supported',
        style: TextStyle(
          color: Colors.red,
          fontSize: 20,
        ),
      ),
    );
  }

  /// Builds the player view widget.
  /// The player view is created using a platform-specific view (AndroidView or UiKitView).
  Widget buildPlayerView() {
    return _getView();
  }

  /// Instance of [IvsPlayerInterface] that interacts with the platform-specific implementation.
  final _controller = IvsPlayerInterface.instance;

  /// StreamController to broadcast the current position of the player.
  StreamController<Duration> positionStream = StreamController.broadcast();

  /// StreamController to broadcast the sync time of the player.
  StreamController<Duration> syncTimeStream = StreamController.broadcast();

  /// StreamController to broadcast the total duration of the content being played.
  StreamController<Duration> durationStream = StreamController.broadcast();

  /// StreamController to broadcast the current streaming quality.
  StreamController<String> qualityStream = StreamController.broadcast();

  /// StreamController to broadcast the current state of the player.
  StreamController<PlayerState> playeStateStream = StreamController.broadcast();

  /// StreamController to broadcast any errors encountered during playback.
  StreamController<String> errorStream = StreamController.broadcast();

  /// StreamController to broadcast whether auto-quality adjustment is enabled.
  StreamController<bool> isAutoQualityStream = StreamController.broadcast();

  /// StreamSubscription to periodically update the player's position.
  StreamSubscription? _positionStreamSubs;

  /// Toggles mute/unmute for the player.
  void muteUnmute() {
    _controller.muteUnmute();
  }

  /// Pauses the player.
  void pause() {
    _controller.pause();
  }

  /// Resumes playback on the player.
  void resume() {
    _controller.resume();
  }

  /// Starts the player with a given [url] and optional [autoPlay] flag.
  ///
  /// This method initializes the player and begins streaming the content from the specified URL.
  /// It listens for various events such as player state changes, quality updates, and errors, and broadcasts them via the respective streams.
  void startPlayer(String url, {bool autoPlay = true}) {
    _controller.createPlayer(url);
    _controller.startPlayer(
      url,
      autoPlay: autoPlay,
      onData: (data) async {
        // Parse incoming data and add relevant information to the appropriate streams.
        final Map<String, dynamic> parsedData = Map<String, dynamic>.from(data);
        if (parsedData.containsKey(AppStrings.state)) {
          final value = parsedData[AppStrings.state];
          playeStateStream.add(PlayerState.values[value]);
        } else if (parsedData.containsKey(AppStrings.quality)) {
          final value = parsedData[AppStrings.quality];
          qualityStream.add(value);
          isAutoQualityStream.add(await isAutoQuality());
        } else if (parsedData.containsKey(AppStrings.duration)) {
          final value = parsedData[AppStrings.duration];
          final duration = double.tryParse(value.toString());
          durationStream.add(
            Duration(
              seconds: (duration?.isFinite ?? false) ? duration!.toInt() : 0,
            ),
          );
          getQualities();
        } else if (parsedData.containsKey(AppStrings.syncTime)) {
          final value = parsedData[AppStrings.syncTime];
          syncTimeStream
              .add(Duration(seconds: double.parse(value.toString()).toInt()));
        } else if (parsedData.containsKey(AppStrings.error)) {
          final value = parsedData[AppStrings.error];
          errorStream.add(value);
        }
      },
      onError: (error) {},
    );

    // Periodically update the player's position.
    _positionStreamSubs?.cancel();
    _positionStreamSubs = Stream.periodic(
      const Duration(milliseconds: 100),
    ).listen(
      (event) async {
        positionStream.add(await _controller.getPosition());
      },
    );
  }

  /// Stops the player and cancels the position update stream subscription.
  void stopPlayer() async {
    _controller.stopPlayer();
    _positionStreamSubs?.cancel();
    _positionStreamSubs = null;
  }

  /// ValueNotifier to hold the available streaming qualities.
  final qualities = ValueNotifier<List<String>>([]);

  /// Retrieves the available streaming qualities and updates the [qualities] ValueNotifier.
  Future<void> getQualities() async {
    qualities.value = (await _controller.getQualities()).toSet().toList();
  }

  /// Sets the streaming quality to the specified [value].
  Future<void> setQuality(String value) async {
    await _controller.setQuality(value);
    isAutoQualityStream.add(await isAutoQuality());
  }

  /// Toggles the auto-quality adjustment setting.
  Future<void> toggleAutoQuality() async {
    await _controller.toggleAutoQuality();
    isAutoQualityStream.add(await isAutoQuality());
  }

  /// Checks whether auto-quality adjustment is enabled.
  Future<bool> isAutoQuality() async {
    return await _controller.isAutoQuality();
  }

  /// Seeks the player to the specified [duration].
  Future<void> seekTo(Duration duration) async {
    await _controller.seekTo(duration);
  }

  void selectPlayer(String s) async {
    _controller.selectPlayer(s);
  }

  void multiPlayer(List<String> s) async {
    _controller.multiPlayer(s);
  }

  Future<Uint8List> getThumbnail({String? url}) async {
    return await _controller.getThumbnail(url: url);
  }
}
