import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/widgets/common/map/buttons.dart';
import 'package:aves/widgets/common/map/decorator.dart';
import 'package:aves/widgets/common/map/scale_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class EntryLeafletMap extends StatefulWidget {
  final LatLng center;
  final double initialZoom;
  final bool interactive;
  final EntryMapStyle style;
  final List<AvesEntry> markerEntries;
  final Widget Function(AvesEntry entry) markerBuilder;
  final Size markerSize;

  const EntryLeafletMap({
    Key? key,
    required this.center,
    required this.initialZoom,
    required this.interactive,
    required this.style,
    required this.markerEntries,
    required this.markerBuilder,
    required this.markerSize,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EntryLeafletMapState();
}

class _EntryLeafletMapState extends State<EntryLeafletMap> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant EntryLeafletMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != oldWidget.center) {
      _mapController.move(widget.center, settings.infoMapZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
    final markerSize = widget.markerSize;
    return FlutterMap(
      options: MapOptions(
        center: widget.center,
        zoom: widget.initialZoom,
        interactiveFlags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
      ),
      mapController: _mapController,
      children: [
        _buildMapLayer(),
        ScaleLayerWidget(
          options: ScaleLayerOptions(),
        ),
        MarkerLayerWidget(
          options: MarkerLayerOptions(
            markers: widget.markerEntries
                .map((entry) => Marker(
                      width: markerSize.width,
                      height: markerSize.height,
                      point: entry.latLng!,
                      builder: (context) => widget.markerBuilder(entry),
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                    ))
                .toList(),
            rotate: true,
            rotateAlignment: Alignment.bottomCenter,
          ),
        ),
      ],
    );
  }

  Widget _buildMapLayer() {
    switch (widget.style) {
      case EntryMapStyle.osmHot:
        return const OSMHotLayer();
      case EntryMapStyle.stamenToner:
        return const StamenTonerLayer();
      case EntryMapStyle.stamenWatercolor:
        return const StamenWatercolorLayer();
      default:
        return const SizedBox.shrink();
    }
  }

  void _zoomBy(double amount) {
    final endZoom = (settings.infoMapZoom + amount).clamp(1.0, 16.0);
    settings.infoMapZoom = endZoom;

    final zoomTween = Tween<double>(begin: _mapController.zoom, end: endZoom);
    final controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    controller.addListener(() => _mapController.move(widget.center, zoomTween.evaluate(animation)));
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }
}

class OSMHotLayer extends StatelessWidget {
  const OSMHotLayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TileLayerWidget(
      options: TileLayerOptions(
        urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
        subdomains: ['a', 'b', 'c'],
        retinaMode: context.select<MediaQueryData, double>((mq) => mq.devicePixelRatio) > 1,
      ),
    );
  }
}

class StamenTonerLayer extends StatelessWidget {
  const StamenTonerLayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TileLayerWidget(
      options: TileLayerOptions(
        urlTemplate: 'https://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}{r}.png',
        subdomains: ['a', 'b', 'c', 'd'],
        retinaMode: context.select<MediaQueryData, double>((mq) => mq.devicePixelRatio) > 1,
      ),
    );
  }
}

class StamenWatercolorLayer extends StatelessWidget {
  const StamenWatercolorLayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TileLayerWidget(
      options: TileLayerOptions(
        urlTemplate: 'https://stamen-tiles-{s}.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.jpg',
        subdomains: ['a', 'b', 'c', 'd'],
        retinaMode: context.select<MediaQueryData, double>((mq) => mq.devicePixelRatio) > 1,
      ),
    );
  }
}
