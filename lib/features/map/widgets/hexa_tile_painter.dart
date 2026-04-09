import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:test_steps/features/map/widgets/tile_handler.dart';

class HexTilePainter extends CustomPainter {
  final List<MapTile> tiles;
  final Map<String, Offset> tileCenters;
  final String currentUserId;
  final String? selectedTileId;

  HexTilePainter({
    required this.tiles,
    required this.tileCenters,
    required this.currentUserId,
    this.selectedTileId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tiles.isEmpty || tileCenters.isEmpty) return;

    for (final tile in tiles) {
      final center = tileCenters[tile.tileId];
      if (center == null) continue;

      // Only paint if center is within view
      if (center.dx < -100 || center.dx > size.width + 100 || 
          center.dy < -100 || center.dy > size.height + 100) {
        continue;
      }

      final isSelected = tile.tileId == selectedTileId;
      _drawHex(canvas, center, tile, isSelected);
    }
  }

  void _drawHex(Canvas canvas, Offset center, MapTile tile, bool isSelected) {
    // Hex radius - roughly matches Google Map zoom level 16-17
    // This value ideally should come from current zoom scale
    const double radius = 35.0; 
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
        double angle = 2.0 * math.pi / 6 * i;
        // Pointy-topped hex orientation
        angle -= math.pi / 6; 
        
        double x = center.dx + radius * math.cos(angle);
        double y = center.dy + radius * math.sin(angle);
        if (i == 0) {
            path.moveTo(x, y);
        } else {
            path.lineTo(x, y);
        }
    }
    path.close();

    final fillPaint = Paint()
      ..color = tile.displayColor.withValues(alpha: isSelected ? 0.6 : 0.3)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = tile.displayColor.withValues(alpha: isSelected ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Draw energy number or icon if needed
    if (tile.ownership != TileOwnership.neutral && !tile.isProtected) {
      final textSpan = TextSpan(
        text: '${tile.energy}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
    
    if (tile.isProtected) {
      const icon = Icons.shield;
      final textSpan = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 14,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HexTilePainter oldDelegate) {
    return oldDelegate.tiles != tiles || 
           oldDelegate.tileCenters != tileCenters ||
           oldDelegate.selectedTileId != selectedTileId;
  }
}
