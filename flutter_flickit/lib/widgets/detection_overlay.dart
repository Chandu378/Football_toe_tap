import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/detection_result.dart';
import '../models/tap_state.dart';

/// Renders real-time computer vision overlays on top of the camera preview:
/// - Person bounding box
/// - Football circular/rectangular bounding box
/// - Foot/toe keypoints (Left & Right with color-coded states)
/// - Contact proximity radius
/// - Vector distance line connecting foot to ball
class DetectionOverlay extends StatelessWidget {
  final DetectionResult detection;
  final TapState leftState;
  final TapState rightState;
  final double? leftDistance;
  final double? rightDistance;

  const DetectionOverlay({
    super.key,
    required this.detection,
    required this.leftState,
    required this.rightState,
    this.leftDistance,
    this.rightDistance,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.showDebugOverlay) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _OverlayPainter(
        detection: detection,
        leftState: leftState,
        rightState: rightState,
        leftDistance: leftDistance,
        rightDistance: rightDistance,
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final DetectionResult detection;
  final TapState leftState;
  final TapState rightState;
  final double? leftDistance;
  final double? rightDistance;

  _OverlayPainter({
    required this.detection,
    required this.leftState,
    required this.rightState,
    this.leftDistance,
    this.rightDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (detection.imageWidth <= 0 || detection.imageHeight <= 0) return;

    // Coordinate mapping ratios from model space to display viewport
    final scaleX = size.width / detection.imageWidth;
    final scaleY = size.height / detection.imageHeight;

    // 1. Draw Person Bounding Box
    if (detection.personBox != null) {
      final pBox = detection.personBox!;
      final rect = Rect.fromLTRB(
        pBox.left * scaleX,
        pBox.top * scaleY,
        pBox.right * scaleX,
        pBox.bottom * scaleY,
      );

      final personPaint = Paint()
        ..color = Colors.blueAccent.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8.0)),
        personPaint,
      );

      _drawText(
        canvas: canvas,
        text: 'Person ${(pBox.confidence * 100).toInt()}%',
        position: Offset(rect.left + 6, rect.top + 6),
        color: Colors.blueAccent,
      );
    }

    // 2. Draw Football Bounding Box & Contact Zone
    if (detection.ball != null) {
      final ball = detection.ball!;
      final bBox = ball.box;
      final ballRect = Rect.fromLTRB(
        bBox.left * scaleX,
        bBox.top * scaleY,
        bBox.right * scaleX,
        bBox.bottom * scaleY,
      );

      // Football perimeter outline
      final ballPaint = Paint()
        ..color = const Color(0xFFFBBF24) // warm amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawOval(ballRect, ballPaint);

      // Football Center Point
      final centerOffset = Offset(bBox.centerX * scaleX, bBox.centerY * scaleY);
      final centerPaint = Paint()..color = const Color(0xFFFBBF24);
      canvas.drawCircle(centerOffset, 4.0, centerPaint);

      // Draw Hysteresis Contact Threshold Ring
      final contactRadius = (bBox.approximateRadius + AppConfig.contactThreshold) * scaleX;
      final contactZonePaint = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(centerOffset, contactRadius, contactZonePaint);

      _drawText(
        canvas: canvas,
        text: 'Football ${(ball.confidence * 100).toInt()}%',
        position: Offset(ballRect.left + 4, ballRect.bottom + 4),
        color: const Color(0xFFFBBF24),
      );

      // 3. Draw Left Foot Keypoint & Distance Vector
      if (detection.leftFoot != null) {
        final lf = detection.leftFoot!;
        final footOffset = Offset(lf.x * scaleX, lf.y * scaleY);
        final footColor = _stateColor(leftState);

        _drawFootIndicator(
          canvas: canvas,
          position: footOffset,
          color: footColor,
          label: 'L: ${leftState.name.toUpperCase()}',
        );

        // Vector line to ball center
        final linePaint = Paint()
          ..color = footColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(footOffset, centerOffset, linePaint);
      }

      // 4. Draw Right Foot Keypoint & Distance Vector
      if (detection.rightFoot != null) {
        final rf = detection.rightFoot!;
        final footOffset = Offset(rf.x * scaleX, rf.y * scaleY);
        final footColor = _stateColor(rightState);

        _drawFootIndicator(
          canvas: canvas,
          position: footOffset,
          color: footColor,
          label: 'R: ${rightState.name.toUpperCase()}',
        );

        // Vector line to ball center
        final linePaint = Paint()
          ..color = footColor.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(footOffset, centerOffset, linePaint);
      }
    }
  }

  void _drawFootIndicator({
    required Canvas canvas,
    required Offset position,
    required Color color,
    required String label,
  }) {
    // Outer ripple ring
    canvas.drawCircle(
      position,
      12.0,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    // Inner solid dot
    canvas.drawCircle(
      position,
      6.0,
      Paint()..color = color,
    );

    _drawText(
      canvas: canvas,
      text: label,
      position: Offset(position.dx - 24, position.dy - 26),
      color: color,
    );
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset position,
    required Color color,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black.withValues(alpha: 0.6),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, position);
  }

  Color _stateColor(TapState state) {
    switch (state) {
      case TapState.contact:
        return const Color(0xFF22C55E); // Bright Neon Green
      case TapState.approaching:
        return const Color(0xFF38BDF8); // Cyan
      case TapState.separated:
        return const Color(0xFFE2E8F0); // White/Slate
      case TapState.idle:
        return const Color(0xFF94A3B8); // Muted gray
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter oldDelegate) => true;
}
