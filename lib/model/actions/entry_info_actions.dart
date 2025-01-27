import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/widgets.dart';

enum EntryInfoAction {
  // general
  editDate,
  editTags,
  removeMetadata,
  // motion photo
  viewMotionPhotoVideo,
}

class EntryInfoActions {
  static const all = [
    EntryInfoAction.editDate,
    EntryInfoAction.editTags,
    EntryInfoAction.removeMetadata,
    EntryInfoAction.viewMotionPhotoVideo,
  ];
}

extension ExtraEntryInfoAction on EntryInfoAction {
  String getText(BuildContext context) {
    switch (this) {
      // general
      case EntryInfoAction.editDate:
        return context.l10n.entryInfoActionEditDate;
      case EntryInfoAction.editTags:
        return context.l10n.entryInfoActionEditTags;
      case EntryInfoAction.removeMetadata:
        return context.l10n.entryInfoActionRemoveMetadata;
      // motion photo
      case EntryInfoAction.viewMotionPhotoVideo:
        return context.l10n.entryActionViewMotionPhotoVideo;
    }
  }

  Widget getIcon() {
    return Icon(_getIconData());
  }

  IconData _getIconData() {
    switch (this) {
      // general
      case EntryInfoAction.editDate:
        return AIcons.date;
      case EntryInfoAction.editTags:
        return AIcons.addTag;
      case EntryInfoAction.removeMetadata:
        return AIcons.clear;
      // motion photo
      case EntryInfoAction.viewMotionPhotoVideo:
        return AIcons.motionPhoto;
    }
  }
}
