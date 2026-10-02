import '../config/app_config.dart';
import '../models/ball_detection.dart';
import '../models/detection_result.dart';
import '../models/foot_detection.dart';
import '../models/tap_state.dart';
import '../utils/geometry_utils.dart';

/// Core algorithmic engine that identifies toe taps on a football using state-machine
/// logic, spatial hysteresis, frame tolerance, and temporal cooldown.
///
/// This class is strictly decoupled from Flutter UI widgets and camera plugins
/// to enable 100% deterministic unit testing and cross-platform portability.
class ToeTapDetector {
  final double contactThreshold;
  final double separationThreshold;
  final int tapCooldownMs;
  final int maxMissedFrames;

  // Trackers for left and right foot independently
  final FootTapTracker leftTracker = FootTapTracker(side: FootSide.left);
  final FootTapTracker rightTracker = FootTapTracker(side: FootSide.right);

  ToeTapDetector({
    this.contactThreshold = AppConfig.contactThreshold,
    this.separationThreshold = AppConfig.separationThreshold,
    this.tapCooldownMs = AppConfig.tapCooldownMs,
    this.maxMissedFrames = AppConfig.maxMissedFrames,
  }) {
    assert(
      separationThreshold >= contactThreshold,
      'Separation threshold must be greater than or equal to contact threshold for hysteresis!',
    );
  }

  /// Total combined taps from both left and right feet.
  int get totalTaps => leftTracker.tapCount + rightTracker.tapCount;
  int get leftTaps => leftTracker.tapCount;
  int get rightTaps => rightTracker.tapCount;

  TapState get leftState => leftTracker.state;
  TapState get rightState => rightTracker.state;

  /// Resets all counters, states, missed frame counts, and cooldown timestamps.
  void reset() {
    leftTracker.reset();
    rightTracker.reset();
  }

  /// Processes a single frame's detection result and updates the state machine.
  ///
  /// Returns the number of new taps counted in this exact frame (0, 1, or 2).
  int processFrame(DetectionResult detection) {
    final now = detection.timestampMs > 0
        ? detection.timestampMs
        : DateTime.now().millisecondsSinceEpoch;

    final ball = detection.ball;

    int newTapsThisFrame = 0;

    // Process Left Foot
    newTapsThisFrame += _updateFootTracker(
      tracker: leftTracker,
      foot: detection.leftFoot,
      ball: ball,
      currentTimestampMs: now,
    );

    // Process Right Foot
    newTapsThisFrame += _updateFootTracker(
      tracker: rightTracker,
      foot: detection.rightFoot,
      ball: ball,
      currentTimestampMs: now,
    );

    return newTapsThisFrame;
  }

  /// Core single-foot state transition step.
  int _updateFootTracker({
    required FootTapTracker tracker,
    required FootDetection? foot,
    required BallDetection? ball,
    required int currentTimestampMs,
  }) {
    // 1. Check for temporary detection failures (missing ball or missing foot)
    if (ball == null || foot == null) {
      tracker.missedFrames++;
      // Retain state for up to maxMissedFrames; reset to idle if missing too long
      if (tracker.missedFrames > maxMissedFrames) {
        tracker.state = TapState.idle;
        tracker.lastCalculatedDistance = null;
      }
      return 0;
    }

    // Detection is valid in this frame: reset missed frames counter
    tracker.missedFrames = 0;

    // 2. Calculate distance between foot keypoint and ball perimeter
    final distance = GeometryUtils.effectiveDistanceToBall(
      footX: foot.x,
      footY: foot.y,
      ballBox: ball.box,
    );
    tracker.lastCalculatedDistance = distance;

    int tapsRegistered = 0;

    // 3. State Machine with Hysteresis & Debounce
    switch (tracker.state) {
      case TapState.idle:
        // Transition from IDLE:
        // If foot is outside separation zone, move to separated
        if (distance > separationThreshold) {
          tracker.state = TapState.separated;
        } else if (distance > contactThreshold) {
          tracker.state = TapState.approaching;
        } else {
          // Foot started already inside contact threshold (e.g., initial frame placement)
          // Do NOT count immediately to prevent false triggers on startup; mark contact
          tracker.state = TapState.contact;
        }
        break;

      case TapState.separated:
      case TapState.approaching:
        // Foot is approaching or separated: check for CONTACT event
        if (distance <= contactThreshold) {
          // Check cooldown / debounce
          final elapsedSinceLastTap = currentTimestampMs - tracker.lastTapTimestampMs;
          if (elapsedSinceLastTap >= tapCooldownMs) {
            // Valid toe-tap registered!
            tracker.tapCount++;
            tracker.lastTapTimestampMs = currentTimestampMs;
            tracker.state = TapState.contact;
            tapsRegistered = 1;
          } else {
            // Still within cooldown period, enter contact state without incrementing count
            tracker.state = TapState.contact;
          }
        } else if (distance <= separationThreshold) {
          // In the intermediate zone between contactThreshold and separationThreshold
          tracker.state = TapState.approaching;
        } else {
          tracker.state = TapState.separated;
        }
        break;

      case TapState.contact:
        // Consecutive contact frames:
        // Foot stays in CONTACT while distance is <= separationThreshold (hysteresis)
        // Only when distance EXCEEDS separationThreshold does it transition to SEPARATED.
        if (distance > separationThreshold) {
          tracker.state = TapState.separated;
        }
        // If still <= separationThreshold, retain TapState.contact (duplicate count prevented!)
        break;
    }

    return tapsRegistered;
  }
}
