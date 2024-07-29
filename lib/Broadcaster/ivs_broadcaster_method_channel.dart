import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ivs_broadcaster_platform_interface.dart';

class MethodChannelIvsBroadcaster extends IvsBroadcasterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('ivs_broadcaster');
  final eventChannel = const EventChannel("ivs_broadcaster_event");

  StreamSubscription? eventStream;

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

  @override
  Future<bool> requestPermissions() async {
    try {
      final persissions = [
        Permission.camera,
        Permission.microphone,
      ];
      await persissions.request();
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

  @override
  Future<void> startBroadcast() async {
    try {
      await methodChannel.invokeMethod("startBroadcast");
    } catch (e) {
      throw throw Exception("$e [Start Broadcast]");
    }
  }

  @override
  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    CameraType cameraType = CameraType.BACK,
    void Function(dynamic)? onData,
    void Function(dynamic)? onError,
  }) async {
    try {
      final permissionStatus = await requestPermissions();
      if (!permissionStatus) {
        throw Exception(
          "Please Grant Camera and Microphone Permsission [Start Preview]",
        );
      }
      if (imgset.isEmpty || streamKey.isEmpty) {
        throw Exception('imgset or streamKey is empty [Start Preview]');
      }
      await methodChannel.invokeMethod<void>('startPreview', <String, dynamic>{
        'imgset': imgset,
        'streamKey': streamKey,
        'cameraType': cameraType.index.toString(),
      });
      eventStream?.cancel();
      eventStream = eventChannel
          .receiveBroadcastStream()
          .listen(onData, onError: onError);
    } catch (e) {
      throw Exception("$e [Start Preview]");
    }
  }

  @override
  Future<void> stopBroadcast() async {
    try {
      await methodChannel.invokeMethod<void>('stopBroadcast');
    } catch (e) {
      throw Exception("$e [Stop Broadcast]");
    }
  }

  @override
  Future<void> setZoomLevel(int zoomLevel) {
    try {
      return methodChannel.invokeMethod<void>('applyzoom', <String, dynamic>{
        'zoom': zoomLevel,
      });
    } catch (e) {
      throw Exception("$e [Set Zoom Level]");
    }
  }
}
