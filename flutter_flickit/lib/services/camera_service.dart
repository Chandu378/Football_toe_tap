import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

typedef CameraImageCallback = void Function(CameraImage image);

/// Manages camera lifecycle, permission queries, video streams, and disposal.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isInitialized = false;
  bool _isStreaming = false;
  String? _errorMessage;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isStreaming => _isStreaming;
  String? get errorMessage => _errorMessage;

  /// Initializes the back-facing camera with optimal resolution for mobile ML inference.
  Future<bool> initialize() async {
    try {
      _errorMessage = null;
      _availableCameras = await availableCameras();

      if (_availableCameras.isEmpty) {
        _errorMessage = 'No camera found on this device or emulator.';
        return false;
      }

      // Prefer back camera for football toe tap tracking
      final camera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium, // 720p or 480p is optimal for ML inference + 30fps
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _isInitialized = true;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: ${e.toString()}';
      _isInitialized = false;
      return false;
    }
  }

  /// Starts streaming camera frames to the given ML callback.
  Future<void> startImageStream(CameraImageCallback onImage) async {
    if (_controller == null || !_isInitialized || _isStreaming) return;

    try {
      await _controller!.startImageStream((image) {
        if (_isStreaming) {
          onImage(image);
        }
      });
      _isStreaming = true;
    } catch (e) {
      debugPrint('Error starting image stream: $e');
    }
  }

  /// Stops streaming frames from the camera.
  Future<void> stopImageStream() async {
    if (_controller == null || !_isStreaming) return;

    try {
      _isStreaming = false;
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
  }

  /// Disposes camera resources cleanly.
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}
