import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/ivs_broadcaster.dart';
import 'package:ivs_broadcaster_example/home_page.dart';

import 'player_page.dart';

const String playBackUrl =
    "https://7453a0e95db4.us-east-1.playback.live-video.net/api/video/v1/us-east-1.655758237974.channel.TkU9oEEBXbzE.m3u8";
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BroadCastWidget(),
    );
  }
}

class BroadCastWidget extends StatefulWidget {
  const BroadCastWidget({
    super.key,
  });

  @override
  State<BroadCastWidget> createState() => _BroadCastWidgetState();
}

class _BroadCastWidgetState extends State<BroadCastWidget> {
  IvsBroadcaster? ivsBroadcaster;

  @override
  void initState() {
    super.initState();
    ivsBroadcaster = IvsBroadcaster.instance;
    ivsBroadcaster!.broadcastStateController.stream.listen((event) {
      log(event.name.toString(), name: "IVS Broadcaster");
    });
    // controller = CameraController(cameras[0], ResolutionPreset.medium)
    //   ..initialize().then((_) {
    //     if (!mounted) {
    //       return;
    //     }
    //     setState(() {});
    //   });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Row(),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      ivsBroadcaster: ivsBroadcaster,
                    ),
                  ),
                );
              },
              // child: controller.value.isInitialized
              //     ? CameraPreview(controller)
              //     : const SizedBox()),
              child: const Text('Start Broadcast'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerPage(),
                  ),
                );
              },
              // child: controller.value.isInitialized
              //     ? CameraPreview(controller)
              //     : const SizedBox()),
              child: const Text('Start Player'),
            ),
          ],
        ),
      ),
    );
  }
}
