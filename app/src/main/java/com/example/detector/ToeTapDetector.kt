package com.example.detector

import com.example.models.BallDetection
import com.example.models.DetectionResult
import com.example.models.FootDetection
import com.example.models.FootSide
import com.example.models.FootTracker
import com.example.models.TapState

class ToeTapDetector(
    val contactThreshold: Float = 45.0f,
    val separationThreshold: Float = 75.0f,
    val tapCooldownMs: Long = 350L,
    val maxMissedFrames: Int = 5
) {
  val leftTracker = FootTracker(FootSide.LEFT)
  val rightTracker = FootTracker(FootSide.RIGHT)

  val totalTaps: Int get() = leftTracker.tapCount + rightTracker.tapCount
  val leftTaps: Int get() = leftTracker.tapCount
  val rightTaps: Int get() = rightTracker.tapCount

  val leftState: TapState get() = leftTracker.state
  val rightState: TapState get() = rightTracker.state

  fun reset() {
    leftTracker.reset()
    rightTracker.reset()
  }

  fun processFrame(detection: DetectionResult): Int {
    val now = detection.timestampMs
    val ball = detection.ball

    var newTaps = 0
    newTaps += updateFoot(leftTracker, detection.leftFoot, ball, now)
    newTaps += updateFoot(rightTracker, detection.rightFoot, ball, now)
    return newTaps
  }

  private fun updateFoot(
      tracker: FootTracker,
      foot: FootDetection?,
      ball: BallDetection?,
      now: Long
  ): Int {
    // 1. Temporary detection failure handling
    if (ball == null || foot == null) {
      tracker.missedFrames++
      if (tracker.missedFrames > maxMissedFrames) {
        tracker.state = TapState.IDLE
        tracker.lastDistance = null
      }
      return 0
    }

    tracker.missedFrames = 0
    val distance = ball.box.distanceToPerimeter(foot.x, foot.y)
    tracker.lastDistance = distance

    var tapRegistered = 0

    when (tracker.state) {
      TapState.IDLE -> {
        if (distance > separationThreshold) {
          tracker.state = TapState.SEPARATED
        } else if (distance > contactThreshold) {
          tracker.state = TapState.APPROACHING
        } else {
          tracker.state = TapState.CONTACT
        }
      }
      TapState.SEPARATED, TapState.APPROACHING -> {
        if (distance <= contactThreshold) {
          val elapsed = now - tracker.lastTapTimestampMs
          if (elapsed >= tapCooldownMs) {
            tracker.tapCount++
            tracker.lastTapTimestampMs = now
            tracker.state = TapState.CONTACT
            tapRegistered = 1
          } else {
            tracker.state = TapState.CONTACT
          }
        } else if (distance <= separationThreshold) {
          tracker.state = TapState.APPROACHING
        } else {
          tracker.state = TapState.SEPARATED
        }
      }
      TapState.CONTACT -> {
        if (distance > separationThreshold) {
          tracker.state = TapState.SEPARATED
        }
      }
    }

    return tapRegistered
  }
}
