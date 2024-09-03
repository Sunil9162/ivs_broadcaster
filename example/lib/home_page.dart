// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
    super.dispose();
  }

  init() async {
    await Future.delayed(Durations.extralong4);
    await ivsBroadcaster!.startPreview(
      imgset: url,
      streamKey: key,
      quality: IvsQuality.q1080,
    );
  }

  double _scale = 1.0;
  double _previousScale = 1.0;
  double minZoom = 1.0; // Minimum zoom level
  double maxZoom = 4.0; // Maximum zoom level
  IvsQuality quality = IvsQuality.q1080;

  Future<void> _zoomCamera(double scale) async {
    // Call your zoom function here
    final v = await ivsBroadcaster?.zoomCamera(scale);
    if (v != null) {
      maxZoom = v["max"] ?? 4.0; // Update maxZoom if needed
    }
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
        // toolbarHeight: 150,
        // title: Wrap(
        //   children: [
        //     // Start Broadcast
        //     ElevatedButton(
        //       onPressed: () async {
        //         await ivsBroadcaster?.startBroadcast();
        //       },
        //       child: const Text('Start Broadcast'),
        //     ),
        //     // Stop Broadcast
        //     ElevatedButton(
        //       onPressed: () async {
        //         await ivsBroadcaster?.stopBroadcast();
        //       },
        //       child: const Text('Stop Broadcast'),
        //     ),
        //     ElevatedButton(
        //       onPressed: () async {
        //         await ivsBroadcaster?.changeCamera(CameraType.FRONT);
        //       },
        //       child: const Text('Change'),
        //     ),
        //     ElevatedButton(
        //       onPressed: () async {
        //         await ivsBroadcaster!.startPreview(imgset: url, streamKey: key);
        //       },
        //       child: const Text('Start preview'),
        //     ),
        //   ],
        // ),
      ),
      extendBodyBehindAppBar: true,
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: null,
      //   label: StreamBuilder<BroadCastState>(
      //     stream: ivsBroadcaster?.broadcastState.stream,
      //     builder: (context, snapshot) {
      //       return Text(
      //         snapshot.data?.name ?? 'INVALID',
      //       );
      //     },
      //   ),
      // ),
      body: Stack(
        children: [
          const Center(
            child: CircularProgressIndicator(),
          ),
          GestureDetector(
            onScaleStart: (ScaleStartDetails details) {
              _previousScale = _scale;
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                            ValueListenableBuilder(
                              valueListenable: currentCamera,
                              builder: (context, value, child) {
                                return DropdownMenu(
                                  dropdownMenuEntries: IOSCameraLens.values
                                      .map(
                                        (e) => DropdownMenuEntry(
                                          value: e,
                                          label: e.name,
                                        ),
                                      )
                                      .toList(),
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
                            ),
                          ],
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
