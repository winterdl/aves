import 'package:aves/model/entry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AvesVideoController {
  AvesEntry _entry;

  AvesEntry get entry => _entry;

  AvesVideoController(AvesEntry entry) {
    _entry = entry;
  }

  Future<void> dispose();

  Future<void> play();

  Future<void> pause();

  Future<void> seekTo(int targetMillis);

  Future<void> seekToProgress(double progress) => seekTo((duration * progress).toInt());

  Listenable get playCompletedListenable;

  VideoStatus get status;

  Stream<VideoStatus> get statusStream;

  bool get isReady;

  bool get isPlaying => status == VideoStatus.playing;

  int get duration;

  int get currentPosition;

  double get progress => (currentPosition ?? 0).toDouble() / duration;

  Stream<int> get positionStream;

  Widget buildPlayerWidget(BuildContext context);
}

enum VideoStatus {
  idle,
  initialized,
  paused,
  playing,
  completed,
  error,
}
