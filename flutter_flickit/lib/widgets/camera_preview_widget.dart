import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/camera_service.dart';

/// Displays the live camera preview with aspect-ratio management,
/// or an athletic simulated pitch background when running in simulation mode.
class CameraPreviewWidget extends StatelessWidget {
  final CameraService cameraService;
  final bool isSimulationMode;

  const CameraPreviewWidget({
    super.key,
    required this.cameraService,
    required this.isSimulationMode,
  });

  @override
  Widget build(BuildContext context) {
    if (isSimulationMode || !cameraService.isInitialized) {
      return Container(
        color: const Color(0xFF0F172A), // Dark slate sports pitch background
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSimulationMode ? Icons.sports_soccer : Icons.videocam_off_outlined,
                size: 64,
                color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                isSimulationMode
                    ? 'YOLO Pose Simulation Active'
                    : 'Camera Preview Starting...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSimulationMode
                    ? 'Generating synthetic foot movement and ball contact'
                    : 'Waiting for device camera access...',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = cameraService.controller!;
    return ClipRect(
      child: SizedOverflowBox(
        size: Size.infinite,
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 480,
            height: controller.value.previewSize?.width ?? 640,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
