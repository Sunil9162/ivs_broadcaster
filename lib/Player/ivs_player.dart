// ignore_for_file: constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/Player/ivs_player_interface.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';
import 'package:ivs_broadcaster/helpers/strings.dart';

class IvsPlayer {
  IvsPlayer._();
  static final IvsPlayer instance = IvsPlayer._();
  factory IvsPlayer() {
    return instance;
  }

  final _controller = IvsPlayerInterface.instance;

  StreamController<Duration> positionStream = StreamController.broadcast();
  StreamController<Duration> syncTimeStream = StreamController.broadcast();
  StreamController<Duration> durationStream = StreamController.broadcast();
  StreamController<String> qualityStream = StreamController.broadcast();
  StreamController<PlayerState> playeStateStream = StreamController.broadcast();
  StreamController<String> errorStream = StreamController.broadcast();
  StreamController<bool> isAutoQualityStream = StreamController.broadcast();

  StreamSubscription? _positionStreamSubs;

  void muteUnmute() {
    _controller.muteUnmute();
  }

  void pause() {
    _controller.pause();
  }

  void resume() {
    _controller.resume();
  }

  void startPlayer(String url, {bool autoPlay = true}) {
    _controller.startPlayer(
      url,
      autoPlay: autoPlay,
      onData: (data) async {
        final Map<String, dynamic> parsedData = Map<String, dynamic>.from(data);
        if (parsedData.containsKey(AppStrings.state)) {
          final value = parsedData[AppStrings.state];
          playeStateStream.add(PlayerState.values[value]);
        } else if (parsedData.containsKey(AppStrings.quality)) {
          final value = parsedData[AppStrings.quality];
          qualityStream.add(value);
          isAutoQualityStream.add(await isAutoQuality());
        } else if (parsedData.containsKey(AppStrings.duration)) {
          final value = parsedData[AppStrings.duration];
          final duration = double.tryParse(value.toString());
          durationStream.add(
            Duration(
              seconds: (duration?.isFinite ?? false) ? duration!.toInt() : 0,
            ),
          );
          getQualities();
        } else if (parsedData.containsKey(AppStrings.syncTime)) {
          final value = parsedData[AppStrings.syncTime];
          syncTimeStream
              .add(Duration(seconds: double.parse(value.toString()).toInt()));
        } else if (parsedData.containsKey(AppStrings.error)) {
          final value = parsedData[AppStrings.error];
          errorStream.add(value);
        }
      },
      onError: (error) {},
    );
    _positionStreamSubs?.cancel();
    _positionStreamSubs = Stream.periodic(
      const Duration(milliseconds: 100),
    ).listen(
      (event) async {
        positionStream.add(await _controller.getPosition());
      },
    );
  }

  void stopPlayer() async {
    _controller.stopPlayer();
    _positionStreamSubs?.cancel();
    _positionStreamSubs = null;
  }

  /// Qualities
  final qualities = ValueNotifier<List<String>>([]);

  Future<void> getQualities() async {
    qualities.value = (await _controller.getQualities()).toSet().toList();
  }

  Future<void> setQuality(String value) async {
    await _controller.setQuality(value);
    isAutoQualityStream.add(await isAutoQuality());
  }

  Future<void> toggleAutoQuality() async {
    await _controller.toggleAutoQuality();
    isAutoQualityStream.add(await isAutoQuality());
  }

  Future<bool> isAutoQuality() async {
    return await _controller.isAutoQuality();
  }

  Future<void> seekTo(Duration duration) async {
    await _controller.seekTo(duration);
  }
}
