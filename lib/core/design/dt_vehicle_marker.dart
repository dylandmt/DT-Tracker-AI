import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders a density-aware vehicle marker at a stable logical map size.
abstract final class DTVehicleMarker {
  static Future<BitmapDescriptor> create({
    required Color accent,
    required Color surface,
    required Color onPrimary,
    required double devicePixelRatio,
    double logicalSize = 52,
    double haloOpacity = .09,
  }) async {
    const baseSize = 52.0;
    final scale = logicalSize / baseSize;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(devicePixelRatio * scale);
    const center = Offset(baseSize / 2, baseSize / 2);

    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = accent.withValues(alpha: haloOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 15, Paint()..color = surface);
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(16, 24, 20, 10),
        const Radius.circular(3),
      ),
      Paint()..color = onPrimary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 19, 12, 7),
        const Radius.circular(3),
      ),
      Paint()..color = onPrimary,
    );
    final wheelPaint = Paint()..color = surface;
    canvas.drawCircle(const Offset(21, 34), 2, wheelPaint);
    canvas.drawCircle(const Offset(31, 34), 2, wheelPaint);

    final image = await recorder.endRecording().toImage(
      (logicalSize * devicePixelRatio).round(),
      (logicalSize * devicePixelRatio).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: logicalSize,
      height: logicalSize,
    );
  }
}
