import 'package:flutter_test/flutter_test.dart';
import '../lib/models/ball_detection.dart';
import '../lib/models/bounding_box.dart';
import '../lib/models/detection_result.dart';
import '../lib/models/foot_detection.dart';
import '../lib/models/pose_keypoint.dart';
import '../lib/models/tap_state.dart';
import '../lib/services/toe_tap_detector.dart';

void main() {
  group('ToeTapDetector Algorithmic Unit Tests', () {
    late ToeTapDetector detector;

    // Standard football centered at (300, 400) with width=100, height=100 (radius=50)
    // Box bounds: left=250, top=350, right=350, bottom=450
    final standardBall = BallDetection(
      box: const BoundingBox(
        left: 250,
        top: 350,
        right: 350,
        bottom: 450,
        confidence: 0.95,
      ),
      confidence: 0.95,
      timestampMs: 1000,
    );

    DetectionResult createFrame({
      required double footX,
      required double footY,
      FootSide side = FootSide.right,
      int timestampMs = 1000,
      bool includeBall = true,
      bool includeFoot = true,
    }) {
      final keypoint = PoseKeypoint(
        index: side == FootSide.right ? 16 : 15,
        x: footX,
        y: footY,
        confidence: 0.9,
      );

      final foot = includeFoot
          ? FootDetection(side: side, primaryKeypoint: keypoint)
          : null;

      return DetectionResult(
        ball: includeBall ? standardBall : null,
        leftFoot: side == FootSide.left ? foot : null,
        rightFoot: side == FootSide.right ? foot : null,
        timestampMs: timestampMs,
      );
    }

    setUp(() {
      detector = ToeTapDetector(
        contactThreshold: 45.0,
        separationThreshold: 75.0,
        tapCooldownMs: 350,
        maxMissedFrames: 5,
      );
    });

    test('Test 1: Foot far from ball -> no tap counted', () {
      // Foot at (300, 100): distance to ball perimeter is ~200px > 75px
      final frame = createFrame(footX: 300, footY: 100, timestampMs: 1000);
      final newTaps = detector.processFrame(frame);

      expect(newTaps, equals(0));
      expect(detector.totalTaps, equals(0));
      expect(detector.rightState, equals(TapState.separated));
    });

    test('Test 2: Foot approaches ball -> no premature duplicate taps', () {
      // Frame 1: Foot separated at distance ~150px
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      expect(detector.totalTaps, equals(0));
      expect(detector.rightState, equals(TapState.separated));

      // Frame 2: Foot approaches within intermediate zone (distance ~60px, between 45 and 75)
      // Ball top edge is at y=350, foot at y=290 -> distance = 60px
      detector.processFrame(createFrame(footX: 300, footY: 290, timestampMs: 1050));
      expect(detector.totalTaps, equals(0));
      expect(detector.rightState, equals(TapState.approaching));

      // Frame 3: Foot still in intermediate zone at y=295 (distance = 55px)
      detector.processFrame(createFrame(footX: 300, footY: 295, timestampMs: 1100));
      expect(detector.totalTaps, equals(0));
      expect(detector.rightState, equals(TapState.approaching));
    });

    test('Test 3: Foot contacts ball -> count 1', () {
      // Start separated
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      expect(detector.totalTaps, equals(0));

      // Foot contacts ball: foot at y=340 (distance to top edge 350 is 10px <= contactThreshold 45)
      final newTaps = detector.processFrame(
        createFrame(footX: 300, footY: 340, timestampMs: 1100),
      );

      expect(newTaps, equals(1));
      expect(detector.totalTaps, equals(1));
      expect(detector.rightTaps, equals(1));
      expect(detector.rightState, equals(TapState.contact));
    });

    test('Test 4: Several consecutive contact frames -> still count 1 (no duplicates)', () {
      // Setup initial tap
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      detector.processFrame(createFrame(footX: 300, footY: 340, timestampMs: 1100));
      expect(detector.totalTaps, equals(1));

      // 5 consecutive frames in contact
      for (int i = 1; i <= 5; i++) {
        final newTaps = detector.processFrame(
          createFrame(footX: 300, footY: 335 + (i * 2.0), timestampMs: 1100 + (i * 50)),
        );
        expect(newTaps, equals(0), reason: 'Frame $i should not register duplicate tap');
        expect(detector.totalTaps, equals(1));
        expect(detector.rightState, equals(TapState.contact));
      }
    });

    test('Test 5: Foot separates and contacts again -> count 2', () {
      // Tap 1
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      detector.processFrame(createFrame(footX: 300, footY: 340, timestampMs: 1100));
      expect(detector.totalTaps, equals(1));

      // Foot lifts up and separates beyond separationThreshold (75px)
      // Ball top is 350. y=250 means distance is 100px > 75px
      detector.processFrame(createFrame(footX: 300, footY: 250, timestampMs: 1300));
      expect(detector.rightState, equals(TapState.separated));
      expect(detector.totalTaps, equals(1));

      // Foot contacts ball again after cooldown (>350ms elapsed since 1100ms)
      final secondTap = detector.processFrame(
        createFrame(footX: 300, footY: 345, timestampMs: 1600),
      );

      expect(secondTap, equals(1));
      expect(detector.totalTaps, equals(2));
      expect(detector.rightTaps, equals(2));
      expect(detector.rightState, equals(TapState.contact));
    });

    test('Test 6: Temporary missing detection -> state does not immediately break', () {
      // Tap 1
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      detector.processFrame(createFrame(footX: 300, footY: 340, timestampMs: 1100));
      expect(detector.rightState, equals(TapState.contact));

      // 3 missing frames (foot or ball obscured)
      for (int i = 1; i <= 3; i++) {
        detector.processFrame(
          createFrame(footX: 0, footY: 0, includeFoot: false, timestampMs: 1100 + (i * 30)),
        );
        // State should still be retained because missedFrames (3) <= maxMissedFrames (5)
        expect(detector.rightState, equals(TapState.contact));
      }

      // Detection recovers on frame 4 still in contact
      detector.processFrame(createFrame(footX: 300, footY: 340, timestampMs: 1250));
      expect(detector.rightTracker.missedFrames, equals(0));
      expect(detector.rightState, equals(TapState.contact));
      expect(detector.totalTaps, equals(1));

      // Now simulate 6 consecutive missing frames -> state should safely reset to idle
      for (int i = 1; i <= 6; i++) {
        detector.processFrame(
          createFrame(footX: 0, footY: 0, includeBall: false, timestampMs: 1300 + (i * 30)),
        );
      }
      expect(detector.rightState, equals(TapState.idle));
    });

    test('Test 7: Left and right foot tap independently', () {
      // Start both feet far away
      final startBothFrame = DetectionResult(
        ball: standardBall,
        leftFoot: const FootDetection(
          side: FootSide.left,
          primaryKeypoint: PoseKeypoint(index: 15, x: 100, y: 100, confidence: 0.9),
        ),
        rightFoot: const FootDetection(
          side: FootSide.right,
          primaryKeypoint: PoseKeypoint(index: 16, x: 500, y: 100, confidence: 0.9),
        ),
        timestampMs: 1000,
      );
      detector.processFrame(startBothFrame);

      // Left foot taps ball at (290, 340)
      final leftTapFrame = DetectionResult(
        ball: standardBall,
        leftFoot: const FootDetection(
          side: FootSide.left,
          primaryKeypoint: PoseKeypoint(index: 15, x: 290, y: 340, confidence: 0.9),
        ),
        rightFoot: const FootDetection(
          side: FootSide.right,
          primaryKeypoint: PoseKeypoint(index: 16, x: 500, y: 100, confidence: 0.9),
        ),
        timestampMs: 1100,
      );
      detector.processFrame(leftTapFrame);

      expect(detector.leftTaps, equals(1));
      expect(detector.rightTaps, equals(0));
      expect(detector.totalTaps, equals(1));

      // Right foot taps ball at (310, 340) while left foot has separated
      final rightTapFrame = DetectionResult(
        ball: standardBall,
        leftFoot: const FootDetection(
          side: FootSide.left,
          primaryKeypoint: PoseKeypoint(index: 15, x: 100, y: 100, confidence: 0.9),
        ),
        rightFoot: const FootDetection(
          side: FootSide.right,
          primaryKeypoint: PoseKeypoint(index: 16, x: 310, y: 340, confidence: 0.9),
        ),
        timestampMs: 1500,
      );
      detector.processFrame(rightTapFrame);

      expect(detector.leftTaps, equals(1));
      expect(detector.rightTaps, equals(1));
      expect(detector.totalTaps, equals(2));
    });

    test('Test 8: Reset -> all counters and states return to zero', () {
      // Accumulate some taps
      detector.processFrame(createFrame(footX: 300, footY: 150, timestampMs: 1000));
      detector.processFrame(createFrame(footX: 300, footY: 340, timestampMs: 1100));
      expect(detector.totalTaps, equals(1));

      // Call reset
      detector.reset();

      expect(detector.totalTaps, equals(0));
      expect(detector.leftTaps, equals(0));
      expect(detector.rightTaps, equals(0));
      expect(detector.leftState, equals(TapState.idle));
      expect(detector.rightState, equals(TapState.idle));
      expect(detector.leftTracker.missedFrames, equals(0));
      expect(detector.rightTracker.missedFrames, equals(0));
      expect(detector.leftTracker.lastTapTimestampMs, equals(0));
      expect(detector.rightTracker.lastTapTimestampMs, equals(0));
    });
  });
}
