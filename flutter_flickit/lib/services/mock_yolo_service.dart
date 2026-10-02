import 'dart:math' as math;
import 'package:camera/camera.dart';
import '../constants/yolo_keypoint_constants.dart';
import '../models/ball_detection.dart';
import '../models/bounding_box.dart';
import '../models/detection_result.dart';
import '../models/foot_detection.dart';
import '../models/pose_keypoint.dart';
import 'yolo_service.dart';

/// Realistic simulation engine for Ultralytics YOLO Pose output.
///
/// Generates realistic person body bounding box, football bounding box,
/// and oscillating left/right foot keypoints to simulate toe taps.
/// Essential for:
/// 1. Testing on Android emulators without a physical camera or soccer ball.
/// 2. Validating the state machine, hysteresis, and UI rendering before inserting model weights.
class MockYoloService implements YoloService {
  bool _isLoaded = false;
  int _frameCounter = 0;

  @override
  bool get isModelLoaded => _isLoaded;

  @override
  String get engineName => 'Mock YOLO Pose (Simulator)';

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoaded = true;
  }

  @override
  Future<DetectionResult> processCameraImage(CameraImage image) async {
    // When live camera stream is active, generate realistic detection
    // scaled to image dimensions
    return generateSimulatedDetection(
      width: image.width.toDouble(),
      height: image.height.toDouble(),
    );
  }

  /// Generates a realistic frame with alternating toe taps
  DetectionResult generateSimulatedDetection({
    double width = 640.0,
    double height = 480.0,
  }) {
    final stopwatch = Stopwatch()..start();
    _frameCounter++;

    final ballCenterX = width * 0.50;
    final ballCenterY = height * 0.72;
    final ballRadius = width * 0.08;

    final ballBox = BoundingBox(
      left: ballCenterX - ballRadius,
      top: ballCenterY - ballRadius,
      right: ballCenterX + ballRadius,
      bottom: ballCenterY + ballRadius,
      confidence: 0.94,
      classId: YoloKeypointConstants.sportsBallClassId,
    );

    final personBox = BoundingBox(
      left: width * 0.25,
      top: height * 0.15,
      right: width * 0.75,
      bottom: height * 0.88,
      confidence: 0.96,
      classId: YoloKeypointConstants.personClassId,
    );

    // Oscillation period for alternating foot taps
    // Cycle is 60 frames:
    // Frame 0-25: Right foot moves down, contacts at frame 15, moves up
    // Frame 30-55: Left foot moves down, contacts at frame 45, moves up
    final cycle = _frameCounter % 60;

    double rightFootY;
    double leftFootY;

    // Contact position is slightly on top edge of ball
    final contactY = ballBox.top + 8.0;
    final separatedY = ballBox.top - 80.0;

    if (cycle < 30) {
      // Right foot tapping cycle
      // Normal sine wave dip
      final progress = math.sin((cycle / 30.0) * math.pi);
      rightFootY = separatedY + progress * (contactY - separatedY);
      leftFootY = separatedY;
    } else {
      // Left foot tapping cycle
      final progress = math.sin(((cycle - 30) / 30.0) * math.pi);
      leftFootY = separatedY + progress * (contactY - separatedY);
      rightFootY = separatedY;
    }

    final rightFootX = ballCenterX + 15.0;
    final leftFootX = ballCenterX - 15.0;

    final leftFootKeypoint = PoseKeypoint(
      index: YoloKeypointConstants.leftAnkle,
      x: leftFootX,
      y: leftFootY,
      confidence: 0.92,
      name: 'left_ankle',
    );

    final rightFootKeypoint = PoseKeypoint(
      index: YoloKeypointConstants.rightAnkle,
      x: rightFootX,
      y: rightFootY,
      confidence: 0.93,
      name: 'right_ankle',
    );

    final allKeypoints = [
      PoseKeypoint(index: 0, x: width * 0.5, y: height * 0.22, confidence: 0.95, name: 'nose'),
      PoseKeypoint(index: 5, x: width * 0.42, y: height * 0.32, confidence: 0.91, name: 'left_shoulder'),
      PoseKeypoint(index: 6, x: width * 0.58, y: height * 0.32, confidence: 0.91, name: 'right_shoulder'),
      PoseKeypoint(index: 11, x: width * 0.45, y: height * 0.52, confidence: 0.88, name: 'left_hip'),
      PoseKeypoint(index: 12, x: width * 0.55, y: height * 0.52, confidence: 0.88, name: 'right_hip'),
      PoseKeypoint(index: 13, x: width * 0.46, y: height * 0.62, confidence: 0.85, name: 'left_knee'),
      PoseKeypoint(index: 14, x: width * 0.54, y: height * 0.62, confidence: 0.85, name: 'right_knee'),
      leftFootKeypoint,
      rightFootKeypoint,
    ];

    stopwatch.stop();

    return DetectionResult(
      personBox: personBox,
      ball: BallDetection(
        box: ballBox,
        confidence: 0.94,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
      leftFoot: FootDetection(
        side: FootSide.left,
        primaryKeypoint: leftFootKeypoint,
        ankleKeypoint: leftFootKeypoint,
      ),
      rightFoot: FootDetection(
        side: FootSide.right,
        primaryKeypoint: rightFootKeypoint,
        ankleKeypoint: rightFootKeypoint,
      ),
      allKeypoints: allKeypoints,
      inferenceTimeMs: 14 + (math.Random().nextInt(6)), // realistic 14-20ms latency
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      imageWidth: width,
      imageHeight: height,
    );
  }

  @override
  void dispose() {
    _isLoaded = false;
  }
}
