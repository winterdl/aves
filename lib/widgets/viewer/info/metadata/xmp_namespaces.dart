import 'package:aves/ref/brand_colors.dart';
import 'package:aves/ref/xmp.dart';
import 'package:aves/utils/constants.dart';
import 'package:aves/utils/string_utils.dart';
import 'package:aves/widgets/common/identity/highlight_title.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/crs.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/darktable.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/dwc.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/exif.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/google.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/iptc.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/mwg.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/photoshop.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/tiff.dart';
import 'package:aves/widgets/viewer/info/metadata/xmp_ns/xmp.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class XmpNamespace extends Equatable {
  final String namespace;
  final Map<String, String> rawProps;

  @override
  List<Object?> get props => [namespace];

  const XmpNamespace(this.namespace, this.rawProps);

  factory XmpNamespace.create(String namespace, Map<String, String> rawProps) {
    switch (namespace) {
      case XmpBasicNamespace.ns:
        return XmpBasicNamespace(rawProps);
      case XmpContainer.ns:
        return XmpContainer(rawProps);
      case XmpCrsNamespace.ns:
        return XmpCrsNamespace(rawProps);
      case XmpDarktableNamespace.ns:
        return XmpDarktableNamespace(rawProps);
      case XmpDwcNamespace.ns:
        return XmpDwcNamespace(rawProps);
      case XmpExifNamespace.ns:
        return XmpExifNamespace(rawProps);
      case XmpGAudioNamespace.ns:
        return XmpGAudioNamespace(rawProps);
      case XmpGDepthNamespace.ns:
        return XmpGDepthNamespace(rawProps);
      case XmpGImageNamespace.ns:
        return XmpGImageNamespace(rawProps);
      case XmpIptcCoreNamespace.ns:
        return XmpIptcCoreNamespace(rawProps);
      case XmpMgwRegionsNamespace.ns:
        return XmpMgwRegionsNamespace(rawProps);
      case XmpMMNamespace.ns:
        return XmpMMNamespace(rawProps);
      case XmpNoteNamespace.ns:
        return XmpNoteNamespace(rawProps);
      case XmpPhotoshopNamespace.ns:
        return XmpPhotoshopNamespace(rawProps);
      case XmpTiffNamespace.ns:
        return XmpTiffNamespace(rawProps);
      default:
        return XmpNamespace(namespace, rawProps);
    }
  }

  String get displayTitle => XMP.namespaces[namespace] ?? namespace;

  Map<String, String> get buildProps => rawProps;

  List<Widget> buildNamespaceSection() {
    final props = buildProps.entries
        .map((kv) {
          final prop = XmpProp(kv.key, kv.value);
          return extractData(prop) ? null : prop;
        })
        .whereNotNull()
        .toList()
      ..sort((a, b) => compareAsciiUpperCaseNatural(a.displayKey, b.displayKey));

    final content = [
      if (props.isNotEmpty)
        InfoRowGroup(
          info: Map.fromEntries(props.map((prop) => MapEntry(prop.displayKey, formatValue(prop)))),
          maxValueLength: Constants.infoGroupMaxValueLength,
          linkHandlers: linkifyValues(props),
        ),
      ...buildFromExtractedData(),
    ];

    return content.isNotEmpty
        ? [
            if (displayTitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: HighlightTitle(
                  title: displayTitle,
                  color: BrandColors.get(displayTitle),
                  selectable: true,
                ),
              ),
            ...content
          ]
        : [];
  }

  bool extractStruct(XmpProp prop, RegExp pattern, Map<String, String> store) {
    final matches = pattern.allMatches(prop.path);
    if (matches.isEmpty) return false;

    final match = matches.first;
    final field = XmpProp.formatKey(match.group(1)!);
    store[field] = formatValue(prop);
    return true;
  }

  bool extractIndexedStruct(XmpProp prop, RegExp pattern, Map<int, Map<String, String>> store) {
    final matches = pattern.allMatches(prop.path);
    if (matches.isEmpty) return false;

    final match = matches.first;
    final index = int.parse(match.group(1)!);
    final field = XmpProp.formatKey(match.group(2)!);
    final fields = store.putIfAbsent(index, () => <String, String>{});
    fields[field] = formatValue(prop);
    return true;
  }

  bool extractData(XmpProp prop) => false;

  List<Widget> buildFromExtractedData() => [];

  String formatValue(XmpProp prop) => prop.value;

  Map<String, InfoLinkHandler> linkifyValues(List<XmpProp> props) => {};
}

class XmpProp {
  final String path, value;
  final String displayKey;

  XmpProp(this.path, this.value) : displayKey = formatKey(path);

  static String formatKey(String propPath) {
    return propPath.splitMapJoin(XMP.structFieldSeparator,
        onMatch: (match) => ' ${match.group(0)} ',
        onNonMatch: (s) {
          // strip namespace
          final key = s.split(XMP.propNamespaceSeparator).last;
          // format
          return key.replaceAll('_', ' ').toSentenceCase();
        });
  }

  @override
  String toString() => '$runtimeType#${shortHash(this)}{path=$path, value=$value}';
}
