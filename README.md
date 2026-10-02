# Flickit — Flutter + Computer Vision Toe Tap Counter

A mobile computer vision application built with **Flutter**, **Dart**, and **Ultralytics YOLO Pose** designed to detect and count toe taps on a football in real time.

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Tech Stack](#tech-stack)
4. [Project Architecture](#project-architecture)
5. [Setup Instructions](#setup-instructions)
6. [Model Setup & Integration](#model-setup--integration)
7. [Running the Application](#running-the-application)
8. [Toe Tap Detection Approach](#toe-tap-detection-approach)
   - [Football Detection](#football-detection)
   - [Foot Keypoints](#foot-keypoints)
   - [Contact & Separation Thresholds (Hysteresis)](#contact--separation-thresholds-hysteresis)
   - [Debounce & Cooldown](#debounce--cooldown)
   - [Finite State Machine](#finite-state-machine)
   - [Duplicate Prevention](#duplicate-prevention)
   - [Handling Temporary Detection Failures](#handling-temporary-detection-failures)
9. [Performance Optimization](#performance-optimization)
10. [Testing](#testing)
11. [Known Limitations](#known-limitations)
12. [Debugging & Troubleshooting Guide](#debugging--troubleshooting-guide)

---

## Overview

Flickit tracks a player performing soccer toe taps on top of a football. Toe taps involve alternating left and right feet touching the top/surface of the ball and quickly bouncing back.

The real-time computer vision processing pipeline:
```
Camera Frame Stream (30 FPS)
        │
        ▼
Frame Throttler (10–15 FPS target)
        │
        ▼
Ultralytics YOLO Pose Inference
        │
        ├── Person Bounding Box
        ├── Football Bounding Box [left, top, right, bottom]
        └── Pose Keypoints [Left Ankle/Toe, Right Ankle/Toe]
        │
        ▼
Toe Tap State Machine (Hysteresis + Debounce)
        │
        ├── Left Foot Tracker  ──► Left Taps Count
        └── Right Foot Tracker ──► Right Taps Count
        │
        ▼
Real-Time HUD Overlay & Counter UI
```

---

## Features

- **Real-Time Camera Stream:** Ingests live video frames via `camera` plugin with lifecycle management and auto-recovery.
- **YOLO Pose Abstraction:** Decoupled `YoloService` interface allowing seamless swapping between TFLite, ONNX, and a built-in `MockYoloService` for emulator testing.
- **Dual-Foot State Machine:** Independent tracking of Left and Right feet with individual counters and total aggregate score.
- **Boundary Jitter Elimination (Hysteresis):** Dual thresholds (`CONTACT_THRESHOLD < SEPARATION_THRESHOLD`) ensure boundary noise never causes false repeated counts.
- **Duplicate Tap Prevention:** Consecutive contact frames are collapsed into a single physical tap; the foot must leave the separation boundary before another tap is registered.
- **Occlusion Tolerance:** Missed detection frames (up to `MAX_MISSED_FRAMES = 5`) do not reset tracking state, handling camera motion blur and temporary foot occlusions.
- **Real-Time Computer Vision Overlay:** Custom painter renders person bounding box, football bounding box, contact perimeter zone, foot keypoint positions, and distance vectors.
- **Performance Telemetry:** In-app telemetry monitors live FPS and inference latency (in ms).
- **Built-in Pose Simulator:** Instant emulator testing mode with oscillating foot movement and ball contact without requiring physical camera or football.

---

## Tech Stack

| Component | Library / Framework | Purpose |
|---|---|---|
| Framework | **Flutter 3.x / Dart 3.x** | Null-safe cross-platform mobile framework |
| Camera | `camera: ^0.10.5+9` | Camera preview and live image streaming |
| State Management | `provider: ^6.1.2` | Clean reactive ChangeNotifier separation |
| Math / Vectors | `vector_math: ^2.1.4` | Spatial Euclidean distance calculations |
| Computer Vision | **Ultralytics YOLO Pose** | Human pose keypoints and football detection |

---

## Project Architecture

The codebase adheres strictly to clean architecture principles:
```
lib/
├── main.dart                       # Entry point, orientation lock, status bar style
├── app.dart                        # FlickitApp widget and Material3 theme
├── config/
│   └── app_config.dart             # Central thresholds, cooldowns, and tuning flags
├── constants/
│   └── yolo_keypoint_constants.dart# COCO 17-keypoint and soccer keypoint mappings
├── models/
│   ├── bounding_box.dart           # Geometric box calculations (center, radius, distance)
│   ├── pose_keypoint.dart          # 2D keypoint with confidence scores
│   ├── foot_detection.dart         # Left/Right foot keypoint model
│   ├── ball_detection.dart         # Football center and bounding box model
│   ├── detection_result.dart       # Consolidated YOLO frame output
│   └── tap_state.dart              # TapState enum and FootTapTracker
├── services/
│   ├── camera_service.dart         # Camera initialization, streaming, and teardown
│   ├── yolo_service.dart           # YoloService interface & production TFLite placeholder
│   ├── mock_yolo_service.dart      # Realistic simulator for emulator validation
│   └── toe_tap_detector.dart       # Core state machine and hysteresis algorithm
├── controllers/
│   └── tap_counter_controller.dart # Orchestrator binding Camera, ML, and UI
├── screens/
│   └── tap_counter_screen.dart     # Camera preview, HUD overlay, and counter controls
├── widgets/
│   ├── camera_preview_widget.dart  # Responsive video preview / simulator background
│   ├── detection_overlay.dart      # CustomPainter rendering boxes, points, & vectors
│   ├── stat_badge.dart             # Performance badges (FPS, Latency, Mode)
│   └── control_bar.dart            # START, PAUSE, RESET, and Mode toggle buttons
└── utils/
    └── geometry_utils.dart         # Euclidean distance and contact calculations
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK `>=3.0.0`
- Android Studio / VS Code with Flutter extension
- Android SDK with minimum API 21 (`minSdkVersion = 21`)

### Clone & Install
```bash
cd flutter_flickit
flutter pub get
```

---

## Model Setup & Integration

### Supported Model Formats
The application accepts standard **Ultralytics YOLOv8-pose** or **YOLO11-pose** models exported for mobile deployment:
1. **TensorFlow Lite (`.tflite`)** (Recommended for Android / TFLite runtime)
2. **ONNX (`.onnx`)** (Recommended for cross-platform ONNX Runtime)

### Exporting from Ultralytics
If you have the PyTorch weights (`.pt`), export them with the official Ultralytics CLI:
```bash
# Export to TensorFlow Lite
yolo export model=yolov8n-pose.pt format=tflite imgsz=640

# Or export to ONNX
yolo export model=yolov8n-pose.pt format=onnx imgsz=640
```

### Inserting the Model File
1. Place your exported model file into:
   ```
   flutter_flickit/assets/models/yolov8n-pose.tflite
   ```
2. In `lib/config/app_config.dart`, verify or update `modelAssetPath`:
   ```dart
   static const String modelAssetPath = 'assets/models/yolov8n-pose.tflite';
   ```
3. To switch from `MockYoloService` to `RealYoloPoseService`, inject the real service in `main.dart` or `tap_counter_controller.dart`:
   ```dart
   TapCounterController(
     yoloService: RealYoloPoseService(modelPath: AppConfig.modelAssetPath),
   );
   ```

### Output Tensor Parsing
Ultralytics YOLOv8-pose produces an output tensor of shape `[1, 56, 8400]`:
- Coordinates `[0..3]`: Box center `cx`, `cy`, width `w`, height `h`.
- Coordinate `[4]`: Person / object confidence.
- Coordinates `[5..55]`: 17 Keypoints $\times$ 3 values each (`kx`, `ky`, `confidence`).

Keypoints mapping (configured in `yolo_keypoint_constants.dart`):
- `15`: Left Ankle
- `16`: Right Ankle
- Custom toe indices can be set in `YoloKeypointConstants.leftBigToe` / `rightBigToe`.

---

## Running the Application

### 1. Run on Connected Device or Emulator
```bash
flutter run
```

### 2. Run Unit Tests
```bash
flutter test
```

---

## Toe Tap Detection Approach

### 1. Football Detection
The football is detected from the YOLO class output (COCO class 32 or custom class 0).
The bounding box provides:
$$\text{center}_x = \text{left} + \frac{\text{width}}{2}, \quad \text{center}_y = \text{top} + \frac{\text{height}}{2}$$
$$\text{approximateRadius} = \frac{\text{width} + \text{height}}{4}$$
Distance to perimeter:
$$\text{distToBall} = \max(0, \text{euclideanDistance}(\text{foot}, \text{ballCenter}) - \text{radius})$$

### 2. Foot Keypoints
Extracted from YOLO Pose keypoints:
- `primaryLeftFoot = leftBigToe ?? leftAnkle (15)`
- `primaryRightFoot = rightBigToe ?? rightAnkle (16)`

### 3. Contact & Separation Thresholds (Hysteresis)
A single threshold causes false oscillating triggers when a foot lingers near the boundary. Flickit implements **Schmitt-trigger hysteresis**:
- `CONTACT_THRESHOLD = 45.0 px`: Foot must get closer than this to trigger a tap.
- `SEPARATION_THRESHOLD = 75.0 px`: Foot must retreat beyond this before another tap can be registered.

Because $75.0 > 45.0$, micro-vibrations between 45 px and 75 px cannot cause duplicate counts.

### 4. Debounce & Cooldown
- `TAP_COOLDOWN_MS = 350 ms`: Enforces the physiological minimum time between successive taps on the same foot.

### 5. Finite State Machine
```
       ┌───────────────────────────────┐
       │             IDLE              │
       └───────────────┬───────────────┘
                       │ (dist > separationThreshold)
                       ▼
       ┌───────────────────────────────┐
  ┌───►│           SEPARATED           │◄───┐
  │    └───────────────┬───────────────┘    │
  │                    │                    │
  │                    │ (dist <= contactThreshold)
  │                    │ [Count + 1, Cooldown reset]
  │                    ▼                    │
  │    ┌───────────────────────────────┐    │
  │    │            CONTACT            │────┘
  │    └───────────────┬───────────────┘  (dist > separationThreshold)
  │                    │
  │                    │ (consecutive frames in contact)
  │                    ▼
  └─────── Duplicate Tap Prevented!
```

### 6. Duplicate Prevention
When consecutive video frames maintain contact ($d \le 45\text{ px}$):
- Frame 1: $\text{SEPARATED} \to \text{CONTACT} \implies \text{Count} = 1$
- Frame 2: $\text{CONTACT} \to \text{CONTACT} \implies \text{Count unchanged}$
- Frame 3: $\text{CONTACT} \to \text{CONTACT} \implies \text{Count unchanged}$
- Frame 4: $\text{CONTACT} \to \text{CONTACT} \implies \text{Count unchanged}$

### 7. Handling Temporary Detection Failures
If the ball or foot is momentarily occluded by motion blur:
- An internal counter `missedFrames` increments.
- While `missedFrames <= MAX_MISSED_FRAMES (5)`, the previous state is preserved.
- When detection returns, `missedFrames` resets to 0 with zero state corruption.
- If missing for $> 5$ frames, the foot safely resets to `IDLE`.

---

## Performance Optimization

1. **Frame Throttling:** Camera feeds frames at 30 FPS. The controller drops non-target frames, executing inference every `INFERENCE_INTERVAL_MS = 66 ms` (~15 FPS).
2. **Concurrency Lock:** `_isInferenceRunning` prevents queued execution or thread deadlocks.
3. **Decoupled CustomPainter:** Overlay redraws strictly on new detection frames without rebuilding the underlying video preview widget.

---

## Testing

8 exhaustive unit tests cover all edge cases in `test/toe_tap_detector_test.dart`:

```bash
flutter test test/toe_tap_detector_test.dart
```

1. **Test 1:** Foot far from ball $\implies$ no tap.
2. **Test 2:** Foot approaching in intermediate zone $\implies$ no premature tap.
3. **Test 3:** Foot contacts ball $\implies$ tap count = 1.
4. **Test 4:** 5 consecutive contact frames $\implies$ tap count stays 1 (no duplicate).
5. **Test 5:** Foot separates and contacts again after cooldown $\implies$ tap count = 2.
6. **Test 6:** Temporary missing frames (occlusion) $\implies$ state retained; safely resets after $> 5$ frames.
7. **Test 7:** Left and right foot tap independently $\implies$ independent counts and combined total.
8. **Test 8:** Reset $\implies$ all counts, states, and timers return to zero.

---

## Known Limitations

- **Lighting & Glare:** Low-light environments reduce YOLO pose confidence on lower limbs.
- **Footwear Camouflage:** Black boots on dark turf can occasionally lower keypoint confidence.
- **Camera Perspective:** Best results are achieved with the phone placed vertically at ground level or knee height 2 to 3 meters away.
- **Hardware Acceleration:** Real-time 640x640 pose inference requires an NPU/GPU delegate (NNAPI on Android) on entry-level devices.

---

## Debugging & Troubleshooting Guide

| Issue | Cause | Solution |
|---|---|---|
| Camera permission denied | Android 6+ runtime permission not granted | Check system settings or accept prompt |
| No camera found | Running on an emulator without virtual camera | Flickit automatically falls back to **Simulator Mode** |
| Model failed to load | Incorrect asset path or missing in `pubspec.yaml` | Ensure path is listed under `flutter.assets` |
| Low FPS (<10 FPS) | Model too large for CPU inference | Use `yolov8n-pose` (nano) with INT8 quantization or enable NNAPI delegate |
