import 'package:flutter/material.dart';
import 'package:ivs_broadcaster/Player/ivs_player.dart';

/// [IvsPlayerView] is a stateful widget that provides a view for playing
/// Interactive Video Service (IVS) content. It handles platform-specific
/// rendering for Android and iOS, while offering an optional aspect ratio
/// and automatic disposal of the player.

class IvsPlayerView extends StatefulWidget {
  /// The controller that manages the IVS player instance.
  final IvsPlayer controller;

  /// Determines whether the player should be automatically disposed of when
  /// the widget is removed from the widget tree. Default is true.
  final bool autoDispose;

  /// The aspect ratio for the player view, defaults to 16:9 if not specified.
  final double? aspectRatio;

  /// Constructor for [IvsPlayerView]. Requires an [IvsPlayer] controller.
  const IvsPlayerView({
    Key? key,
    required this.controller,
    this.autoDispose = true,
    this.aspectRatio,
  }) : super(key: key);

  @override
  State<IvsPlayerView> createState() => _IvsPlayerViewState();
}

class _IvsPlayerViewState extends State<IvsPlayerView>
    with AutomaticKeepAliveClientMixin {
  /// Local reference to the IVS player controller.
  IvsPlayer? _player;

  /// Initializes the state of the widget. The player controller is assigned
  /// after the first frame has been rendered.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _player = widget.controller;
      },
    );
  }

  /// Disposes of the player if [autoDispose] is true.
  @override
  void dispose() {
    if (widget.autoDispose) {
      _player?.stopPlayer();
    }
    super.dispose();
  }

  /// Builds the widget's UI, including the platform-specific view for the IVS player.
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 16 / 9,
      child: widget.controller.buildPlayerView(),
    );
  }

  /// Ensures that the widget's state is kept alive when the parent widget rebuilds.
  @override
  bool get wantKeepAlive => true;
}
