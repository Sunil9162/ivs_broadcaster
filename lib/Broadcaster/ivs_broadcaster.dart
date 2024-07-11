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
    CameraType cameraType = CameraType.BACK,
  }) async {
    return await broadcater.startPreview(
      imgset: imgset,
      streamKey: streamKey,
      cameraType: cameraType,
      onData: (data) {
        broadcastState.add(_parseBroadCastState(data.toString()));
      },
      onError: (error) {
        broadcastState.addError(error.toString());
      },
    );
  }

  Future<void> stopBroadcast() {
    return broadcater.stopBroadcast();
  }
}
