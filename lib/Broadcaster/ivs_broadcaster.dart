// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:ivs_broadcaster/Broadcaster/ivs_broadcaster_platform_interface.dart';

import '../helpers/enums.dart';

String ivsBroadcaster = "IVS Broadcaster";

class IvsBroadcaster {
  IvsBroadcaster._();
  static final IvsBroadcaster instance = IvsBroadcaster._();

  factory IvsBroadcaster() {
    return instance;
  }

  StreamController<BroadCastState> broadcastState =
      StreamController<BroadCastState>.broadcast();

  StreamController<BroadcastQuality> broadcastQuality =
      StreamController<BroadcastQuality>.broadcast();
  StreamController<BroadcastHealth> broadcastHealth =
      StreamController<BroadcastHealth>.broadcast();

  final broadcater = IvsBroadcasterPlatform.instance;

  _parseBroadCastState(String state) {
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

  _parseRawData(data) {
    if (data is Map) {
      if (data.containsKey("state")) {
        broadcastState.add(_parseBroadCastState(data["state"]));
      }
      // if (data.containsKey("settings")) {
      final settings = data;
      if (settings.containsKey("quality")) {
        broadcastQuality.add(
          BroadcastQuality.values[settings["quality"] as int],
        );
      }
      if (settings.containsKey("network")) {
        broadcastHealth.add(
          BroadcastHealth.values[settings["network"] as int],
        );
      }
      // }
    }
  }

  Future<void> changeCamera(CameraType cameraType) {
    return broadcater.changeCamera(cameraType);
  }

  Future<bool> requestPermissions() async {
    return await broadcater.requestPermissions();
  }

  Future<void> startBroadcast() {
    return broadcater.startBroadcast();
  }

  Future<void> startPreview({
    required String imgset,
    required String streamKey,
    IvsQuality quality = IvsQuality.q720,
    CameraType cameraType = CameraType.BACK,
  }) async {
    return await broadcater.startPreview(
      imgset: imgset,
      streamKey: streamKey,
      cameraType: cameraType,
      quality: quality,
      onData: (data) {
        _parseRawData(data);
      },
      onError: (error) {},
    );
  }

  Future<void> stopBroadcast() {
    return broadcater.stopBroadcast();
  }

  Future<dynamic> zoomCamera(double zoomValue) {
    return broadcater.zoomCamera(zoomValue);
  }
}
