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

  const GoogleMapLayer({super.key, 
   
    required this.hexGrid,
    required this.hexPolygons,
    required this.mapState,
    required this.onMapCreated,
    required this.onCameraIdle,
    required this.onCameraMove,
    required this.buildPolylines,
  });

  @override
  Widget build(BuildContext context) {


print("{  mapState.userLocation: ${mapState.userLocation}, mapState.homeBase: ${mapState.homeBase} }");

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: mapState.userLocation ??
            mapState.homeBase ??
            const LatLng(51.5074, -0.1278), // default to SF if no location
        zoom: 15.0,
      ),
     
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      polylines: buildPolylines(),
      polygons: {...hexGrid, ...hexPolygons},
      onCameraIdle: onCameraIdle,
      onCameraMove: onCameraMove,
      onMapCreated: onMapCreated,
    );
  }
}