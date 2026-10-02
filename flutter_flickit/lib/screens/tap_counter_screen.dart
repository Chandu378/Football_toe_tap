import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/tap_counter_controller.dart';
import '../models/tap_state.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/control_bar.dart';
import '../widgets/detection_overlay.dart';
import '../widgets/stat_badge.dart';

/// Main screen showcasing the Camera Preview, Real-Time Detection Overlay,
/// Toe-Tap Counters (Total, Left, Right), and Action Controls.
class TapCounterScreen extends StatefulWidget {
  const TapCounterScreen({super.key});

  @override
  State<TapCounterScreen> createState() => _TapCounterScreenState();
}

class _TapCounterScreenState extends State<TapCounterScreen> with WidgetsBindingObserver {
  late TapCounterController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = Provider.of<TapCounterController>(context, listen: false);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Gracefully pause session when app moves to background
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_controller.isRunning) {
        _controller.stopSession();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TapCounterController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF090D16),
          body: SafeArea(
            child: Column(
              children: [
                // Top Header: App Branding & Status
                _buildHeader(controller),

                // Main Interactive Viewport: Camera Preview + Detection Overlay
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Camera Video Preview / Pitch Background
                      CameraPreviewWidget(
                        cameraService: controller.cameraService,
                        isSimulationMode: controller.isSimulationMode,
                      ),

                      // Real-Time Computer Vision Overlay
                      DetectionOverlay(
                        detection: controller.currentDetection,
                        leftState: controller.leftState,
                        rightState: controller.rightState,
                        leftDistance: controller.detector.leftTracker.lastCalculatedDistance,
                        rightDistance: controller.detector.rightTracker.lastCalculatedDistance,
                      ),

                      // Floating Top-Left Telemetry (FPS & Inference Latency)
                      if (AppConfig.showPerformanceStats)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatBadge(
                                label: 'FPS',
                                value: '${controller.fps}',
                                icon: Icons.speed,
                                color: const Color(0xFF38BDF8),
                              ),
                              const SizedBox(height: 6),
                              StatBadge(
                                label: 'Inference',
                                value: '${controller.latencyMs} ms',
                                icon: Icons.timer,
                                color: const Color(0xFFA78BFA),
                              ),
                            ],
                          ),
                        ),

                      // Floating Top-Right Mode Badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: StatBadge(
                          label: 'Engine',
                          value: controller.isSimulationMode ? 'Simulator' : 'Live Camera',
                          icon: controller.isSimulationMode ? Icons.smart_toy : Icons.camera_alt,
                          color: controller.isSimulationMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF22C55E),
                        ),
                      ),

                      // Center HUD Alert Banner
                      if (!controller.isRunning)
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sports_soccer,
                                  size: 40,
                                  color: Color(0xFF38BDF8),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ready to Track Toe Taps',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.statusMessage ?? 'Press START to begin session',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Lower Dashboard: Total Toe Taps & Left/Right breakdown
                _buildCounterDashboard(controller),

                // Bottom Action Controls: START/PAUSE, RESET, and Simulation Toggle
                ControlBar(
                  isRunning: controller.isRunning,
                  isSimulationMode: controller.isSimulationMode,
                  onStartToggle: () {
                    if (controller.isRunning) {
                      controller.stopSession();
                    } else {
                      controller.startSession();
                    }
                  },
                  onReset: controller.reset,
                  onToggleSimulation: controller.toggleSimulationMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(TapCounterController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Color(0xFF22C55E),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FLICKIT TOE TAP COUNTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Ultralytics YOLO Pose Computer Vision',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (controller.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFF22C55E),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCounterDashboard(TapCounterController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Total Toe Taps Counter Card
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL TOE TAPS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${controller.totalTaps}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'taps',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Left & Right Foot Independent Counters
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildFootPill(
                  label: 'Left Foot',
                  count: controller.leftTaps,
                  state: controller.leftState,
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 8),
                _buildFootPill(
                  label: 'Right Foot',
                  count: controller.rightTaps,
                  state: controller.rightState,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootPill({
    required String label,
    required int count,
    required TapState state,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: state == TapState.contact
              ? color
              : const Color(0xFF334155),
          width: state == TapState.contact ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 4,
                backgroundColor: state == TapState.contact ? color : Colors.white30,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
