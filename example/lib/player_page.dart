import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/Player/Widget/ivs_player_view.dart';
import 'package:ivs_broadcaster/Player/ivs_player.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late IvsPlayer _player;
  ValueNotifier<bool> autoPlay = ValueNotifier(true);
  final urlController = TextEditingController();

  @override
  void initState() {
    _player = IvsPlayer.instance;
    super.initState();
    urlController.text =
        "https://d35j504z0x2vu2.cloudfront.net/v1/manifest/0bc8e8376bd8417a1b6761138aa41c26c7309312/mastiii/ab2b6cce-f7be-4037-83f0-926cf111131e/2.m3u8";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          IvsPlayerView(
            controller: _player,
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: "Url",
                      enabledBorder: OutlineInputBorder(),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ElevatedButton(
                  child: const Text("Load"),
                  onPressed: () {
                    _player.startPlayer(
                      urlController.text,
                      autoPlay: autoPlay.value,
                    );
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Text(
                "Auto Play",
              ),
              ValueListenableBuilder<bool>(
                valueListenable: autoPlay,
                builder: (context, value, child) {
                  return Switch(
                    value: value,
                    onChanged: (newvalue) {
                      autoPlay.value = newvalue;
                    },
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<String>(
                  stream: _player.qualityStream.stream,
                  builder: (context, snapshot) {
                    return ValueListenableBuilder(
                      valueListenable: _player.qualities,
                      builder: (context, value, child) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButtonFormField(
                            decoration: const InputDecoration(
                              labelText: "Quality",
                              enabledBorder: OutlineInputBorder(),
                              border: OutlineInputBorder(),
                            ),
                            value: snapshot.data,
                            items: value.map(
                              (e) {
                                return DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.toString(),
                                  ),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              _player.setQuality(value!);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Column(
                children: [
                  const Text(
                    "Auto",
                  ),
                  StreamBuilder<bool>(
                    stream: _player.isAutoQualityStream.stream,
                    builder: (context, value) {
                      return Switch(
                        value: value.data ?? false,
                        onChanged: (newvalue) async {
                          await _player.toggleAutoQuality();
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          StreamBuilder<PlayerState>(
            stream: _player.playeStateStream.stream,
            builder: (context, snapshot) {
              return Text(
                "PlayerState: ${snapshot.data?.name.toString() ?? ""}",
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  child: const Text("Resume"),
                  onPressed: () {
                    _player.resume();
                  },
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  child: const Text("Pause"),
                  onPressed: () {
                    _player.pause();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              StreamBuilder<Duration>(
                stream: _player.positionStream.stream,
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return const Text("00:00");
                  }
                  return Text(
                    _printDuration(snapshot.data!),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.durationStream.stream,
                  builder: (context, duration) {
                    return StreamBuilder<Duration>(
                      stream: _player.positionStream.stream,
                      builder: (context, position) {
                        return Slider(
                          onChanged: (value) {
                            _player.seekTo(Duration(seconds: value.toInt()));
                          },
                          value: position.data?.inSeconds.toDouble() ?? 0,
                          min: 0,
                          max: getMax(position.data, duration.data),
                        );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<Duration>(
                stream: _player.durationStream.stream,
                builder: (context, snapshot) {
                  if (snapshot.data == null || snapshot.data!.inSeconds == 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "Live",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }
                  return Text(
                    _printDuration(snapshot.data!),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _printDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  double getMax(Duration? position, Duration? duration) {
    if (position == null && duration == null) {
      return 1;
    }
    if ((duration == null || duration.inSeconds == 0) &&
        position!.inSeconds != 0) {
      return position.inSeconds.toDouble();
    }
    return duration?.inSeconds.toDouble() ?? 0.0;
  }
}
