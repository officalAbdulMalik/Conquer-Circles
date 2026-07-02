import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders the gamified "player" map marker: a circular avatar with a colored
/// ring and a soft glow, baked into a [BitmapDescriptor] the Google Map can
/// draw. Results are cached so we only rasterise once per configuration.
class PlayerMarkerBuilder {
  PlayerMarkerBuilder._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> build({
    String assetPath = 'assets/images/get_started_runner.png',
    Color ringColor = const Color(0xFF4169FF),
    double logicalSize = 20,
    double devicePixelRatio = 3.0,
  }) async {
    final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final key = '$assetPath|$ringColor|$logicalSize|$dpr';
    final cached = _cache[key];
    if (cached != null) return cached;

    final size = logicalSize * dpr;
    final center = Offset(size / 2, size / 2);
    final avatarRadius = size * 0.33;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Soft outer glow.
    canvas.drawCircle(
      center,
      size * 0.44,
      Paint()
        ..color = ringColor.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.07),
    );

    // White backing so the avatar reads on any map tile.
    canvas.drawCircle(
      center,
      avatarRadius + size * 0.035,
      Paint()..color = Colors.white,
    );

    ui.Image? avatar;
    try {
      avatar = await _loadImage(assetPath);
    } catch (_) {
      avatar = null;
    }

    if (avatar != null) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: avatarRadius)),
      );
      final src = Rect.fromLTWH(
        0,
        0,
        avatar.width.toDouble(),
        avatar.height.toDouble(),
      );
      final dst = Rect.fromCircle(center: center, radius: avatarRadius);
      canvas.drawImageRect(
        avatar,
        src,
        dst,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    } else {
      // Fallback: a filled disc if the avatar art is missing.
      canvas.drawCircle(
        center,
        avatarRadius,
        Paint()..color = ringColor.withValues(alpha: 0.9),
      );
    }

    // Crisp ring around the avatar.
    canvas.drawCircle(
      center,
      avatarRadius + size * 0.02,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.055,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round(), size.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    avatar?.dispose();

    if (bytes == null) {
      return BitmapDescriptor.defaultMarker;
    }

    final descriptor = BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  /// A direction cone that sits *under* the avatar marker and rotates with the
  /// player's heading (the avatar itself stays screen-upright). Drawn pointing
  /// north; the map rotates it via [Marker.rotation]. Baked once and cached.
  static Future<BitmapDescriptor> buildHeadingArrow({
    Color color = const Color(0xFF4169FF),
    double logicalSize = 34,
    double devicePixelRatio = 3.0,
  }) async {
    final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final key = 'arrow|$color|$logicalSize|$dpr';
    final cached = _cache[key];
    if (cached != null) return cached;

    final size = logicalSize * dpr;
    final center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Soft cone fanning out from the centre towards the top edge.
    final cone = Path()
      ..moveTo(center.dx, size * 0.02) // tip
      ..lineTo(center.dx - size * 0.16, size * 0.34)
      ..quadraticBezierTo(
        center.dx,
        size * 0.26,
        center.dx + size * 0.16,
        size * 0.34,
      )
      ..close();

    canvas.drawPath(
      cone,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.03),
    );
    canvas.drawPath(cone, Paint()..color = color.withValues(alpha: 0.95));

    final descriptor = await _rasterise(recorder, size, dpr);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// The player's home base: glowing gold-ringed disc with a castle glyph.
  /// Baked once and cached, exactly like the avatar marker.
  static Future<BitmapDescriptor> buildHomeBase({
    Color ringColor = const Color(0xFFF5A623),
    double logicalSize = 34,
    double devicePixelRatio = 3.0,
  }) async {
    final dpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final key = 'home|$ringColor|$logicalSize|$dpr';
    final cached = _cache[key];
    if (cached != null) return cached;

    final size = logicalSize * dpr;
    final center = Offset(size / 2, size / 2);
    final discRadius = size * 0.34;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Warm outer glow so the base reads as a landmark.
    canvas.drawCircle(
      center,
      size * 0.46,
      Paint()
        ..color = ringColor.withValues(alpha: 0.30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.08),
    );

    // White disc + gold ring.
    canvas.drawCircle(center, discRadius, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      center,
      discRadius,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.055,
    );

    // Castle glyph, drawn as text so no extra asset is needed.
    final painter = TextPainter(
      text: TextSpan(text: '🏰', style: TextStyle(fontSize: discRadius * 1.15)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

    final descriptor = await _rasterise(recorder, size, dpr);
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> _rasterise(
    ui.PictureRecorder recorder,
    double size,
    double dpr,
  ) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.round(), size.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      imagePixelRatio: dpr,
    );
  }

  static Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
