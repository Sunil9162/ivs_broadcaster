import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/ivs_player_abstract.dart';

class IvsPlayer extends PlayerControls {
  IvsPlayer._() {
    // initPreview();
  }
  static final IvsPlayer instance = IvsPlayer._();
  factory IvsPlayer() {
    return instance;
  }

  Widget? _preview;
  Widget get player =>
      _preview ??
      Container(
        color: Colors.black,
      );

  static const MethodChannel _methodChannel = MethodChannel("ivs_player");
  static const EventChannel _eventChannel = EventChannel("ivs_player_event");

  static StreamSubscription? playerState;

  initPreview() {
    _preview = _getView();
    log(_preview.runtimeType.toString());
  }

  Widget _getView() {
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: 'ivs_player',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'ivs_player',
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

  void _onData(dynamic data) {
    log("Player State: $data");
  }

  void _onError(Object error) {}

  @override
  void muteUnmute() {
    // TODO: implement muteUnmute
  }

  @override
  void pause() {
    // TODO: implement pause
  }

  @override
  void resume() {
    // TODO: implement resume
  }

  @override
  void startPlayer(String url) async {
    try {
      await _methodChannel.invokeMethod("startPlayer", {
        "url": url,
      });
      playerState = _eventChannel
          .receiveBroadcastStream()
          .listen(_onData, onError: _onError);
    } catch (e) {
      log(e.toString());
      throw Exception("Unable to Load Url");
    }
  }

  @override
  void stopPlayer() async {
    try {
      await _methodChannel.invokeMethod("stopPlayer");
    } catch (e) {
      throw Exception("Unable to Stop");
    }
  }
}
