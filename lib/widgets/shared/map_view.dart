import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:test_steps/models/map_model.dart';

class GoogleMapLayer extends StatelessWidget {
  final Set<Polygon> hexGrid;
  final Set<Polygon> hexPolygons;
  final MapState mapState;
  final void Function(GoogleMapController) onMapCreated;
  final VoidCallback onCameraIdle;
  final void Function(CameraPosition) onCameraMove;
  final Set<Polyline> Function() buildPolylines;
  final void Function(LatLng position)? onTap;

  const GoogleMapLayer({
    super.key,
    required this.hexGrid,
    required this.hexPolygons,
    required this.mapState,
    required this.onMapCreated,
    required this.onCameraIdle,
    required this.onCameraMove,
    required this.buildPolylines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target:
            mapState.userLocation ??
            mapState.homeBase ??
            const LatLng(31.5204, 74.3587),
        zoom: 15.0,
      ),

      myLocationEnabled: mapState.permissionGranted,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: buildPolylines(),
      polygons: {...hexGrid, ...hexPolygons},
      onCameraIdle: onCameraIdle,
      onCameraMove: onCameraMove,
      onMapCreated: onMapCreated,
      onTap: onTap,
    );
  }
}
