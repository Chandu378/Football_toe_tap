import 'package:flutter/material.dart';

/// Bottom action bar providing START/PAUSE, RESET, and SIMULATOR toggle buttons.
class ControlBar extends StatelessWidget {
  final bool isRunning;
  final bool isSimulationMode;
  final VoidCallback onStartToggle;
  final VoidCallback onReset;
  final VoidCallback onToggleSimulation;

  const ControlBar({
    super.key,
    required this.isRunning,
    required this.isSimulationMode,
    required this.onStartToggle,
    required this.onReset,
    required this.onToggleSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Mode toggle button (Camera vs Simulator)
            IconButton(
              onPressed: onToggleSimulation,
              tooltip: isSimulationMode ? 'Switch to Camera' : 'Switch to Simulator',
              icon: Icon(
                isSimulationMode ? Icons.camera_alt : Icons.smart_toy,
                color: isSimulationMode ? const Color(0xFF38BDF8) : Colors.white70,
              ),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                minimumSize: const Size(48, 48),
              ),
            ),
            const SizedBox(width: 12),

            // Primary START / PAUSE Button
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                onPressed: onStartToggle,
                icon: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 24,
                ),
                label: Text(
                  isRunning ? 'PAUSE' : 'START',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning
                      ? const Color(0xFFE11D48) // Rose red for pause
                      : const Color(0xFF16A34A), // Emerald green for start
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // RESET Button
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text(
                  'RESET',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF334155), width: 1.5),
                  backgroundColor: const Color(0xFF1E293B),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
