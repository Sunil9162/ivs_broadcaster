// ignore_for_file: constant_identifier_names

enum BroadCastState {
  INVALID,
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR;
}

enum CameraType {
  FRONT,
  BACK,
}

enum PlayerState {
  PlayerStateIdle,

  /// Indicates that the player is ready to play the selected source.
  PlayerStateReady,

  /// Indicates that the player is buffering content.
  PlayerStateBuffering,

  /// Indicates that the player is playing.
  PlayerStatePlaying,

  /// Indicates that the player reached the end of the stream.
  PlayerStateEnded,
}
