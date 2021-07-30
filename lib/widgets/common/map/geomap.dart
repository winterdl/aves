import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/enums.dart';
import 'package:aves/model/settings/map_style.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/services/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/map/attribution.dart';
import 'package:aves/widgets/common/map/buttons.dart';
import 'package:aves/widgets/common/map/decorator.dart';
import 'package:aves/widgets/common/map/google_map.dart';
import 'package:aves/widgets/common/map/leaflet_map.dart';
import 'package:aves/widgets/common/map/marker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GeoMap extends StatefulWidget {
  final List<AvesEntry> entries;
  final bool interactive;
  final double? mapHeight;
  final ValueNotifier<bool> isAnimatingNotifier;

  const GeoMap({
    Key? key,
    required this.entries,
    required this.interactive,
    this.mapHeight,
    required this.isAnimatingNotifier,
  }) : super(key: key);

  @override
  _GeoMapState createState() => _GeoMapState();
}

class _GeoMapState extends State<GeoMap> with TickerProviderStateMixin {
  // as of google_maps_flutter v2.0.6, Google Maps initialization is blocking
  // cf https://github.com/flutter/flutter/issues/28493
  // it is especially severe the first time, but still significant afterwards
  // so we prevent loading it while scrolling or animating
  bool _googleMapsLoaded = false;

  List<AvesEntry> get entries => widget.entries;

  bool get interactive => widget.interactive;

  double? get mapHeight => widget.mapHeight;

  static const extent = 48.0;
  static const pointerSize = Size(8, 6);

  @override
  Widget build(BuildContext context) {
    final center = entries.first.latLng!;
    return FutureBuilder<bool>(
      future: availability.isConnected,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox();
        return Selector<Settings, EntryMapStyle>(
          selector: (context, s) => s.infoMapStyle,
          builder: (context, mapStyle, child) {
            final isGoogleMaps = mapStyle.isGoogleMaps;

            Widget child = isGoogleMaps
                ? EntryGoogleMap(
                    center: center,
                    initialZoom: settings.infoMapZoom,
                    interactive: interactive,
                    markerEntries: entries,
                    markerBuilder: _buildMarker,
                  )
                : EntryLeafletMap(
                    center: center,
                    initialZoom: settings.infoMapZoom,
                    interactive: interactive,
                    style: settings.infoMapStyle,
                    markerSize: Size(
                      extent + ImageMarker.outerBorderWidth * 2,
                      extent + ImageMarker.outerBorderWidth * 2 + pointerSize.height,
                    ),
                    markerEntries: entries,
                    markerBuilder: _buildMarker,
                  );

            child = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mapHeight != null
                    ? SizedBox(
                        height: mapHeight,
                        child: child,
                      )
                    : Expanded(child: child),
                Attribution(style: mapStyle),
              ],
            );

            return AnimatedSize(
              alignment: Alignment.topCenter,
              curve: Curves.easeInOutCubic,
              duration: Durations.mapStyleSwitchAnimation,
              vsync: this,
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.isAnimatingNotifier,
                builder: (context, animating, child) {
                  if (!animating && isGoogleMaps) {
                    _googleMapsLoaded = true;
                  }
                  Widget replacement = Stack(
                    children: [
                      MapDecorator(
                        interactive: interactive,
                      ),
                      MapButtonPanel(
                        latLng: center,
                        zoomBy: (_) {},
                      ),
                    ],
                  );
                  if (mapHeight != null) {
                    replacement = SizedBox(
                      height: mapHeight,
                      child: replacement,
                    );
                  }
                  return Visibility(
                    visible: !isGoogleMaps || _googleMapsLoaded,
                    replacement: replacement,
                    child: child!,
                  );
                },
                child: child,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarker(AvesEntry entry) => ImageMarker(
        entry: entry,
        extent: extent,
        pointerSize: pointerSize,
      );
}
