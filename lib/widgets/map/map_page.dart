import 'package:aves/model/entry.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/map/geomap.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  static const routeName = '/collection/map';

  final CollectionSource source;
  final CollectionLens? parentCollection;
  late final List<AvesEntry> entries;

  final ValueNotifier<bool> _isAnimatingNotifier = ValueNotifier(false);

  MapPage({
    Key? key,
    required this.source,
    this.parentCollection,
  }) : super(key: key) {
    entries = (parentCollection?.sortedEntries.expand((entry) => entry.burstEntries ?? {entry}).toSet() ?? source.visibleEntries).where((entry) => entry.hasGps).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.mapPageTitle),
        ),
        body: SafeArea(
          child: GeoMap(
            entries: entries,
            interactive: true,
            isAnimatingNotifier: _isAnimatingNotifier,
          ),
        ),
      ),
    );
  }
}
