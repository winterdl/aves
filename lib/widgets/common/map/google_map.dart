import 'dart:async';
import 'dart:typed_data';

import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/map/buttons.dart';
import 'package:aves/widgets/common/map/decorator.dart';
import 'package:aves/widgets/common/map/marker.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;

class EntryGoogleMap extends StatefulWidget {
  // `LatLng` used by `google_maps_flutter` is not the one from `latlong2` package
  final ll.LatLng center;
  final double initialZoom;
  final bool interactive;
  final List<AvesEntry> markerEntries;
  final Widget Function(AvesEntry entry) markerBuilder;

  const EntryGoogleMap({
    Key? key,
    required this.center,
    required this.initialZoom,
    required this.interactive,
    required this.markerEntries,
    required this.markerBuilder,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EntryGoogleMapState();
}

class _EntryGoogleMapState extends State<EntryGoogleMap> {
  GoogleMapController? _controller;
  late Completer<List<Uint8List>> _markerLoaderCompleter;

  @override
  void initState() {
    super.initState();
    _markerLoaderCompleter = Completer<List<Uint8List>>();
  }

  @override
  void didUpdateWidget(covariant EntryGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != oldWidget.center && _controller != null) {
      _controller!.moveCamera(CameraUpdate.newLatLng(_toGoogleLatLng(widget.center)));
    }
    const eq = DeepCollectionEquality();
    if (!eq.equals(widget.markerEntries, oldWidget.markerEntries)) {
      _markerLoaderCompleter = Completer<List<Uint8List>>();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MarkerGeneratorWidget(
          markers: widget.markerEntries.map(widget.markerBuilder).toList(),
          onComplete: (bitmaps) => _markerLoaderCompleter.complete(bitmaps),
        ),
        MapDecorator(
          interactive: widget.interactive,
          child: _buildMap(),
        ),
        MapButtonPanel(
          latLng: widget.center,
          zoomBy: _zoomBy,
        ),
      ],
    );
  }

  Widget _buildMap() {
    return FutureBuilder<List<Uint8List>>(
        future: _markerLoaderCompleter.future,
        builder: (context, snapshot) {
          final markers = <Marker>{};
          if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done) {
            final markerBytes = snapshot.data!;
            markers.addAll(widget.markerEntries.mapIndexed((i, entry) => Marker(
                  markerId: MarkerId(entry.uri),
                  icon: BitmapDescriptor.fromBytes(markerBytes[i]),
                  position: _toGoogleLatLng(entry.latLng!),
                )));
          }
          final interactive = widget.interactive;
          return GoogleMap(
            // GoogleMap init perf issue: https://github.com/flutter/flutter/issues/28493
            initialCameraPosition: CameraPosition(
              target: _toGoogleLatLng(widget.center),
              zoom: widget.initialZoom,
            ),
            onMapCreated: (controller) => setState(() => _controller = controller),
            compassEnabled: interactive,
            mapToolbarEnabled: false,
            mapType: _toMapStyle(settings.infoMapStyle),
            rotateGesturesEnabled: interactive,
            scrollGesturesEnabled: interactive,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: interactive,
            // no camera animation in lite mode
            liteModeEnabled: false,
            tiltGesturesEnabled: interactive,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: markers,
          );
        });
  }

  void _zoomBy(double amount) {
    settings.infoMapZoom += amount;
    _controller?.animateCamera(CameraUpdate.zoomBy(amount));
  }

  LatLng _toGoogleLatLng(ll.LatLng latLng) => LatLng(latLng.latitude, latLng.longitude);

  MapType _toMapStyle(EntryMapStyle style) {
    switch (style) {
      case EntryMapStyle.googleNormal:
        return MapType.normal;
      case EntryMapStyle.googleHybrid:
        return MapType.hybrid;
      case EntryMapStyle.googleTerrain:
        return MapType.terrain;
      default:
        return MapType.none;
    }
  }
}
