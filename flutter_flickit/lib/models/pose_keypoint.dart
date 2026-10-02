/// Individual 2D anatomical pose keypoint produced by YOLO Pose.
class PoseKeypoint {
  final int index;
  final double x;
  final double y;
  final double confidence;
  final String? name;

  const PoseKeypoint({
    required this.index,
    required this.x,
    required this.y,
    required this.confidence,
    this.name,
  });

  bool get isValid => confidence > 0.0 && !x.isNaN && !y.isNaN;

  @override
  String toString() =>
      'PoseKeypoint(#$index, (${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}), '
      'conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
