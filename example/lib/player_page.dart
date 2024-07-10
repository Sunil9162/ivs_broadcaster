import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/ivs_player.dart';

import 'main.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late IvsPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = IvsPlayer.instance;
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _player.startPlayer(playBackUrl);
        setState(() {
          _player.initPreview();
        });
      },
    );
  }

  @override
  void dispose() {
    _player.stopPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Transform.flip(
        flipX: true,
        child: RotatedBox(
          quarterTurns: 1,
          child: _player.player,
        ),
      ),
    );
  }
}
