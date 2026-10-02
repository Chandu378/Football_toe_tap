/// Application-wide configuration and algorithmic tuning constants.
///
/// Magic numbers are centralized here to allow easy calibration
/// depending on camera resolution, user distance, and model output characteristics.
class AppConfig {
  AppConfig._();

  // ==========================================
  // TOE TAP DETECTION THRESHOLDS (HYSTERESIS)
  // ==========================================

  /// Maximum pixel/distance threshold between the foot keypoint and the
  /// football boundary/center to declare a "CONTACT" event.
  /// When normalized coordinates (0.0 to 1.0) are used, this corresponds
  /// to normalized distance. In absolute image pixels (e.g. 640x480),
  /// adjust or multiply by frame scale factor.
  static const double contactThreshold = 45.0;

  /// Distance threshold that the foot must exceed before another tap can
  /// be registered. Because [separationThreshold] > [contactThreshold],
  /// hysteresis prevents boundary jitter from registering false multiple taps.
  static const double separationThreshold = 75.0;

  /// Minimum time (in milliseconds) required between successive tap events
  /// on the same foot. Prevents rapid duplicate tap registrations in case
  /// of foot micro-oscillations near the ball.
  static const int tapCooldownMs = 350;

  /// Number of consecutive missing detection frames tolerated before the
  /// state machine resets tracking state to IDLE.
  static const int maxMissedFrames = 5;

  // ==========================================
  // PERFORMANCE & THROTTLING
  // ==========================================

  /// Minimum duration between consecutive YOLO inference passes (in milliseconds).
  /// For instance, 66 ms targets ~15 FPS inference while camera preview runs at 30 FPS.
  /// Prevents GPU/CPU thermal throttling and UI stutters.
  static const int inferenceIntervalMs = 66;

  /// Toggle visual bounding boxes, keypoints, and contact zone lines on the overlay.
  static const bool showDebugOverlay = true;

  /// Toggle FPS and inference latency overlay metrics.
  static const bool showPerformanceStats = true;

  // ==========================================
  // MODEL CONFIGURATION & ASSET PLACEHOLDERS
  // ==========================================

  /// Path to the provided Ultralytics YOLO Pose model asset.
  /// Supported mobile formats: .tflite, .onnx, or TorchScript mobile.
  /// Place the provided file into `assets/models/` and update this filename if needed.
  static const String modelAssetPath = 'assets/models/yolov8n-pose.tflite';

  /// Minimum detection confidence required to accept a person detection.
  static const double personConfidenceThreshold = 0.40;

  /// Minimum detection confidence required to accept a football detection.
  static const double ballConfidenceThreshold = 0.35;

  /// Minimum confidence score required to accept a pose keypoint (ankle/toe).
  static const double keypointConfidenceThreshold = 0.30;
}
