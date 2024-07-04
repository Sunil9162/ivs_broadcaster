// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

String ivsBroadcaster = "IVS Broadcaster";

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

class IvsBroadcaster {
  IvsBroadcaster._() {
    init();
  }
  static bool isReady = false;
  static final IvsBroadcaster instance = IvsBroadcaster._();

  // Factory constructor
  factory IvsBroadcaster() {
    return instance;
  }
  init() {
    log("Broadcaster Initialized", name: ivsBroadcaster);
    _preview = _getView();
    setupChannels();
  }

  // IvsBroadcaster() {
  //   broadcastStateController.add(BroadCastState.INVALID);
  // }

  StreamController<BroadCastState> broadcastStateController =
      StreamController<BroadCastState>.broadcast();

  // static IvsBroadcaster get instance {
  // return IvsBroadcaster();
  // if (isReady.value) {
  //   return Get.find<IvsBroadcaster>();
  // }
  // return Get.put(IvsBroadcaster(), permanent: true);
  // }

  EventChannel? _eventChannel;
  MethodChannel? _channel;
  Widget? _preview;
  Widget get previewWidget => _preview ?? const SizedBox();

  // @override
  // void onInit() {
  //   super.onInit();
  //   _preview = _getView();
  //   setupChannels();
  // }

  Widget _getView() {
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const Center(
      child: Center(
        child: Text(
          'Platform not supported',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void setupChannels() {
    _channel = const MethodChannel('ivs_broadcaster');
    _eventChannel = const EventChannel('ivs_broadcaster_event');
    isReady = true;
    requestPermissions();
  }

  void _onEvent(Object? event) {
    log('onEvent: $event', name: ivsBroadcaster);
    broadcastStateController.add(_parseBroadCastState(event.toString()));
  }

  void _onError(Object? error) {
    log('onError: $error', name: ivsBroadcaster);
  }

  Future<bool> requestPermissions() async {
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
  }

  Future<void> startBroadcast({
    required String imgset,
    required String streamKey,
    CameraType cameraType = CameraType.BACK,
  }) async {
    if (imgset.isEmpty || streamKey.isEmpty) {
      throw Exception('imgset or streamKey is empty');
    }

    _channel?.invokeMethod<void>('startBroadcast', <String, dynamic>{
      'imgset': imgset,
      'streamKey': streamKey,
      'cameraType': cameraType.index.toString(),
    });
    _eventChannel?.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  Future<void> stopBroadcast() async {
    await _channel?.invokeMethod<void>('stopBroadcast');
  }

  CameraType type = CameraType.FRONT;

  changeCamera() async {
    await _channel?.invokeMethod<void>('changeCamera', <String, dynamic>{
      'type': type.index.toString(),
    });
    type = type == CameraType.FRONT ? CameraType.BACK : CameraType.FRONT;
  }

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
}
