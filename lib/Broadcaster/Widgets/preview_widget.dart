import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A stateful widget that provides a preview of the broadcaster view.
///
/// This widget renders a platform-specific view for the IVS broadcaster on Android and iOS.
/// It uses `AutomaticKeepAliveClientMixin` to ensure that the platform view is kept alive
/// and not destroyed when the widget is offscreen or when the widget tree rebuilds.
class BroadcaterPreview extends StatefulWidget {
  const BroadcaterPreview({super.key});

  @override
  State<BroadcaterPreview> createState() => _BroadcaterPreviewState();
}

class _BroadcaterPreviewState extends State<BroadcaterPreview>
    with AutomaticKeepAliveClientMixin {
  /// Holds the platform-specific view widget (either AndroidView or UiKitView).
  Widget? _platformView;

  @override
  void initState() {
    super.initState();
    // Initialize the platform view when the widget is first created.
    _initializePlatformView();
  }

  /// Initializes the platform-specific view depending on the current platform.
  ///
  /// This method checks the platform and creates either an [AndroidView] or [UiKitView].
  /// If the platform is not Android or iOS, it displays a message indicating that the platform is not supported.
  void _initializePlatformView() {
    if (Platform.isAndroid) {
      // Create an Android-specific view for the broadcaster.
      _platformView = const AndroidView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      // Create an iOS-specific view for the broadcaster.
      _platformView = const UiKitView(
        viewType: 'ivs_broadcaster',
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      // Display an error message if the platform is not supported.
      _platformView = const Center(
        child: Text(
          'Platform not supported',
          style: TextStyle(
            color: Colors.red,
            fontSize: 20,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Required for the AutomaticKeepAliveClientMixin to work.
    // Return the platform view if it was initialized, or an empty widget if not.
    return _platformView ?? const SizedBox.shrink();
  }

  @override
  bool get wantKeepAlive => true; // Keeps the widget alive when it's offscreen.
}
