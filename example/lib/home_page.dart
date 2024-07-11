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
    init();
  }

  @override
  void dispose() {
    ivsBroadcaster!.stopBroadcast();
    super.dispose();
  }

  init() async {
    // await Future.delayed(Durations.extralong4);
    await ivsBroadcaster!.startPreview(imgset: url, streamKey: key);
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
      body: const BroadcaterPreview(),
    );
  }
}
