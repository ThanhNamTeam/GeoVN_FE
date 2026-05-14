import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

import '../models/province_model.dart';

class VietnamMapPainter extends CustomPainter {
  final List<Province> provinces;
  final Set<String> emphasisIds;
  final bool dimOutsideEmphasis;
  final bool isDarkMode;

  VietnamMapPainter({
    required this.provinces,
    this.emphasisIds = const {},
    this.dimOutsideEmphasis = false,
    this.isDarkMode = true,
  });


  List<List<List<List<double>>>> _drawPolys(Province p) => p.getCoordinates();

  void _expandBoundsForProvince(Province province, void Function(double lng, double lat) onPoint) {
    final polys = _drawPolys(province);
    for (final polygon in polys) {
      for (final ring in polygon) {
        for (final coord in ring) {
          onPoint(coord[0], coord[1]);
        }
      }
    }
  }

  Color _fillColorForProvince(Province p) {

    final h = (p.id.hashCode % 360).abs().toDouble();
    if (isDarkMode) {
      return HSLColor.fromAHSL(1, h, 0.4, 0.35).toColor();
    }
    return HSLColor.fromAHSL(1, h, 0.5, 0.8).toColor();
  }

  (double lng, double lat) _centroid(Province province) {
    double sx = 0, sy = 0;
    var n = 0;
    final polys = _drawPolys(province);
    for (final polygon in polys) {
      for (final ring in polygon) {
        for (final c in ring) {
          sx += c[0];
          sy += c[1];
          n++;
        }
      }
    }
    if (n == 0) return (0, 0);
    return (sx / n, sy / n);
  }

  Path _ringPath(
      List<List<double>> ring,
      double minLng,
      double maxLat,
      double scale,
      double offsetX,
      double offsetY,
      ) {
    final path = Path();
    var first = true;
    for (final coord in ring) {
      final x = offsetX + (coord[0] - minLng) * scale;
      final y = offsetY + (maxLat - coord[1]) * scale;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawProvincePath(
      Canvas canvas,
      Province province,
      double minLng,
      double maxLat,
      double scale,
      double offsetX,
      double offsetY,
      Paint paint,
      ) {
    final polys = _drawPolys(province);
    for (final polygon in polys) {
      for (final ring in polygon) {
        final path = _ringPath(ring, minLng, maxLat, scale, offsetX, offsetY);
        canvas.drawPath(path, paint);
      }
    }
  }

  double _layerOpacity(Province province) {
    if (!dimOutsideEmphasis || emphasisIds.isEmpty) return 1.0;
    final on = emphasisIds.contains(province.id);
    return on ? 1.0 : 0.2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (provinces.isEmpty) return;

    double minLng = 180, maxLng = -180;
    double minLat = 90, maxLat = -90;

    for (final province in provinces) {
      _expandBoundsForProvince(province, (lng, lat) {
        minLng = minLng > lng ? lng : minLng;
        maxLng = maxLng < lng ? lng : maxLng;
        minLat = minLat > lat ? lat : minLat;
        maxLat = maxLat < lat ? lat : maxLat;
      });
    }

    final lngRange = maxLng - minLng;
    final latRange = maxLat - minLat;
    minLng -= lngRange * 0.05;
    maxLng += lngRange * 0.05;
    minLat -= latRange * 0.05;
    maxLat += latRange * 0.05;

    final scaleLng = size.width / (maxLng - minLng);
    final scaleLat = size.height / (maxLat - minLat);
    final scale = scaleLng < scaleLat ? scaleLng : scaleLat;

    final offsetX = (size.width - (maxLng - minLng) * scale) / 2;
    final offsetY = (size.height - (maxLat - minLat) * scale) / 2;

    final neonCyan = const Color(0xFF22D3EE);

    for (final province in provinces) {
      final opacity = _layerOpacity(province);
      final baseColor = _fillColorForProvince(province);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = baseColor.withOpacity(opacity);

      _drawProvincePath(canvas, province, minLng, maxLat, scale, offsetX, offsetY, fillPaint);
    }


    for (final province in provinces) {
      final opacity = _layerOpacity(province);
      final isEmphasized = emphasisIds.contains(province.id);


      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isEmphasized ? 2.0 : 0.5
        ..color = (isDarkMode ? Colors.white70 : Colors.indigo).withOpacity(isEmphasized ? 1.0 : 0.5 * opacity);

      _drawProvincePath(canvas, province, minLng, maxLat, scale, offsetX, offsetY, strokePaint);

      if (isEmphasized && dimOutsideEmphasis) {
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = neonCyan.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);
        _drawProvincePath(canvas, province, minLng, maxLat, scale, offsetX, offsetY, glowPaint);
      }
    }

    for (final province in provinces) {
      final opacity = _layerOpacity(province);
      if (opacity < 0.5) continue;

      final (lng, lat) = _centroid(province);
      final ox = offsetX + (lng - minLng) * scale;
      final oy = offsetY + (maxLat - lat) * scale;

      final tp = TextPainter(
        text: TextSpan(
          text: province.name,
          style: GoogleFonts.beVietnamPro(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
            shadows: [
              Shadow(color: isDarkMode ? Colors.black : Colors.white, blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(ox - tp.width / 2, oy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant VietnamMapPainter oldDelegate) {
    return oldDelegate.emphasisIds != emphasisIds ||
        oldDelegate.dimOutsideEmphasis != dimOutsideEmphasis ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.provinces != provinces;
  }
}