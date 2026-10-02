/// Centralized index mappings for Ultralytics YOLO Pose keypoints.
///
/// Standard COCO 17-Keypoint Layout used by YOLOv8-pose, YOLO11-pose:
/// 0:  Nose
/// 1:  Left Eye       2:  Right Eye
/// 3:  Left Ear       4:  Right Ear
/// 5:  Left Shoulder  6:  Right Shoulder
/// 7:  Left Elbow     8:  Right Elbow
/// 9:  Left Wrist     10: Right Wrist
/// 11: Left Hip       12: Right Hip
/// 13: Left Knee      14: Right Knee
/// 15: Left Ankle     16: Right Ankle
///
/// Note: If your supplied model uses a custom soccer layout with foot keypoints
/// (e.g. big toe, heel, small toe) or a 24-keypoint WholeBody model,
/// update the indices below without modifying any detection or UI code.
class YoloKeypointConstants {
  YoloKeypointConstants._();

  // Core Pose Indices (COCO Standard)
  static const int leftAnkle = 15;
  static const int rightAnkle = 16;
  static const int leftKnee = 13;
  static const int rightKnee = 14;
  static const int leftHip = 11;
  static const int rightHip = 12;

  // Extended Foot Indices (Configurable for custom toe/foot models)
  // Set to -1 or null if standard 17-keypoint COCO is used (falls back to ankles).
  static const int? leftBigToe = null;
  static const int? rightBigToe = null;

  // Class IDs for YOLO object detection outputs
  // COCO default: 0 = person, 32 = sports ball
  static const int personClassId = 0;
  static const int sportsBallClassId = 32;

  /// Helper to get the preferred keypoint index for left foot contact
  static int get primaryLeftFootIndex => leftBigToe ?? leftAnkle;

  /// Helper to get the preferred keypoint index for right foot contact
  static int get primaryRightFootIndex => rightBigToe ?? rightAnkle;
}
