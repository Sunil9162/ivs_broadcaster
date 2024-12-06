import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/enums.dart';
import 'Classes/zoom_factor.dart';
import 'ivs_broadcaster_method_channel.dart';

/// An abstract base class that defines the interface for platform-specific implementations
/// of the IVS Broadcaster functionality. This class uses the `PlatformInterface` from the
/// `plugin_platform_interface` package to ensure that platform-specific implementations
/// adhere to this interface.
///
/// The default implementation uses method channels (`MethodChannelIvsBroadcaster`), but
/// other implementations can be swapped in by changing the [instance] property.
abstract class IvsBroadcasterPlatform extends PlatformInterface {
  /// Constructs an [IvsBroadcasterPlatform].
  ///
  /// This constructor calls the `PlatformInterface` constructor with a unique token,
  /// ensuring that platform-specific implementations can be validated.
  IvsBroadcasterPlatform() : super(token: _token);

  /// A private token used to verify that platform-specific implementations extend this class.
  static final Object _token = Object();

  /// The default instance of [IvsBroadcasterPlatform] that is used to interact with the
  /// platform-specific implementation. It is initially set to an instance of [MethodChannelIvsBroadcaster].
  static IvsBroadcasterPlatform _instance = MethodChannelIvsBroadcaster();

  /// Gets the current instance of [IvsBroadcasterPlatform].
  ///
  /// This will return the platform-specific implementation being used (e.g., [MethodChannelIvsBroadcaster]).
  static IvsBroadcasterPlatform get instance => _instance;

  /// Sets a new platform-specific implementation of [IvsBroadcasterPlatform].
  ///
  /// The [instance] must extend [IvsBroadcasterPlatform] and will be verified using a unique token.
  /// This allows for flexibility in swapping out the underlying platform-specific implementation.
  static set instance(IvsBroadcasterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Requests camera and microphone permissions necessary for broadcasting.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the permissions were granted.
  Future<bool> requestPermissions();

  /// Starts the camera preview for the broadcast with the specified settings.
  ///
  /// * [imgset]: The image set identifier for the broadcast.
  /// * [streamKey]: The stream key for the broadcast.
  /// * [quality]: The desired broadcast quality, default is [IvsQuality.q720].
  /// * [cameraType]: The camera to use for the preview, default is [CameraType.BACK].
  /// * [onData]: A callback function to handle real-time data from the event stream.
  /// * [onError]: A callback function to handle errors from the event stream.
  ///
  /// Returns a [Future] that completes when the preview has started.
  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    IvsQuality quality = IvsQuality.q720,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  });

  /// Starts the broadcast.
  ///
  /// Returns a [Future] that completes when the broadcast has started.
  Future<void> startBroadcast();

  /// Stops the ongoing broadcast.
  ///
  /// Returns a [Future] that completes when the broadcast has stopped.
  Future<void> stopBroadcast();

  /// Zooms the camera to the specified zoom level.
  ///
  /// * [zoomValue]: The zoom level to set, typically between 1.0 (no zoom) and the maximum zoom level supported by the device.
  ///
  /// Returns a [Future] that completes with the result of the zoom operation.
  Future<dynamic> zoomCamera(double zoomValue);

  /// Switches the camera to the specified [CameraType].
  ///
  /// * [cameraType]: The camera to switch to, either [CameraType.FRONT] or [CameraType.BACK].
  ///
  /// Returns a [Future] that completes when the camera has been changed.
  Future<void> changeCamera(CameraType cameraType);

  /// Toggle Mute and Unmute the microphone
  ///
  Future<void> toggleMute();

  /// To Check if currently Muted or not
  ///
  /// * Always return the value if not started then it will give false
  ///
  Future<bool> isMuted();

  /// To Update CameraLens to the specified [IOSCameraLens]
  ///
  /// * [cameraLens]: The camera lens to switch to, either [IOSCameraLens.DualCamera] or [IOSCameraLens.WideAngleCamera] etc.
  ///
  /// Returns a [Future] that completes when the camera lens has been changed.
  ///
  Future<String?> updateCameraLens(IOSCameraLens cameraLens);

  Future<List<IOSCameraLens>> getAvailableCameraLens();

  Future<ZoomFactor> getZoomFactor();

  Future<bool?> setFocusMode(FocusMode focusMode);

  Future<bool?> setFocusPoint(double x, double y);

  Future<void> captureVideo(int seconds);

  Future<void> stopVideoCapture();
}
