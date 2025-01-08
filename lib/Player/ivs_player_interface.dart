import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ivs_player_method_channel.dart';

/// [IvsPlayerInterface] serves as the abstract base class for platform-specific
/// implementations of the IVS (Interactive Video Service) Player functionality.
/// This interface ensures that any platform-specific implementation follows the same
/// structure and behavior.

abstract class IvsPlayerInterface extends PlatformInterface {
  /// Constructor for [IvsPlayerInterface] which passes a unique token to the superclass.
  IvsPlayerInterface() : super(token: _token);

  /// A unique token used for verification to ensure the integrity of the platform interface.
  static final Object _token = Object();

  /// The default instance of [IvsPlayerInterface] that will be used, initialized to
  /// the platform-specific implementation [IvsPlayerMethodChannel].
  static IvsPlayerInterface _instance = IvsPlayerMethodChannel();

  /// Getter to retrieve the current instance of [IvsPlayerInterface].
  static IvsPlayerInterface get instance => _instance;

  /// Setter to override the current instance with a new platform-specific implementation.
  ///
  /// The method verifies the integrity of the new instance by checking its token.
  static set instance(IvsPlayerInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Starts the player with the given [url]. Optionally, it can auto-play the content.
  ///
  /// - [url]: The streaming URL that the player should start playing.
  /// - [autoPlay]: If true, the player starts playing the content automatically.
  /// - [onData]: Callback function to handle data events from the player.
  /// - [onError]: Callback function to handle error events from the player.
  void startPlayer(
    String url, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });

  void createPlayer(String url);
  void selectPlayer(String url);

  /// Resumes the playback if the player was paused.
  void resume();

  /// Pauses the playback of the player.
  void pause();

  /// Toggles mute/unmute for the player's audio.
  void muteUnmute();

  /// Stops the player from playing and releases any resources it was using.
  void stopPlayer();

  /// Retrieves the list of available streaming qualities.
  ///
  /// Returns a [Future] that resolves to a list of quality strings.
  Future<List<String>> getQualities();

  /// Sets the streaming quality to the specified [value].
  ///
  /// - [value]: The quality level to set for the player.
  /// Returns a [Future] that completes when the quality has been set.
  Future<void> setQuality(String value);

  /// Toggles the auto-quality adjustment setting for the player.
  ///
  /// Returns a [Future] that completes when the toggle is done.
  Future<void> toggleAutoQuality();

  /// Checks if the player is currently set to auto-quality adjustment mode.
  ///
  /// Returns a [Future] that resolves to a boolean indicating whether auto-quality is enabled.
  Future<bool> isAutoQuality();

  /// Seeks the player to a specific [duration] within the content.
  ///
  /// - [duration]: The position in the content to seek to.
  /// Returns a [Future] that completes when the seek operation is done.
  Future<void> seekTo(Duration duration);

  /// Retrieves the current playback position of the player.
  ///
  /// Returns a [Future] that resolves to a [Duration] representing the current playback position.
  Future<Duration> getPosition();

  /// Sets the player to play multiple streams simultaneously.
  ///
  /// - [urls]: A list of streaming URLs to play simultaneously.
  void multiPlayer(
    List<String> urls, {
    required bool autoPlay,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });

  /// Get Screenshot of the player.
  /// Returns a [Future] that resolves to a [Uint8List] representing the path of the screenshot.
  ///
  Future<Uint8List> getThumbnail({String? url});
}
