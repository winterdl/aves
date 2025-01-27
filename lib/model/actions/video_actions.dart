import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

enum VideoAction {
  captureFrame,
  playOutside,
  replay10,
  skip10,
  selectStreams,
  setSpeed,
  settings,
  togglePlay,
  // TODO TLAD [video] toggle mute
}

class VideoActions {
  static const all = [
    VideoAction.togglePlay,
    VideoAction.captureFrame,
    VideoAction.setSpeed,
    VideoAction.selectStreams,
    VideoAction.replay10,
    VideoAction.skip10,
    VideoAction.playOutside,
    VideoAction.settings,
  ];
}

extension ExtraVideoAction on VideoAction {
  String getText(BuildContext context) {
    switch (this) {
      case VideoAction.captureFrame:
        return context.l10n.videoActionCaptureFrame;
      case VideoAction.playOutside:
        return context.l10n.entryActionOpen;
      case VideoAction.replay10:
        return context.l10n.videoActionReplay10;
      case VideoAction.skip10:
        return context.l10n.videoActionSkip10;
      case VideoAction.selectStreams:
        return context.l10n.videoActionSelectStreams;
      case VideoAction.setSpeed:
        return context.l10n.videoActionSetSpeed;
      case VideoAction.settings:
        return context.l10n.videoActionSettings;
      case VideoAction.togglePlay:
        // different data depending on toggle state
        return context.l10n.videoActionPlay;
    }
  }

  Widget getIcon() {
    return Icon(_getIconData());
  }

  IconData _getIconData() {
    switch (this) {
      case VideoAction.captureFrame:
        return AIcons.captureFrame;
      case VideoAction.playOutside:
        return AIcons.openOutside;
      case VideoAction.replay10:
        return AIcons.replay10;
      case VideoAction.skip10:
        return AIcons.skip10;
      case VideoAction.selectStreams:
        return AIcons.streams;
      case VideoAction.setSpeed:
        return AIcons.speed;
      case VideoAction.settings:
        return AIcons.videoSettings;
      case VideoAction.togglePlay:
        // different data depending on toggle state
        return AIcons.play;
    }
  }
}
