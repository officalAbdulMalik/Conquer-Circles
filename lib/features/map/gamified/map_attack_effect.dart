import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapEffectVariant { captured, claimed, damaged, reinforced }

/// A short-lived, animated map effect spawned when the player attacks, claims,
/// captures, or reinforces a territory. Owns its own [AnimationController]
/// (created with the map screen's ticker) and exposes derived values for the
/// shockwave rings, the territory flash, and the floating hit-text.
class MapAttackEffect {
  MapAttackEffect({
    required this.id,
    required this.location,
    required this.variant,
    required this.label,
    required this.color,
    required this.controller,
    this.territoryId,
  });

  final String id;
  final LatLng location;
  final String? territoryId;
  final MapEffectVariant variant;
  final String label;
  final Color color;
  final AnimationController controller;

  /// Screen position (logical pixels) of [location], captured when the effect
  /// spawns so the floating text can be laid out without an async lookup on
  /// every frame.
  Offset? screenAnchor;

  double get t => controller.value;

  /// Largest shockwave radius, in metres, at full expansion.
  double get maxRadiusMeters =>
      variant == MapEffectVariant.captured ? 90.0 : 55.0;

  /// Number of concentric rings for this effect.
  int get ringCount => variant == MapEffectVariant.captured ? 3 : 2;

  /// Expanding shockwave rings for the map's [Circle] layer.
  Set<Circle> buildRings() {
    final rings = <Circle>{};
    for (var i = 0; i < ringCount; i++) {
      // Stagger the rings so they ripple outward.
      final delay = i * 0.18;
      final double local = ((t - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
      if (local <= 0) continue;
      final eased = Curves.easeOut.transform(local);
      final radius = eased * maxRadiusMeters;
      final fade = (1 - local);
      rings.add(
        Circle(
          circleId: CircleId('fx_${id}_ring_$i'),
          center: location,
          radius: radius,
          strokeWidth: 4,
          strokeColor: color.withValues(alpha: 0.75 * fade),
          fillColor: color.withValues(alpha: 0.10 * fade),
        ),
      );
    }
    return rings;
  }

  /// Alpha for the flashing territory fill (0 when the effect is done).
  double get territoryFlashAlpha {
    // Quick bright flash that decays over the life of the effect.
    return (0.45 * (1 - Curves.easeIn.transform(t))).clamp(0.0, 0.45).toDouble();
  }

  /// Floating hit-text: rises and fades.
  double get textOpacity {
    // Fade in fast, hold, then fade out.
    if (t < 0.15) return (t / 0.15).clamp(0.0, 1.0).toDouble();
    return (1 - ((t - 0.15) / 0.85)).clamp(0.0, 1.0).toDouble();
  }

  double get textRisePixels => Curves.easeOut.transform(t) * 46;
  double get textScale =>
      0.8 + Curves.easeOutBack.transform((t.clamp(0.0, 0.5) * 2).toDouble()) * 0.2;

  static MapEffectVariant? variantFromAction(String action) {
    switch (action) {
      case 'captured':
        return MapEffectVariant.captured;
      case 'claimed':
        return MapEffectVariant.claimed;
      case 'damaged':
        return MapEffectVariant.damaged;
      case 'reinforced':
        return MapEffectVariant.reinforced;
      default:
        return null;
    }
  }

  static Color colorFor(MapEffectVariant variant) {
    switch (variant) {
      case MapEffectVariant.captured:
        return const Color(0xFFFF3B3B);
      case MapEffectVariant.claimed:
        return const Color(0xFF2ECC71);
      case MapEffectVariant.damaged:
        return const Color(0xFFFFA500);
      case MapEffectVariant.reinforced:
        return const Color(0xFF4169FF);
    }
  }
}
