import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/Broadcaster/Widgets/preview_widget.dart';
import 'package:ivs_broadcaster/Broadcaster/ivs_broadcaster.dart';
import 'package:ivs_broadcaster/helpers/enums.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String key = "sk_us-east-************************************";
  String url = "rtmps:-***************************************";

  IvsBroadcaster? ivsBroadcaster;

  @override
  void initState() {
    super.initState();
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
    ivsBroadcaster!.stopBroadcast();
    super.dispose();
  }

  init() async {
    // await Future.delayed(Durations.extralong4);

    await ivsBroadcaster!.startPreview(
      imgset: url,
      streamKey: key,
      quality: IvsQuality.q360,
    );
  }

  double _scale = 1.0;
  double _previousScale = 1.0;
  double minZoom = 1.0; // Minimum zoom level
  double maxZoom = 4.0; // Maximum zoom level

  Future<void> _zoomCamera(double scale) async {
    // Call your zoom function here
    final v = await ivsBroadcaster?.zoomCamera(scale);
    if (v != null) {
      maxZoom = v["max"] ?? 4.0; // Update maxZoom if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 150,
        title: Wrap(
          children: [
            // Start Broadcast
            ElevatedButton(
              onPressed: () async {
                await ivsBroadcaster?.startBroadcast();
              },
              child: const Text('Start Broadcast'),
            ),
            // Stop Broadcast
            ElevatedButton(
              onPressed: () async {
                await ivsBroadcaster?.stopBroadcast();
              },
              child: const Text('Stop Broadcast'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ivsBroadcaster?.changeCamera(CameraType.FRONT);
              },
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ivsBroadcaster!.startPreview(imgset: url, streamKey: key);
              },
              child: const Text('Start preview'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: null,
        label: StreamBuilder<BroadCastState>(
          stream: ivsBroadcaster?.broadcastState.stream,
          builder: (context, snapshot) {
            return Text(
              snapshot.data?.name ?? 'INVALID',
            );
          },
        ),
      ),
      body: GestureDetector(
        onScaleStart: (ScaleStartDetails details) {
          _previousScale = _scale;
        },
        onScaleUpdate: (ScaleUpdateDetails details) async {
          _scale = (_previousScale * details.scale).clamp(minZoom, maxZoom);
          log("Scale value is $_scale and detail scale ${details.scale} previous scale $_previousScale");

          // Call the zoom function if needed
          _zoomCamera(_scale);
        },
        onScaleEnd: (ScaleEndDetails details) {
          // Optional: Reset or finalize the zoom scale if needed
        },
        child: const BroadcaterPreview(),
      ),
    );
  }
}
