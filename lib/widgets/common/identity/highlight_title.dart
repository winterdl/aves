import 'dart:ui';

import 'package:aves/utils/color_utils.dart';
import 'package:aves/widgets/common/fx/highlight_decoration.dart';
import 'package:flutter/material.dart';

class HighlightTitle extends StatelessWidget {
  final String title;
  final Color? color;
  final double fontSize;
  final bool enabled, selectable;
  final bool showHighlight;

  const HighlightTitle({
    Key? key,
    required this.title,
    this.color,
    this.fontSize = 18,
    this.enabled = true,
    this.selectable = false,
    this.showHighlight = true,
  }) : super(key: key);

  static const disabledColor = Colors.grey;

  static const shadows = [
    Shadow(
      color: Colors.black,
      offset: Offset(1, 1),
      blurRadius: 2,
    )
  ];

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      shadows: shadows,
      fontSize: fontSize,
      letterSpacing: 1.0,
      fontFeatures: const [FontFeature.enable('smcp')],
    );

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        decoration: showHighlight
            ? HighlightDecoration(
                color: enabled ? color ?? stringToColor(title) : disabledColor,
              )
            : null,
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: selectable
            ? SelectableText(
                title,
                style: style,
                maxLines: 1,
              )
            : Text(
                title,
                style: style,
                softWrap: false,
                overflow: TextOverflow.fade,
                maxLines: 1,
              ),
      ),
    );
  }
}
