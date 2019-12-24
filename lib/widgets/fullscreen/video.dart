import 'dart:math';
import 'dart:ui';

import 'package:aves/model/image_entry.dart';
import 'package:aves/widgets/common/image_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class AvesVideo extends StatefulWidget {
  final ImageEntry entry;
  final VideoPlayerController controller;

  const AvesVideo({
    Key key,
    @required this.entry,
    @required this.controller,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => AvesVideoState();
}

class AvesVideoState extends State<AvesVideo> {
  ImageEntry get entry => widget.entry;

  VideoPlayerValue get value => widget.controller.value;

  @override
  void initState() {
    super.initState();
    _registerWidget(widget);
    _onValueChange();
  }

  @override
  void didUpdateWidget(AvesVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unregisterWidget(oldWidget);
    _registerWidget(widget);
  }

  @override
  void dispose() {
    _unregisterWidget(widget);
    super.dispose();
  }

  void _registerWidget(AvesVideo widget) {
    widget.controller.addListener(_onValueChange);
  }

  void _unregisterWidget(AvesVideo widget) {
    widget.controller.removeListener(_onValueChange);
  }

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox();
    if (value.hasError) {
      return Selector<MediaQueryData, double>(
        selector: (c, mq) => mq.size.width,
        builder: (c, mqWidth, child) {
          final width = min<double>(mqWidth, entry.width.toDouble());
          return ImagePreview(
            entry: entry,
            width: width,
            height: width / entry.aspectRatio,
            builder: (bytes) => Image.memory(bytes),
          );
        },
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: entry.aspectRatio,
        child: VideoPlayer(widget.controller),
      ),
    );
  }

  void _onValueChange() {
    if (!value.isPlaying && value.position == value.duration) _goToStart();
    setState(() {});
  }

  Future<void> _goToStart() async {
    await widget.controller.seekTo(Duration.zero);
    await widget.controller.pause();
  }
}
