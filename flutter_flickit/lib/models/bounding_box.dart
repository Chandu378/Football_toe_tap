import 'dart:math' as math;

/// Rectangular bounding box represented by [left], [top], [right], and [bottom] coordinates.
///
/// Provides geometric helpers for center calculation, dimensions, point containment,
/// and euclidean distance from points to the box boundary or center.
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
  final int classId;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence = 1.0,
    this.classId = 0,
  });

  /// Bounding box width
  double get width => (right - left).abs();

  /// Bounding box height
  double get height => (bottom - top).abs();

  /// Horizontal center coordinate
  double get centerX => left + (width / 2.0);

  /// Vertical center coordinate
  double get centerY => top + (height / 2.0);

  /// Radius approximation when treating the bounding box as a circular football
  double get approximateRadius => (width + height) / 4.0;

  /// Returns true if the coordinate ([px], [py]) falls strictly inside the box.
  bool contains(double px, double py) {
    return px >= left && px <= right && py >= top && py <= bottom;
  }

  /// Calculates the Euclidean distance from a point ([px], [py]) to the box center.
  double distanceToCenter(double px, double py) {
    final dx = px - centerX;
    final dy = py - centerY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Calculates Euclidean distance from a point to the nearest edge of the bounding box.
  /// If the point is inside the box, returns 0.0.
  double distanceToEdge(double px, double py) {
    final dx = math.max(0.0, math.max(left - px, px - right));
    final dy = math.max(0.0, math.max(top - py, py - bottom));
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Returns whether a foot point ([px], [py]) is within an expanded contact radius
  /// or within [contactThreshold] distance from the ball edge.
  bool isPointInContact(double px, double py, double contactThreshold) {
    // If inside or within threshold of edge, consider in contact
    return distanceToEdge(px, py) <= contactThreshold;
  }

  BoundingBox copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? confidence,
    int? classId,
  }) {
    return BoundingBox(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      confidence: confidence ?? this.confidence,
      classId: classId ?? this.classId,
    );
  }

  @override
  String toString() =>
      'BoundingBox(l: ${left.toStringAsFixed(1)}, t: ${top.toStringAsFixed(1)}, '
      'r: ${right.toStringAsFixed(1)}, b: ${bottom.toStringAsFixed(1)}, '
      'conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
