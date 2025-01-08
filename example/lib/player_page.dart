import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final player1 =
      "https://4c62a87c1810.us-west-2.playback.live-video.net/api/video/v1/us-west-2.049054135175.channel.TgUC9BcpWMIK.m3u8?player_version=1.19.0";
  final player2 =
      "https://4c62a87c1810.us-west-2.playback.live-video.net/api/video/v1/us-west-2.049054135175.channel.vz7GFGP6M3xJ.m3u8?player_version=1.19.0";
  final player3 =
      "https://4c62a87c1810.us-west-2.playback.live-video.net/api/video/v1/us-west-2.049054135175.channel.7hL7yiiFH0Q1.m3u8?player_version=1.19.0";
  final player4 =
      "https://4c62a87c1810.us-west-2.playback.live-video.net/api/video/v1/us-west-2.049054135175.channel.NUiimXpVUGyr.m3u8?player_version=1.19.0";

  @override
  void initState() {
    _player = IvsPlayer.instance;
    super.initState();
    urlController.text =
        "https://4c62a87c1810.us-west-2.playback.live-video.net/api/video/v1/us-west-2.049054135175.channel.JmLwVqcdvTLO.m3u8";
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _player.multiPlayer([
          player1,
          player2,
          player3,
          player4,
        ]);
      },
    );
  }

  @override
  void dispose() {
    _player.stopPlayer();
    super.dispose();
  }

  ValueNotifier<bool> isFullScreen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ValueListenableBuilder(
              valueListenable: isFullScreen,
              builder: (context, value, child) {
                return Stack(
                  fit: value ? StackFit.expand : StackFit.loose,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Transform.rotate(
                        angle: 0,
                        child: IvsPlayerView(
                          controller: _player,
                        ),
                      ),
                    ),
                    if (!value)
                      Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: urlController,
                                            decoration: const InputDecoration(
                                              labelText: "Url",
                                              enabledBorder:
                                                  OutlineInputBorder(),
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
                                              valueListenable:
                                                  _player.qualities,
                                              builder: (context, value, child) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child:
                                                      DropdownButtonFormField(
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: "Quality",
                                                      enabledBorder:
                                                          OutlineInputBorder(),
                                                      border:
                                                          OutlineInputBorder(),
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
                                                      _player
                                                          .setQuality(value!);
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
                                            stream: _player
                                                .isAutoQualityStream.stream,
                                            builder: (context, value) {
                                              return Switch(
                                                value: value.data ?? false,
                                                onChanged: (newvalue) async {
                                                  await _player
                                                      .toggleAutoQuality();
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
                                              stream:
                                                  _player.positionStream.stream,
                                              builder: (context, position) {
                                                return Slider(
                                                  onChanged: (value) {
                                                    _player.seekTo(Duration(
                                                        seconds:
                                                            value.toInt()));
                                                  },
                                                  value: position
                                                          .data?.inSeconds
                                                          .toDouble() ??
                                                      0,
                                                  min: 0,
                                                  max: getMax(
                                                            position.data,
                                                            duration.data,
                                                          ) <
                                                          1
                                                      ? 1
                                                      : getMax(
                                                          position.data,
                                                          duration.data,
                                                        ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      StreamBuilder<Duration>(
                                        stream: _player.durationStream.stream,
                                        builder: (context, snapshot) {
                                          if (snapshot.data == null ||
                                              snapshot.data!.inSeconds == 0) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(5),
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
                                  ListView.builder(
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        onTap: () async {
                                          final playerid = [
                                            player1,
                                            player2,
                                            player3,
                                            player4,
                                          ][index];
                                          _player.selectPlayer(playerid);
                                          // final image =
                                          //     await _player.getThumbnail(
                                          //   url: playerid,
                                          // );
                                          // if (context.mounted) {
                                          //   showDialog(
                                          //     context: context,
                                          //     builder: (context) {
                                          //       return AlertDialog(
                                          //         content: Image.memory(
                                          //           image,
                                          //         ),
                                          //       );
                                          //     },
                                          //   );
                                          // }
                                        },
                                        title: Text("Select Player $index"),
                                      );
                                    },
                                    itemCount: 4,
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                  ],
                );
              },
            ),
            Positioned(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    SystemChrome.setPreferredOrientations(
                      isFullScreen.value
                          ? [
                              DeviceOrientation.portraitUp,
                              DeviceOrientation.portraitDown,
                            ]
                          : [
                              DeviceOrientation.landscapeLeft,
                              DeviceOrientation.landscapeRight,
                            ],
                    );
                    isFullScreen.value = !isFullScreen.value;
                  },
                ),
              ),
            )
          ],
        ),
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
    if ((duration == null ||
            duration.inSeconds == 0 ||
            duration.inSeconds < 0) &&
        position?.inSeconds != 0) {
      return position?.inSeconds.toDouble() ?? 0.0;
    }
    return duration?.inSeconds.toDouble() ?? 0.0;
  }
}
