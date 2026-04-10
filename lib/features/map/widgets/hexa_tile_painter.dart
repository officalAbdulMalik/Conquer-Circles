import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/tile_handler.dart';

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
    const double radius = 35.0; 
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
        double angle = 2.0 * math.pi / 6 * i;
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
      ..color = tile.displayColor.withOpacity(isSelected ? 0.5 : 0.25)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = tile.displayColor.withOpacity(isSelected ? 0.7 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 1.5;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    
    // Protected icon
    if (tile.isProtected) {
      const icon = Icons.shield;
      final textSpan = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 16,
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
