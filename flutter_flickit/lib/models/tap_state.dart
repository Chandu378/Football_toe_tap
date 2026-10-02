import 'foot_detection.dart';

/// Finite states for toe-tap detection.
///
/// Lifecycle transition:
/// [idle] -> [approaching] -> [contact] -> [separated] -> [contact] / [idle]
enum TapState {
  /// Foot is far from the ball, or tracking has not yet initialized.
  idle,

  /// Foot is moving closer to the ball within the outer boundary zone.
  approaching,

  /// Foot has penetrated the ball's contact threshold.
  contact,

  /// Foot has rebounded/separated beyond the hysteresis separation threshold,
  /// resetting the gate for the next count.
  separated,
}

/// Tracks the dynamic detection state, counts, and timing for one foot (Left or Right).
class FootTapTracker {
  final FootSide side;
  TapState state;
  int tapCount;
  int missedFrames;
  int lastTapTimestampMs;
  double? lastCalculatedDistance;

  FootTapTracker({
    required this.side,
    this.state = TapState.idle,
    this.tapCount = 0,
    this.missedFrames = 0,
    this.lastTapTimestampMs = 0,
    this.lastCalculatedDistance,
  });

  /// Resets all counters and internal states.
  void reset() {
    state = TapState.idle;
    tapCount = 0;
    missedFrames = 0;
    lastTapTimestampMs = 0;
    lastCalculatedDistance = null;
  }

  FootTapTracker copy() {
    return FootTapTracker(
      side: side,
      state: state,
      tapCount: tapCount,
      missedFrames: missedFrames,
      lastTapTimestampMs: lastTapTimestampMs,
      lastCalculatedDistance: lastCalculatedDistance,
    );
  }
}
