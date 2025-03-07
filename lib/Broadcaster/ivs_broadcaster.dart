// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Broadcaster/Classes/video_capturing_model.dart';
import 'package:ivs_broadcaster/Broadcaster/Classes/zoom_factor.dart';
import 'package:ivs_broadcaster/Broadcaster/ivs_broadcaster_platform_interface.dart';

import '../helpers/enums.dart';

/// A singleton class that manages the IVS (Interactive Video Service) broadcasting.
/// It interfaces with the platform-specific broadcaster implementations to handle
/// broadcasting, camera operations, and streaming settings.
class IvsBroadcaster {
  // Private constructor for the singleton pattern.
  IvsBroadcaster._();

  /// The single instance of [IvsBroadcaster].
  static final IvsBroadcaster instance = IvsBroadcaster._();

  /// A factory constructor that returns the single instance of [IvsBroadcaster].
  factory IvsBroadcaster() {
    return instance;
  }

  /// A stream controller to handle the broadcast state events.
  StreamController<BroadCastState> broadcastState =
      StreamController<BroadCastState>.broadcast();

  /// A stream controller to handle the broadcast retry State.
  StreamController<RetryState> retryState =
      StreamController<RetryState>.broadcast();

  /// A stream controller to handle the broadcast quality events.
  StreamController<BroadcastQuality> broadcastQuality =
      StreamController<BroadcastQuality>.broadcast();

  /// A stream controller to handle the broadcast health events.
  StreamController<BroadcastHealth> broadcastHealth =
      StreamController<BroadcastHealth>.broadcast();

  /// Focus Point Stream Controller
  StreamController<Offset> focusPoint = StreamController<Offset>.broadcast();

  /// An instance of the platform-specific broadcaster.
  final broadcater = IvsBroadcasterPlatform.instance;

  /// Parses the raw broadcast state received from the platform-specific implementation
  /// and maps it to the [BroadCastState] enum.
  ///
  /// * [state]: A string representing the broadcast state.
  ///
  /// Returns a [BroadCastState] value corresponding to the given state.
  BroadCastState _parseBroadCastState(String state) {
    switch (state) {
      case 'INVALID':
        return BroadCastState.INVALID;
      case 'DISCONNECTED':
        return BroadCastState.DISCONNECTED;
      case 'CONNECTING':
        return BroadCastState.CONNECTING;
      case 'CONNECTED':
        return BroadCastState.CONNECTED;
      case 'ERROR':
        return BroadCastState.ERROR;
      default:
        return BroadCastState.INVALID;
    }
  }

  /// Parses the raw data received from the platform-specific implementation
  /// and adds it to the appropriate stream controller.
  ///
  /// * [data]: A dynamic object that could be a Map containing state, quality, and network information.
  void _parseRawData(dynamic data) {
    if (data is Map) {
      if (data.containsKey("state")) {
        broadcastState.add(_parseBroadCastState(data["state"]));
      }

      final settings = data;
      if (settings.containsKey("quality")) {
        broadcastQuality.add(
          BroadcastQuality.values[settings["quality"] as int],
        );
      }
      if (settings.containsKey("retrystate")) {
        retryState.add(
          RetryState.values[settings["retrystate"] as int],
        );
      }
      if (settings.containsKey("network")) {
        broadcastHealth.add(
          BroadcastHealth.values[settings["network"] as int],
        );
      }
      if (settings.containsKey("foucsPoint")) {
        final data = settings["foucsPoint"].toString().split("_");
        final offset = Offset(double.parse(data[0]), double.parse(data[1]));
        focusPoint.add(offset);
      }
      if (settings.containsKey('isRecording')) {
        onVideoCapturingStream.add(
          VideoCapturingModel(
            isRecording: settings['isRecording'],
            videoPath: settings['videoPath'],
          ),
        );
      }
    }
  }

  /// Switches the camera to the specified [CameraType].
  ///
  /// * [cameraType]: The camera to switch to, either [CameraType.FRONT] or [CameraType.BACK].
  ///
  /// Returns a [Future] that completes when the camera has been changed.
  Future<void> changeCamera(CameraType cameraType) {
    return broadcater.changeCamera(cameraType);
  }

  /// Requests the necessary permissions for broadcasting.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the permissions were granted.
  Future<bool> requestPermissions() async {
    return await broadcater.requestPermissions();
  }

  /// Starts the broadcast.
  ///
  /// Returns a [Future] that completes when the broadcast has started.
  Future<void> startBroadcast() {
    return broadcater.startBroadcast();
  }

  /// Starts the camera preview for the broadcast with the specified settings.
  ///
  /// * [imgset]: The image set identifier for the broadcast.
  /// * [streamKey]: The stream key for the broadcast.
  /// * [quality]: The desired broadcast quality, default is [IvsQuality.q720].
  /// * [cameraType]: The camera to use for the preview, default is [CameraType.BACK].
  ///
  /// Returns a [Future] that completes when the preview has started.
  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    IvsQuality quality = IvsQuality.q720,
    CameraType cameraType = CameraType.BACK,
    bool autoReconnect = false,
  }) async {
    return await broadcater.startPreview(
      imgset: imgset,
      streamKey: streamKey,
      cameraType: cameraType,
      quality: quality,
      autoReconnect: autoReconnect,
      onData: (data) {
        _parseRawData(data);
      },
      onError: (error) {
        // Handle error scenarios here, if needed.
      },
    );
  }

  /// Stops the ongoing broadcast.
  ///
  /// Returns a [Future] that completes when the broadcast has stopped.
  Future<void> stopBroadcast() {
    return broadcater.stopBroadcast();
  }

  /// Zooms the camera to the specified zoom level.
  ///
  /// * [zoomValue]: The zoom level to set, typically between 1.0 (no zoom) and the maximum zoom level supported by the device.
  ///
  /// Returns a [Future] that completes with the result of the zoom operation.
  Future<dynamic> zoomCamera(double zoomValue) {
    return broadcater.zoomCamera(zoomValue);
  }

  /// Checks if the broadcaster is muted.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the broadcaster is muted.
  Future<bool> isMuted() {
    return broadcater.isMuted();
  }

  /// Toggles the mute state of the broadcaster.
  ///
  /// Returns a [Future] that completes when the mute state has been toggled.
  Future<void> toggleMute() {
    return broadcater.toggleMute();
  }

  /// Updates the camera lens to the specified [IOSCameraLens].
  ///
  /// * [cameraLens]: The camera lens to switch to.
  ///
  /// Returns a [Future] that completes with a string indicating the result of the operation.
  Future<String?> updateCameraLens(IOSCameraLens cameraLens) {
    return broadcater.updateCameraLens(cameraLens);
  }

  /// Gets the current zoom factor of the camera.
  ///
  /// Returns a [Future] that completes with the current [ZoomFactor].
  Future<ZoomFactor?> getZoomFactor() async {
    return await broadcater.getZoomFactor();
  }

  /// Gets the available camera lenses.
  ///
  /// Returns a [Future] that completes with a list of available [IOSCameraLens].
  Future<List<IOSCameraLens>> getAvailableCameraLens() async {
    return await broadcater.getAvailableCameraLens();
  }

  /// Sets the focus mode of the camera.
  ///
  /// * [focusMode]: The focus mode to set.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the focus mode was set successfully.
  Future<bool?> setFocusMode(FocusMode focusMode) async {
    return await broadcater.setFocusMode(focusMode);
  }

  /// Sets the focus point of the camera.
  ///
  /// * [x]: The x-coordinate of the focus point.
  /// * [y]: The y-coordinate of the focus point.
  ///
  /// Returns a [Future] that completes with a boolean indicating whether the focus point was set successfully.
  Future<bool?> setFocusPoint(double x, double y) async {
    return await broadcater.setFocusPoint(x, y);
  }

  /// Captures a video for the specified number of seconds.
  ///
  /// * [seconds]: The duration of the video capture in seconds, default is 30 seconds.
  ///
  /// Returns a [Future] that completes when the video capture has started.
  Future<void> captureVideo({int seconds = 30}) async {
    return await broadcater.captureVideo(seconds);
  }

  /// A stream controller to handle video capturing events.
  StreamController<VideoCapturingModel> onVideoCapturingStream =
      StreamController<VideoCapturingModel>.broadcast();

  /// Stops the ongoing video capture.
  ///
  /// Returns a [Future] that completes when the video capture has stopped.
  Future<void> stopVideoCapture() async {
    await broadcater.stopVideoCapture();
  }
}
