import 'bounding_box.dart';

/// Detected football representation extracted from YOLO detection.
class BallDetection {
  final BoundingBox box;
  final double confidence;
  final int timestampMs;

  const BallDetection({
    required this.box,
    required this.confidence,
    required this.timestampMs,
  });

  double get centerX => box.centerX;
  double get centerY => box.centerY;
  double get radius => box.approximateRadius;

  @override
  String toString() =>
      'BallDetection(center: (${centerX.toStringAsFixed(1)}, ${centerY.toStringAsFixed(1)}), '
      'radius: ${radius.toStringAsFixed(1)}, conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
