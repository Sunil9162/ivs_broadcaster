// ignore_for_file: constant_identifier_names

enum BroadCastState {
  INVALID,
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  ERROR;
}

enum BroadcastQuality {
  NearMaximum,
  High,
  Medium,
  Low,
  NearMinimum,
}

enum BroadcastHealth {
  Excellent,
  High,
  Medium,
  Low,
  Bad,
}

enum CameraType {
  FRONT,
  BACK,
}

enum IOSCameraLens {
  DualCamera,
  WideAngleCamera,
  TripleCamera,
  TelePhotoCamera,
  DualWideAngleCamera,
  TrueDepthCamera,
  UltraWideCamera,
  LiDarDepthCamera,
  DefaultCamera,
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

enum IvsQuality {
  q360,
  q720,
  q1080,
}

extension IvsQualityExtension on IvsQuality {
  String get description {
    switch (this) {
      case IvsQuality.q360:
        return '360';
      case IvsQuality.q720:
        return '720';
      case IvsQuality.q1080:
        return '1080';
    }
  }
}
