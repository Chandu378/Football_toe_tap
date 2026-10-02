package com.example.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.detector.ToeTapDetector
import com.example.models.BallDetection
import com.example.models.BoundingBox
import com.example.models.DetectionResult
import com.example.models.FootDetection
import com.example.models.FootSide
import com.example.models.PoseKeypoint
import com.example.models.TapState
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.sin
import kotlin.random.Random

data class ToeTapUiState(
    val isRunning: Boolean = false,
    val isSimulationMode: Boolean = true,
    val isCameraPermissionGranted: Boolean = false,
    val totalTaps: Int = 0,
    val leftTaps: Int = 0,
    val rightTaps: Int = 0,
    val leftState: TapState = TapState.IDLE,
    val rightState: TapState = TapState.IDLE,
    val leftDistance: Float? = null,
    val rightDistance: Float? = null,
    val fps: Int = 0,
    val latencyMs: Long = 0L,
    val statusMessage: String = "Ready. Press START to track toe taps.",
    val currentDetection: DetectionResult = DetectionResult()
)

class ToeTapViewModel : ViewModel() {
  private val detector = ToeTapDetector()

  private val _uiState = MutableStateFlow(ToeTapUiState())
  val uiState: StateFlow<ToeTapUiState> = _uiState.asStateFlow()

  private var simulationJob: Job? = null
  private var frameCounter = 0
  private var fpsCounter = 0
  private var lastFpsWindowMs = System.currentTimeMillis()

  fun onCameraPermissionResult(granted: Boolean) {
    _uiState.update {
      it.copy(
          isCameraPermissionGranted = granted,
          isSimulationMode = !granted,
          statusMessage = if (granted) "Camera connected. Ready!" else "Camera denied: Running simulator."
      )
    }
  }

  fun toggleSimulationMode() {
    val current = _uiState.value
    val newMode = !current.isSimulationMode
    _uiState.update {
      it.copy(
          isSimulationMode = newMode,
          statusMessage = if (newMode) "Switched to Pose Simulator" else "Switched to Live Camera"
      )
    }

    if (current.isRunning) {
      stopSession()
      startSession()
    }
  }

  fun startSession() {
    if (_uiState.value.isRunning) return

    _uiState.update {
      it.copy(
          isRunning = true,
          statusMessage = "Tracking active! Alternate toe taps on the ball."
      )
    }

    if (_uiState.value.isSimulationMode) {
      startSimulationLoop()
    }
  }

  fun stopSession() {
    _uiState.update {
      it.copy(
          isRunning = false,
          statusMessage = "Session paused."
      )
    }
    simulationJob?.cancel()
    simulationJob = null
  }

  fun reset() {
    detector.reset()
    _uiState.update {
      it.copy(
          totalTaps = 0,
          leftTaps = 0,
          rightTaps = 0,
          leftState = TapState.IDLE,
          rightState = TapState.IDLE,
          leftDistance = null,
          rightDistance = null,
          currentDetection = DetectionResult(),
          statusMessage = if (it.isRunning) "Counters reset. Tracking active!" else "Counters reset to 0."
      )
    }
  }

  fun onFrameDetected(detection: DetectionResult) {
    detector.processFrame(detection)
    val now = System.currentTimeMillis()

    fpsCounter++
    var currentFps = _uiState.value.fps
    if (now - lastFpsWindowMs >= 1000L) {
      currentFps = fpsCounter
      fpsCounter = 0
      lastFpsWindowMs = now
    }

    _uiState.update {
      it.copy(
          totalTaps = detector.totalTaps,
          leftTaps = detector.leftTaps,
          rightTaps = detector.rightTaps,
          leftState = detector.leftState,
          rightState = detector.rightState,
          leftDistance = detector.leftTracker.lastDistance,
          rightDistance = detector.rightTracker.lastDistance,
          fps = currentFps,
          latencyMs = detection.inferenceTimeMs,
          currentDetection = detection
      )
    }
  }

  private fun startSimulationLoop() {
    simulationJob?.cancel()
    simulationJob = viewModelScope.launch {
      while (isActive && _uiState.value.isRunning) {
        val detection = generateSimulatedFrame(width = 640f, height = 480f)
        onFrameDetected(detection)
        delay(66L) // ~15 FPS throttled inference rate
      }
    }
  }

  private fun generateSimulatedFrame(width: Float, height: Float): DetectionResult {
    frameCounter++
    val ballCenterX = width * 0.50f
    val ballCenterY = height * 0.72f
    val ballRadius = width * 0.08f

    val ballBox = BoundingBox(
        left = ballCenterX - ballRadius,
        top = ballCenterY - ballRadius,
        right = ballCenterX + ballRadius,
        bottom = ballCenterY + ballRadius,
        confidence = 0.95f,
        classId = 32
    )

    val personBox = BoundingBox(
        left = width * 0.25f,
        top = height * 0.15f,
        right = width * 0.75f,
        bottom = height * 0.88f,
        confidence = 0.96f,
        classId = 0
    )

    val cycle = frameCounter % 60
    val contactY = ballBox.top + 8f
    val separatedY = ballBox.top - 70f

    val leftFootY: Float
    val rightFootY: Float

    if (cycle < 30) {
      val progress = sin((cycle / 30.0) * PI).toFloat()
      rightFootY = separatedY + progress * (contactY - separatedY)
      leftFootY = separatedY
    } else {
      val progress = sin(((cycle - 30) / 30.0) * PI).toFloat()
      leftFootY = separatedY + progress * (contactY - separatedY)
      rightFootY = separatedY
    }

    val rightFootKeypoint = PoseKeypoint(
        index = 16,
        x = ballCenterX + 15f,
        y = rightFootY,
        confidence = 0.92f,
        name = "right_ankle"
    )

    val leftFootKeypoint = PoseKeypoint(
        index = 15,
        x = ballCenterX - 15f,
        y = leftFootY,
        confidence = 0.92f,
        name = "left_ankle"
    )

    return DetectionResult(
        personBox = personBox,
        ball = BallDetection(box = ballBox, confidence = 0.95f),
        leftFoot = FootDetection(FootSide.LEFT, leftFootKeypoint),
        rightFoot = FootDetection(FootSide.RIGHT, rightFootKeypoint),
        inferenceTimeMs = 15L + Random.nextInt(5),
        timestampMs = System.currentTimeMillis(),
        imageWidth = width,
        imageHeight = height
    )
  }

  override fun onCleared() {
    simulationJob?.cancel()
    super.onCleared()
  }
}
