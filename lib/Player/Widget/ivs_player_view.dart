import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Player/ivs_player.dart';

class IvsPlayerView extends StatefulWidget {
  final IvsPlayer controller;
  final bool autoDispose;
  final double? aspectRatio;
  const IvsPlayerView({
    Key? key,
    required this.controller,
    this.autoDispose = true,
    this.aspectRatio,
  }) : super(key: key);

  @override
  State<IvsPlayerView> createState() => _IvsPlayerViewState();
}

class _IvsPlayerViewState extends State<IvsPlayerView> {
  IvsPlayer? _player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _player = widget.controller;
      },
    );
  }

  @override
  void dispose() {
    if (widget.autoDispose) {
      _player?.stopPlayer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: _getView(),
    );
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
}
