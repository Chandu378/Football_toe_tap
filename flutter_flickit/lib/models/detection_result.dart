import 'ball_detection.dart';
import 'bounding_box.dart';
import 'foot_detection.dart';
import 'pose_keypoint.dart';

/// Aggregated output resulting from a single YOLO inference pass on a video frame.
class DetectionResult {
  /// Bounding box of the primary detected person performing toe taps.
  final BoundingBox? personBox;

  /// Detected football with bounding box and confidence.
  final BallDetection? ball;

  /// Left foot/toe keypoint and position.
  final FootDetection? leftFoot;

  /// Right foot/toe keypoint and position.
  final FootDetection? rightFoot;

  /// Complete list of detected pose keypoints for the primary person.
  final List<PoseKeypoint> allKeypoints;

  /// Inference duration in milliseconds for this frame.
  final int inferenceTimeMs;

  /// Timestamp when inference completed.
  final int timestampMs;

  /// Frame image width in pixels.
  final double imageWidth;

  /// Frame image height in pixels.
  final double imageHeight;

  const DetectionResult({
    this.personBox,
    this.ball,
    this.leftFoot,
    this.rightFoot,
    this.allKeypoints = const [],
    this.inferenceTimeMs = 0,
    this.timestampMs = 0,
    this.imageWidth = 640.0,
    this.imageHeight = 480.0,
  });

  bool get hasBall => ball != null;
  bool get hasAnyFoot => leftFoot != null || rightFoot != null;
  bool get hasPerson => personBox != null;

  static const DetectionResult empty = DetectionResult();

  @override
  String toString() =>
      'DetectionResult(person: ${personBox != null}, ball: ${ball != null}, '
      'leftFoot: ${leftFoot != null}, rightFoot: ${rightFoot != null}, '
      'latency: ${inferenceTimeMs}ms)';
}
