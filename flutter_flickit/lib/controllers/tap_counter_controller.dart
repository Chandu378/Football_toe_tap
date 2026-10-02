import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/detection_result.dart';
import '../models/tap_state.dart';
import '../services/camera_service.dart';
import '../services/mock_yolo_service.dart';
import '../services/toe_tap_detector.dart';
import '../services/yolo_service.dart';

/// Central state controller binding Camera, YOLO Pose Inference,
/// Toe-Tap Detection, and UI state.
class TapCounterController extends ChangeNotifier {
  final CameraService _cameraService = CameraService();
  final ToeTapDetector _detector = ToeTapDetector();
  late YoloService _yoloService;

  // Session State
  bool _isRunning = false;
  bool _isCameraReady = false;
  bool _isSimulationMode = false;
  String? _statusMessage;

  // Inference Guard & Throttling
  bool _isInferenceRunning = false;
  int _lastInferenceTimestampMs = 0;
  Timer? _simulationTimer;

  // Performance Telemetry
  int _fpsCounter = 0;
  int _currentFps = 0;
  int _lastFpsWindowTimestampMs = 0;
  int _currentInferenceLatencyMs = 0;

  // Current Frame Results
  DetectionResult _lastDetectionResult = DetectionResult.empty;

  TapCounterController({YoloService? yoloService}) {
    _yoloService = yoloService ?? MockYoloService();
  }

  // Getters for UI
  CameraService get cameraService => _cameraService;
  ToeTapDetector get detector => _detector;
  YoloService get yoloService => _yoloService;

  bool get isRunning => _isRunning;
  bool get isCameraReady => _isCameraReady;
  bool get isSimulationMode => _isSimulationMode;
  String? get statusMessage => _statusMessage;

  int get totalTaps => _detector.totalTaps;
  int get leftTaps => _detector.leftTaps;
  int get rightTaps => _detector.rightTaps;
  TapState get leftState => _detector.leftState;
  TapState get rightState => _detector.rightState;

  int get fps => _currentFps;
  int get latencyMs => _currentInferenceLatencyMs;
  DetectionResult get currentDetection => _lastDetectionResult;

  /// Initializes camera hardware and loads YOLO model.
  Future<void> initialize() async {
    _statusMessage = 'Initializing YOLO Pose model...';
    notifyListeners();

    try {
      await _yoloService.initialize();

      _statusMessage = 'Initializing camera preview...';
      notifyListeners();

      final cameraOk = await _cameraService.initialize();
      _isCameraReady = cameraOk;

      if (!cameraOk) {
        // Fallback to simulation mode if on emulator or camera permission is denied
        _isSimulationMode = true;
        _statusMessage = 'Camera unavailable: running in Pose Simulation mode.';
      } else {
        _statusMessage = 'Ready. Press START to begin toe tap tracking.';
      }
    } catch (e) {
      _isSimulationMode = true;
      _statusMessage = 'Initialized with fallback simulator: ${e.toString()}';
    }

    notifyListeners();
  }

  /// Starts the toe-tap tracking session.
  Future<void> startSession() async {
    if (_isRunning) return;

    _isRunning = true;
    _statusMessage = 'Tracking active! Tap the ball with your toes.';
    notifyListeners();

    if (_isCameraReady && !_isSimulationMode) {
      await _cameraService.startImageStream(_handleCameraFrame);
    } else {
      _startSimulationLoop();
    }
  }

  /// Stops/pauses the toe-tap tracking session.
  Future<void> stopSession() async {
    if (!_isRunning) return;

    _isRunning = false;
    _statusMessage = 'Session paused.';
    _simulationTimer?.cancel();
    _simulationTimer = null;

    if (_cameraService.isStreaming) {
      await _cameraService.stopImageStream();
    }

    notifyListeners();
  }

  /// Resets all counters, state machines, and debouncers back to zero.
  void reset() {
    _detector.reset();
    _lastDetectionResult = DetectionResult.empty;
    _fpsCounter = 0;
    _currentFps = 0;
    _currentInferenceLatencyMs = 0;
    _statusMessage = _isRunning ? 'Counters reset. Tracking active!' : 'Counters reset to 0.';
    notifyListeners();
  }

  /// Toggles between live camera input and simulated test poses.
  Future<void> toggleSimulationMode() async {
    final wasRunning = _isRunning;
    if (wasRunning) {
      await stopSession();
    }

    _isSimulationMode = !_isSimulationMode;
    _statusMessage = _isSimulationMode
        ? 'Switched to Simulated Pose mode'
        : 'Switched to Live Camera mode';

    notifyListeners();

    if (wasRunning) {
      await startSession();
    }
  }

  /// Ingests camera frames with rate throttling and an inference-running lock.
  void _handleCameraFrame(CameraImage image) async {
    if (!_isRunning) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Throttling guard: ensure minimum interval between inferences
    if (now - _lastInferenceTimestampMs < AppConfig.inferenceIntervalMs) {
      return;
    }

    // 2. Concurrency guard: avoid overlapping inference passes
    if (_isInferenceRunning) {
      return;
    }

    _isInferenceRunning = true;
    _lastInferenceTimestampMs = now;

    try {
      final detection = await _yoloService.processCameraImage(image);
      _processDetectionResult(detection, now);
    } catch (e) {
      debugPrint('Error during frame inference: $e');
    } finally {
      _isInferenceRunning = false;
    }
  }

  /// Simulation loop for testing on emulators and desktops without hardware camera.
  void _startSimulationLoop() {
    _simulationTimer?.cancel();
    final mock = _yoloService is MockYoloService
        ? _yoloService as MockYoloService
        : MockYoloService();

    _simulationTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.inferenceIntervalMs),
      (timer) {
        if (!_isRunning) {
          timer.cancel();
          return;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final detection = mock.generateSimulatedDetection(
          width: 640.0,
          height: 480.0,
        );
        _processDetectionResult(detection, now);
      },
    );
  }

  /// Feeds the detection output into the toe tap state machine and updates UI.
  void _processDetectionResult(DetectionResult detection, int now) {
    _detector.processFrame(detection);
    _lastDetectionResult = detection;
    _currentInferenceLatencyMs = detection.inferenceTimeMs;

    // Update FPS calculation
    _fpsCounter++;
    if (now - _lastFpsWindowTimestampMs >= 1000) {
      _currentFps = _fpsCounter;
      _fpsCounter = 0;
      _lastFpsWindowTimestampMs = now;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _cameraService.dispose();
    _yoloService.dispose();
    super.dispose();
  }
}
