import 'pose_keypoint.dart';

enum FootSide { left, right }

/// Detected foot/toe position derived from YOLO Pose keypoints.
class FootDetection {
  final FootSide side;
  final PoseKeypoint primaryKeypoint;
  final PoseKeypoint? ankleKeypoint;
  final PoseKeypoint? toeKeypoint;

  const FootDetection({
    required this.side,
    required this.primaryKeypoint,
    this.ankleKeypoint,
    this.toeKeypoint,
  });

  double get x => primaryKeypoint.x;
  double get y => primaryKeypoint.y;
  double get confidence => primaryKeypoint.confidence;

  @override
  String toString() =>
      'FootDetection(${side.name}, pos: (${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}), '
      'conf: ${(confidence * 100).toStringAsFixed(0)}%)';
}
