import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/map_model.dart';

class GoogleMapLayer extends StatelessWidget {
  final MapState mapState;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onCameraIdle;
  final void Function(CameraPosition) onCameraMove;
  final VoidCallback? onCameraMoveStarted;
  final Set<Polyline> Function() buildPolylines;
  final Set<Polygon> polygons;
  final Set<Marker> markers;
  final Set<Circle> circles;

  /// When true the built-in Google "my location" blue dot is shown. We turn it
  /// off once our own gamified avatar marker is available to avoid two dots.
  final bool showDefaultLocationDot;
  final void Function(LatLng position)? onTap;

  /// Optional JSON map style (e.g. the gamified theme). Applied natively by
  /// the platform map — no Dart-side per-frame cost.
  final String? style;

  const GoogleMapLayer({
    super.key,
    required this.mapState,
    required this.onMapCreated,
    required this.onCameraIdle,
    required this.onCameraMove,
    required this.buildPolylines,
    this.polygons = const {},
    this.markers = const {},
    this.circles = const {},
    this.showDefaultLocationDot = true,
    this.onCameraMoveStarted,
    this.onTap,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target:
            mapState.userLocation ?? mapState.homeBase ?? const LatLng(0, 0),
        zoom: mapState.userLocation != null || mapState.homeBase != null
            ? 17.5
            : 2.0,
      ),

      style: style,
      myLocationEnabled: mapState.permissionGranted && showDefaultLocationDot,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: buildPolylines(),
      polygons: polygons,
      markers: markers,
      circles: circles,
      onCameraIdle: onCameraIdle,
      onCameraMove: onCameraMove,
      onCameraMoveStarted: onCameraMoveStarted,
      onMapCreated: onMapCreated,
      onTap: onTap,
    );
  }
}
