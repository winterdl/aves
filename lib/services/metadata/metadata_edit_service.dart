import 'dart:async';

import 'package:aves/model/entry.dart';
import 'package:aves/model/entry_xmp_iptc.dart';
import 'package:aves/model/metadata/date_modifier.dart';
import 'package:aves/model/metadata/enums.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

abstract class MetadataEditService {
  Future<Map<String, dynamic>> rotate(AvesEntry entry, {required bool clockwise});

  Future<Map<String, dynamic>> flip(AvesEntry entry);

  Future<Map<String, dynamic>> editDate(AvesEntry entry, DateModifier modifier);

  Future<Map<String, dynamic>> setIptc(AvesEntry entry, List<Map<String, dynamic>>? iptc, {required bool postEditScan});

  Future<Map<String, dynamic>> setXmp(AvesEntry entry, AvesXmp? xmp);

  Future<Map<String, dynamic>> removeTypes(AvesEntry entry, Set<MetadataType> types);
}

class PlatformMetadataEditService implements MetadataEditService {
  static const platform = MethodChannel('deckers.thibault/aves/metadata_edit');

  static Map<String, dynamic> _toPlatformEntryMap(AvesEntry entry) {
    return {
      'uri': entry.uri,
      'path': entry.path,
      'pageId': entry.pageId,
      'mimeType': entry.mimeType,
      'width': entry.width,
      'height': entry.height,
      'rotationDegrees': entry.rotationDegrees,
      'isFlipped': entry.isFlipped,
      'dateModifiedSecs': entry.dateModifiedSecs,
      'sizeBytes': entry.sizeBytes,
    };
  }

  @override
  Future<Map<String, dynamic>> rotate(AvesEntry entry, {required bool clockwise}) async {
    try {
      // returns map with: 'rotationDegrees' 'isFlipped'
      final result = await platform.invokeMethod('rotate', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
        'clockwise': clockwise,
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> flip(AvesEntry entry) async {
    try {
      // returns map with: 'rotationDegrees' 'isFlipped'
      final result = await platform.invokeMethod('flip', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> editDate(AvesEntry entry, DateModifier modifier) async {
    try {
      final result = await platform.invokeMethod('editDate', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
        'dateMillis': modifier.setDateTime?.millisecondsSinceEpoch,
        'shiftMinutes': modifier.shiftMinutes,
        'fields': modifier.fields.map((v) => v.toExifInterfaceTag()).toList(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> setIptc(AvesEntry entry, List<Map<String, dynamic>>? iptc, {required bool postEditScan}) async {
    try {
      final result = await platform.invokeMethod('setIptc', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
        'iptc': iptc,
        'postEditScan': postEditScan,
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> setXmp(AvesEntry entry, AvesXmp? xmp) async {
    try {
      final result = await platform.invokeMethod('setXmp', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
        'xmp': xmp?.xmpString,
        'extendedXmp': xmp?.extendedXmpString,
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> removeTypes(AvesEntry entry, Set<MetadataType> types) async {
    try {
      final result = await platform.invokeMethod('removeTypes', <String, dynamic>{
        'entry': _toPlatformEntryMap(entry),
        'types': types.map(_toPlatformMetadataType).toList(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  String _toPlatformMetadataType(MetadataType type) {
    switch (type) {
      case MetadataType.comment:
        return 'comment';
      case MetadataType.exif:
        return 'exif';
      case MetadataType.iccProfile:
        return 'icc_profile';
      case MetadataType.iptc:
        return 'iptc';
      case MetadataType.jfif:
        return 'jfif';
      case MetadataType.jpegAdobe:
        return 'jpeg_adobe';
      case MetadataType.jpegDucky:
        return 'jpeg_ducky';
      case MetadataType.photoshopIrb:
        return 'photoshop_irb';
      case MetadataType.xmp:
        return 'xmp';
    }
  }
}
