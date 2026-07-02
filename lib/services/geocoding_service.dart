import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:test_steps/features/map/widgets/home_base_setup_sheet.dart'
    show HomeBaseLocationSuggestion;

/// Thin wrapper around the platform geocoder so business code (providers)
/// never talks to the plugin directly and the UI layer never geocodes.
class GeocodingService {
  const GeocodingService();

  /// Forward-geocodes [query] and returns up to [limit] labelled suggestions.
  Future<List<HomeBaseLocationSuggestion>> searchAddress(
    String query, {
    int limit = 5,
  }) async {
    final results = await locationFromAddress(query);
    if (results.isEmpty) return const [];

    return Future.wait(
      results.take(limit).map((result) async {
        final coordinates = LatLng(result.latitude, result.longitude);
        final label = await addressForCoordinates(
          coordinates,
          fallback: query,
        );
        return HomeBaseLocationSuggestion(
          label: label,
          latitude: result.latitude,
          longitude: result.longitude,
        );
      }),
    );
  }

  /// Reverse-geocodes coordinates into a human-readable address, falling back
  /// to [fallback] or "lat, lng" when the geocoder has nothing.
  Future<String> addressForCoordinates(
    LatLng coordinates, {
    String? fallback,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      if (placemarks.isNotEmpty) {
        final address = _formatPlacemark(placemarks.first);
        if (address.isNotEmpty) return address;
      }
    } catch (_) {}

    return fallback ??
        '${coordinates.latitude.toStringAsFixed(5)}, '
            '${coordinates.longitude.toStringAsFixed(5)}';
  }

  String _formatPlacemark(Placemark placemark) {
    final parts = <String?>[
      placemark.name,
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ];
    final unique = <String>[];
    for (final part in parts) {
      final value = part?.trim();
      if (value != null && value.isNotEmpty && !unique.contains(value)) {
        unique.add(value);
      }
    }
    return unique.join(', ');
  }
}
