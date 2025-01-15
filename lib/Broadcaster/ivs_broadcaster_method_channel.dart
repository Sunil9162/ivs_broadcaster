import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Classes/zoom_factor.dart';
import 'ivs_broadcaster_platform_interface.dart';

/// A platform-specific implementation of the [IvsBroadcasterPlatform] using method channels.
/// This class communicates with the native platform (iOS/Android) to manage broadcasting functionalities
/// like camera control, permissions, and streaming setup.
class MethodChannelIvsBroadcaster extends IvsBroadcasterPlatform {
  /// The method channel used to communicate with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ivs_broadcaster');

  /// The event channel used to receive real-time broadcasting data from the native platform.
  final eventChannel = const EventChannel("ivs_broadcaster_event");

  /// A subscription to the event stream, listening for real-time data and errors during broadcasting.
  StreamSubscription? eventStream;

  /// Switches the camera to the specified [CameraType].
  ///
  /// * [cameraType]: The camera to switch to, either [CameraType.FRONT] or [CameraType.BACK].
  ///
  /// Throws an [Exception] if the camera switch fails.
  @override
  Future<void> changeCamera(CameraType cameraType) async {
    try {
      await methodChannel.invokeMethod<void>('changeCamera', <String, dynamic>{
        'type': cameraType.index.toString(),
      });
    } catch (e) {
      throw Exception("Unable to change the camera [Change Camera]");
    }
  }

  /// Requests camera and microphone permissions necessary for broadcasting.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the permissions were granted.
  /// Returns `false` if permissions are denied or if an error occurs during the permission request.
  @override
  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.camera,
        Permission.microphone,
      ];
      await permissions.request();
      final cameraPermission = await Permission.camera.status;
      final microphonePermission = await Permission.microphone.status;
      if (cameraPermission.isGranted && microphonePermission.isGranted) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Starts the broadcast.
  ///
  /// Throws an [Exception] if starting the broadcast fails.
  @override
  Future<void> startBroadcast() async {
    try {
      await methodChannel.invokeMethod("startBroadcast");
    } catch (e) {
      throw Exception("$e [Start Broadcast]");
    }
  }

  /// Starts the camera preview for the broadcast with the specified settings.
  ///
  /// * [imgset]: The image set identifier for the broadcast.
  /// * [streamKey]: The stream key for the broadcast.
  /// * [quality]: The desired broadcast quality, default is [IvsQuality.q720].
  /// * [cameraType]: The camera to use for the preview, default is [CameraType.BACK].
  /// * [onData]: A callback function to handle real-time data from the event stream.
  /// * [onError]: A callback function to handle errors from the event stream.
  ///
  /// Throws an [Exception] if the preview cannot start due to missing permissions, invalid parameters, or native platform issues.
  @override
  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    IvsQuality quality = IvsQuality.q720,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  }) async {
    try {
      // Request permissions before starting the preview.
      final permissionStatus = await requestPermissions();
      if (!permissionStatus) {
        throw Exception(
          "Please Grant Camera and Microphone Permission [Start Preview]",
        );
      }
      // Ensure imgset and streamKey are not empty.
      if (imgset.isEmpty || streamKey.isEmpty) {
        throw Exception('imgset or streamKey is empty [Start Preview]');
      }
      // Invoke the native platform method to start the preview.
      await methodChannel.invokeMethod<void>('startPreview', <String, dynamic>{
        'imgset': imgset,
        'streamKey': streamKey,
        'cameraType': cameraType.index.toString(),
        "quality": quality.description,
      });
      // Cancel any existing event stream before starting a new one.
      try {
        eventStream?.cancel();
      } catch (e) {
        log("Error Cancelling Event Stream: $e");
      }
      // Start listening to the event stream for real-time data and errors.
      eventStream = eventChannel
          .receiveBroadcastStream()
          .listen(onData, onError: onError);
    } catch (e) {
      throw Exception("$e [Start Preview]");
    }
  }

  /// Stops the ongoing broadcast.
  ///
  /// Throws an [Exception] if stopping the broadcast fails.
  @override
  Future<void> stopBroadcast() async {
    try {
      await methodChannel.invokeMethod<void>('stopBroadcast');
    } catch (e) {
      throw Exception("$e [Stop Broadcast]");
    }
  }

  /// Zooms the camera to the specified zoom level.
  ///
  /// * [zoomValue]: The zoom level to set, typically between 1.0 (no zoom) and the maximum zoom level supported by the device.
  ///
  /// Returns a [Future] that completes with the result of the zoom operation.
  /// Throws an [Exception] if the zoom operation fails.
  @override
  Future<dynamic> zoomCamera(double zoomValue) async {
    try {
      return await methodChannel
          .invokeMethod<void>("zoomCamera", <String, dynamic>{
        'zoom': zoomValue,
      });
    } catch (e) {
      throw Exception("$e [Zoom Camera]");
    }
  }

  @override
  Future<bool> isMuted() async {
    try {
      return await methodChannel.invokeMethod<bool>("isMuted") ?? false;
    } catch (e) {
      throw Exception("$e [Zoom Camera]");
    }
  }

  @override
  Future<void> toggleMute() async {
    try {
      return await methodChannel.invokeMethod<void>("mute");
    } catch (e) {
      throw Exception("$e [Zoom Camera]");
    }
  }

  @override
  Future<String?> updateCameraLens(IOSCameraLens cameraLens) async {
    try {
      return await methodChannel
          .invokeMethod<String>("updateCameraLens", <String, dynamic>{
        'lens': cameraLens.index.toString(),
      });
    } catch (e) {
      throw Exception("$e [Update Camera Lens]");
    }
  }

  @override
  Future<List<IOSCameraLens>> getAvailableCameraLens() async {
    try {
      final List<dynamic>? lensList = await methodChannel
          .invokeMethod<List<dynamic>>("getAvailableCameraLens");
      if (lensList != null) {
        return lensList.map((e) => IOSCameraLens.values[e]).toList();
      }
      return [];
    } catch (e) {
      throw Exception("$e [Get Available Camera Lens]");
    }
  }

  @override
  Future<ZoomFactor> getZoomFactor() async {
    try {
      final Map<Object?, Object?>? zoomFactorMap = await methodChannel
          .invokeMethod<Map<Object?, Object?>>("getCameraZoomFactor");
      if (zoomFactorMap != null) {
        return ZoomFactor.fromMap(Map<String, dynamic>.from(zoomFactorMap));
      }
      return ZoomFactor(maxZoom: 0, minZoom: 0);
    } catch (e) {
      throw Exception("$e [Get Zoom Factor]");
    }
  }

  @override
  Future<bool?> setFocusMode(FocusMode focusMode) async {
    try {
      return await methodChannel
          .invokeMethod<bool>("setFocusMode", <String, dynamic>{
        'type': focusMode.index.toString(),
      });
    } catch (e) {
      throw Exception("$e [Set Focus Mode]");
    }
  }

  @override
  Future<bool?> setFocusPoint(double x, double y) async {
    try {
      return await methodChannel
          .invokeMethod<bool>("setFocusPoint", <String, dynamic>{
        'dx': x.toString(),
        'dy': y.toString(),
      });
    } catch (e) {
      throw Exception("$e [Set Focus Point]");
    }
  }

  @override
  Future<void> captureVideo(int seconds) async {
    try {
      return await methodChannel.invokeMethod<void>(
        "captureVideo",
        <String, dynamic>{
          'seconds': seconds,
        },
      );
    } catch (e) {
      throw Exception("$e [Capture Video]");
    }
  }

  @override
  Future<void> stopVideoCapture() async {
    try {
      await methodChannel.invokeMethod("stopVideoCapture");
    } catch (e) {
      throw Exception("$e [Stop Video Capture]");
    }
  }
}
