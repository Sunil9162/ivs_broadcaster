// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ivs_broadcaster/Broadcaster/Classes/video_capturing_model.dart';
import 'package:ivs_broadcaster/Broadcaster/Widgets/preview_widget.dart';
import 'package:ivs_broadcaster/Broadcaster/ivs_broadcaster.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // String key = "sk_us-east-************************************";
  // String url = "rtmps:-***************************************";
  String key = "sk_us-east-1_rDaEh55crJgC_JuCoeGBlcRIa1qnlkirfuwjSjuNKmy";
  String url = "rtmps://7453a0e95db4.global-contribute.live-video.net:443/app/";

  IvsBroadcaster? ivsBroadcaster;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
    ]);
    ivsBroadcaster = IvsBroadcaster.instance;
    ivsBroadcaster!.broadcastState.stream.listen((event) {
      log(event.name.toString(), name: "IVS Broadcaster");
    });
    ivsBroadcaster!.broadcastQuality.stream.listen((event) {
      log(event.name.toString(), name: "IVS Broadcaster Quality");
    });
    ivsBroadcaster!.broadcastHealth.stream.listen((event) {
      log(event.name.toString(), name: "IVS Broadcaster Health");
    });
    init();
  }

  @override
  void dispose() {
    ivsBroadcaster?.stopBroadcast();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  init() async {
    await Future.delayed(Durations.extralong4);
    await ivsBroadcaster!.startPreview(
      imgset: url,
      streamKey: key,
      quality: IvsQuality.q1080,
      autoReconnect: true,
    );
    final zoomFactor = await ivsBroadcaster?.getZoomFactor();
    if (zoomFactor != null) {
      maxZoom = zoomFactor.maxZoom.toDouble();
      minZoom = zoomFactor.minZoom.toDouble();
    }
  }

  double _scale = 1.0;
  double _previousScale = 1.0;
  double minZoom = 1.0; // Minimum zoom level
  double maxZoom = 4.0; // Maximum zoom level
  IvsQuality quality = IvsQuality.q1080;

  Future<void> _zoomCamera(double scale) async {
    // Call your zoom function here
    await ivsBroadcaster?.zoomCamera(scale);
  }

  ValueNotifier<IOSCameraLens> currentCamera =
      ValueNotifier(IOSCameraLens.DefaultCamera);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('IVS Broadcaster'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.5),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Center(
            child: CircularProgressIndicator(),
          ),
          GestureDetector(
            onScaleStart: (ScaleStartDetails details) {
              _previousScale = _scale;
              log("Started $_previousScale");
            },
            onScaleUpdate: (ScaleUpdateDetails details) async {
              _scale = (_previousScale * details.scale).clamp(minZoom, maxZoom);
              _zoomCamera(_scale);
            },
            child: const BroadcaterPreview(),
          ),
          Positioned(
            height: 150,
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<BroadCastState>(
              stream: ivsBroadcaster?.broadcastState.stream,
              builder: (context, snapshot) {
                final isConnected = snapshot.data == BroadCastState.CONNECTED;
                final isConnecting = snapshot.data == BroadCastState.CONNECTING;
                return Container(
                  height: 150,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                  ),
                  padding: const EdgeInsets.all(15).copyWith(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Connection State: ${snapshot.data?.name.toString() ?? "No State"}",
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            FutureBuilder<List<IOSCameraLens>>(
                              future: ivsBroadcaster?.getAvailableCameraLens(),
                              builder: (context, snapshot) {
                                return ValueListenableBuilder(
                                  valueListenable: currentCamera,
                                  builder: (context, value, child) {
                                    if (snapshot.connectionState !=
                                        ConnectionState.done) {
                                      return const CupertinoActivityIndicator();
                                    }
                                    return DropdownMenu<IOSCameraLens>(
                                      dropdownMenuEntries: snapshot.data
                                              ?.map(
                                                (e) => DropdownMenuEntry(
                                                  value: e,
                                                  label: e.name,
                                                ),
                                              )
                                              .toList() ??
                                          [],
                                      initialSelection: value,
                                      inputDecorationTheme:
                                          const InputDecorationTheme(
                                        border: OutlineInputBorder(),
                                      ),
                                      onSelected: (selectedValue) async {
                                        if (selectedValue != null) {
                                          final data = await ivsBroadcaster
                                              ?.updateCameraLens(selectedValue);
                                          // Only update currentCamera if the configuration was successful
                                          if (data == "Configuration Updated") {
                                            currentCamera.value = selectedValue;
                                            showSnackBar(
                                              context,
                                              "Camera configuration updated",
                                            );
                                          } else {
                                            // Handle failure case here if necessary
                                            currentCamera.value =
                                                IOSCameraLens.DefaultCamera;
                                            showSnackBar(
                                              context,
                                              "Device does not support this camera configuration",
                                            );
                                          }
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () async {
                          await ivsBroadcaster?.captureVideo(
                            seconds: 10,
                          );
                        },
                        child: StreamBuilder<VideoCapturingModel>(
                          stream: ivsBroadcaster?.onVideoCapturingStream.stream,
                          builder: (context, snapshot) {
                            final isCapturing =
                                snapshot.data?.isRecording ?? false;
                            if (snapshot.data?.videoPath != null) {
                              print(snapshot.data?.videoPath);
                            }
                            return CircleAvatar(
                              radius: 35,
                              backgroundColor: isCapturing
                                  ? Colors.green
                                  : Colors.black.withOpacity(0.5),
                              child: isCapturing
                                  ? const Icon(
                                      Icons.stop_rounded,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.fiber_manual_record_sharp,
                                      color: Colors.white,
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () async {
                          if (isConnected) {
                            await ivsBroadcaster?.stopBroadcast();
                            return;
                          }
                          await ivsBroadcaster?.startPreview(
                            imgset: url,
                            streamKey: key,
                            quality: quality,
                          );
                          await ivsBroadcaster?.startBroadcast();
                        },
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor:
                              isConnected ? Colors.green : Colors.red,
                          child: isConnecting
                              ? const CupertinoActivityIndicator()
                              : isConnected
                                  ? const Icon(
                                      Icons.stop_rounded,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      Icons.fiber_manual_record_sharp,
                                      color: Colors.white,
                                    ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          StreamBuilder<Offset>(
            stream: ivsBroadcaster?.focusPoint.stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? const Offset(0, 0);
              log(value.toString());
              return FutureBuilder<bool>(
                future: Future.delayed(const Duration(seconds: 2))
                    .then((value) => false),
                builder: (context, showBox) {
                  final show = showBox.connectionState == ConnectionState.done
                      ? false
                      : true;
                  return Positioned(
                    top: value.dy - 25,
                    left: value.dx - 25,
                    child: AnimatedContainer(
                      duration: Durations.short4,
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: show
                              ? Colors.white.withOpacity(0.5)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  showSnackBar(BuildContext content, String message) {
    ScaffoldMessenger.of(content).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
