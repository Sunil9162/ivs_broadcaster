import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/ivs_broadcaster.dart';

class HomePage extends StatefulWidget {
  final IvsBroadcaster? ivsBroadcaster;
  const HomePage({Key? key, this.ivsBroadcaster}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // String key = "sk_us-east-************************************";
  // String url = "rtmps:-***************************************";
  String key = "sk_us-east-1_UjZKSPgr268l_Hn1I1xDGr8PFYbSNGAeiyOkjm2tV8U";
  String url = "rtmps://e18918b433c0.global-contribute.live-video.net:443/app/";
  @override
  void initState() {
    super.initState();
    log("Home init called");
    init();
  }

  @override
  void dispose() {
    widget.ivsBroadcaster!.stopBroadcast();
    super.dispose();
  }

  init() async {
    // await Future.delayed(Durations.extralong4);
    await widget.ivsBroadcaster!.startPreview(imgset: url, streamKey: key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 100,
        title: Wrap(
          children: [
            // Start Broadcast
            ElevatedButton(
              onPressed: () async {
                await widget.ivsBroadcaster?.startPreview(
                  imgset: url,
                  streamKey: key,
                );
              },
              child: const Text('Start Broadcast'),
            ),
            // Stop Broadcast
            ElevatedButton(
              onPressed: () async {
                await widget.ivsBroadcaster?.stopBroadcast();
              },
              child: const Text('Stop Broadcast'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.ivsBroadcaster?.changeCamera();
              },
              child: const Text('Change'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.ivsBroadcaster!
                    .startPreview(imgset: url, streamKey: key);
              },
              child: const Text('Start preview'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          IvsBroadcaster.instance.changeCamera();
        },
        label: StreamBuilder<BroadCastState>(
          stream: widget.ivsBroadcaster?.broadcastStateController.stream,
          builder: (context, snapshot) {
            return Text(
              snapshot.data?.name ?? 'INVALID',
            );
          },
        ),
      ),
      body: widget.ivsBroadcaster?.previewWidget,
    );
  }
}
