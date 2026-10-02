package com.example.models

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

enum class FootSide { LEFT, RIGHT }

enum class TapState {
  IDLE,
  APPROACHING,
  CONTACT,
  SEPARATED
}

data class BoundingBox(
    val left: Float,
    val top: Float,
    val right: Float,
    val bottom: Float,
    val confidence: Float = 1.0f,
    val classId: Int = 0
) {
  val width: Float get() = abs(right - left)
  val height: Float get() = abs(bottom - top)
  val centerX: Float get() = left + (width / 2.0f)
  val centerY: Float get() = top + (height / 2.0f)
  val approximateRadius: Float get() = (width + height) / 4.0f

  fun distanceToCenter(px: Float, py: Float): Float {
    val dx = px - centerX
    val dy = py - centerY
    return sqrt(dx * dx + dy * dy)
  }

  fun distanceToEdge(px: Float, py: Float): Float {
    val dx = max(0.0f, max(left - px, px - right))
    val dy = max(0.0f, max(top - py, py - bottom))
    return sqrt(dx * dx + dy * dy)
  }

  fun distanceToPerimeter(px: Float, py: Float): Float {
    return max(0.0f, distanceToCenter(px, py) - approximateRadius)
  }
}

data class PoseKeypoint(
    val index: Int,
    val x: Float,
    val y: Float,
    val confidence: Float,
    val name: String? = null
)

data class BallDetection(
    val box: BoundingBox,
    val confidence: Float,
    val timestampMs: Long = System.currentTimeMillis()
)

data class FootDetection(
    val side: FootSide,
    val primaryKeypoint: PoseKeypoint
) {
  val x: Float get() = primaryKeypoint.x
  val y: Float get() = primaryKeypoint.y
  val confidence: Float get() = primaryKeypoint.confidence
}

data class FootTracker(
    val side: FootSide,
    var state: TapState = TapState.IDLE,
    var tapCount: Int = 0,
    var missedFrames: Int = 0,
    var lastTapTimestampMs: Long = 0L,
    var lastDistance: Float? = null
) {
  fun reset() {
    state = TapState.IDLE
    tapCount = 0
    missedFrames = 0
    lastTapTimestampMs = 0L
    lastDistance = null
  }
}

data class DetectionResult(
    val personBox: BoundingBox? = null,
    val ball: BallDetection? = null,
    val leftFoot: FootDetection? = null,
    val rightFoot: FootDetection? = null,
    val allKeypoints: List<PoseKeypoint> = emptyList(),
    val inferenceTimeMs: Long = 0L,
    val timestampMs: Long = System.currentTimeMillis(),
    val imageWidth: Float = 640f,
    val imageHeight: Float = 480f
)
