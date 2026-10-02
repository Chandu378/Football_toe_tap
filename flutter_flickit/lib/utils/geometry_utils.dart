import 'dart:math' as math;
import '../models/bounding_box.dart';

/// Geometry utilities for 2D points, bounding boxes, and football contact regions.
class GeometryUtils {
  GeometryUtils._();

  /// Calculates the Euclidean distance between two points (x1, y1) and (x2, y2).
  static double euclideanDistance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates distance from a point to the perimeter of a circular ball.
  /// If the point is inside the ball radius, returns 0.0.
  static double distanceToBallPerimeter({
    required double px,
    required double py,
    required double ballCenterX,
    required double ballCenterY,
    required double ballRadius,
  }) {
    final distToCenter = euclideanDistance(px, py, ballCenterX, ballCenterY);
    return math.max(0.0, distToCenter - ballRadius);
  }

  /// Evaluates whether a foot coordinate is within the contact zone of a football.
  ///
  /// Can use either edge distance or perimeter distance based on bounding box.
  static double effectiveDistanceToBall({
    required double footX,
    required double footY,
    required BoundingBox ballBox,
  }) {
    // Treat the ball as a circle with radius = approximateRadius
    return distanceToBallPerimeter(
      px: footX,
      py: footY,
      ballCenterX: ballBox.centerX,
      ballCenterY: ballBox.centerY,
      ballRadius: ballBox.approximateRadius,
    );
  }
}
