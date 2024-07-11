import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BroadcaterPreview extends StatelessWidget {
  const BroadcaterPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return startPreview();
  }

  Widget startPreview() {
    if (Platform.isAndroid) {
      return const AndroidView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return const UiKitView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const Center(
      child: Center(
        child: Text(
          'Platform not supported',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}
