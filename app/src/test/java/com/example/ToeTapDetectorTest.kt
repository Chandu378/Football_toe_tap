package com.example

import com.example.detector.ToeTapDetector
import com.example.models.BallDetection
import com.example.models.BoundingBox
import com.example.models.DetectionResult
import com.example.models.FootDetection
import com.example.models.FootSide
import com.example.models.PoseKeypoint
import com.example.models.TapState
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class ToeTapDetectorTest {

  private lateinit var detector: ToeTapDetector

  // Football centered at (300, 400) with radius 50 (left=250, top=350, right=350, bottom=450)
  private val standardBall =
      BallDetection(
          box =
              BoundingBox(
                  left = 250f,
                  top = 350f,
                  right = 350f,
                  bottom = 450f,
                  confidence = 0.95f,
                  classId = 32
              ),
          confidence = 0.95f,
          timestampMs = 1000L
      )

  @Before
  fun setUp() {
    detector =
        ToeTapDetector(
            contactThreshold = 45.0f,
            separationThreshold = 75.0f,
            tapCooldownMs = 350L,
            maxMissedFrames = 5
        )
  }

  private fun createFrame(
      footX: Float,
      footY: Float,
      side: FootSide = FootSide.RIGHT,
      timestampMs: Long = 1000L,
      includeBall: Boolean = true,
      includeFoot: Boolean = true
  ): DetectionResult {
    val foot =
        if (includeFoot) {
          FootDetection(
              side = side,
              primaryKeypoint =
                  PoseKeypoint(
                      index = if (side == FootSide.RIGHT) 16 else 15,
                      x = footX,
                      y = footY,
                      confidence = 0.9f
                  )
          )
        } else null

    return DetectionResult(
        ball = if (includeBall) standardBall else null,
        leftFoot = if (side == FootSide.LEFT) foot else null,
        rightFoot = if (side == FootSide.RIGHT) foot else null,
        timestampMs = timestampMs
    )
  }

  @Test
  fun test1_footFarFromBall_noTap() {
    val frame = createFrame(footX = 300f, footY = 100f, timestampMs = 1000L)
    val newTaps = detector.processFrame(frame)

    assertEquals(0, newTaps)
    assertEquals(0, detector.totalTaps)
    assertEquals(TapState.SEPARATED, detector.rightState)
  }

  @Test
  fun test2_footApproachesBall_noPrematureDuplicateTaps() {
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    assertEquals(0, detector.totalTaps)
    assertEquals(TapState.SEPARATED, detector.rightState)

    // Intermediate distance (between 45 and 75)
    detector.processFrame(createFrame(footX = 300f, footY = 290f, timestampMs = 1050L))
    assertEquals(0, detector.totalTaps)
    assertEquals(TapState.APPROACHING, detector.rightState)

    detector.processFrame(createFrame(footX = 300f, footY = 295f, timestampMs = 1100L))
    assertEquals(0, detector.totalTaps)
    assertEquals(TapState.APPROACHING, detector.rightState)
  }

  @Test
  fun test3_footContactsBall_count1() {
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    val newTaps = detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1100L))

    assertEquals(1, newTaps)
    assertEquals(1, detector.totalTaps)
    assertEquals(1, detector.rightTaps)
    assertEquals(TapState.CONTACT, detector.rightState)
  }

  @Test
  fun test4_consecutiveContactFrames_stillCount1() {
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1100L))
    assertEquals(1, detector.totalTaps)

    for (i in 1..5) {
      val newTaps =
          detector.processFrame(
              createFrame(footX = 300f, footY = 335f + (i * 2f), timestampMs = 1100L + (i * 50L))
          )
      assertEquals(0, newTaps)
      assertEquals(1, detector.totalTaps)
      assertEquals(TapState.CONTACT, detector.rightState)
    }
  }

  @Test
  fun test5_footSeparatesAndContactsAgain_count2() {
    // Tap 1
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1100L))
    assertEquals(1, detector.totalTaps)

    // Separate beyond 75px
    detector.processFrame(createFrame(footX = 300f, footY = 250f, timestampMs = 1300L))
    assertEquals(TapState.SEPARATED, detector.rightState)

    // Tap 2 after cooldown
    val secondTap =
        detector.processFrame(createFrame(footX = 300f, footY = 345f, timestampMs = 1600L))
    assertEquals(1, secondTap)
    assertEquals(2, detector.totalTaps)
    assertEquals(TapState.CONTACT, detector.rightState)
  }

  @Test
  fun test6_temporaryMissingDetection_stateDoesNotBreak() {
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1100L))
    assertEquals(TapState.CONTACT, detector.rightState)

    // 3 missing frames
    for (i in 1..3) {
      detector.processFrame(
          createFrame(footX = 0f, footY = 0f, includeFoot = false, timestampMs = 1100L + (i * 30L))
      )
      assertEquals(TapState.CONTACT, detector.rightState)
    }

    // Recovers
    detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1250L))
    assertEquals(TapState.CONTACT, detector.rightState)
    assertEquals(1, detector.totalTaps)

    // 6 missing frames exceeds maxMissedFrames
    for (i in 1..6) {
      detector.processFrame(
          createFrame(footX = 0f, footY = 0f, includeBall = false, timestampMs = 1300L + (i * 30L))
      )
    }
    assertEquals(TapState.IDLE, detector.rightState)
  }

  @Test
  fun test7_leftAndRightFootTapIndependently() {
    val startFrame =
        DetectionResult(
            ball = standardBall,
            leftFoot =
                FootDetection(
                    FootSide.LEFT,
                    PoseKeypoint(15, 100f, 100f, 0.9f)
                ),
            rightFoot =
                FootDetection(
                    FootSide.RIGHT,
                    PoseKeypoint(16, 500f, 100f, 0.9f)
                ),
            timestampMs = 1000L
        )
    detector.processFrame(startFrame)

    // Left foot contacts
    val leftTapFrame =
        DetectionResult(
            ball = standardBall,
            leftFoot =
                FootDetection(
                    FootSide.LEFT,
                    PoseKeypoint(15, 290f, 340f, 0.9f)
                ),
            rightFoot =
                FootDetection(
                    FootSide.RIGHT,
                    PoseKeypoint(16, 500f, 100f, 0.9f)
                ),
            timestampMs = 1100L
        )
    detector.processFrame(leftTapFrame)
    assertEquals(1, detector.leftTaps)
    assertEquals(0, detector.rightTaps)
    assertEquals(1, detector.totalTaps)

    // Right foot contacts while left separated
    val rightTapFrame =
        DetectionResult(
            ball = standardBall,
            leftFoot =
                FootDetection(
                    FootSide.LEFT,
                    PoseKeypoint(15, 100f, 100f, 0.9f)
                ),
            rightFoot =
                FootDetection(
                    FootSide.RIGHT,
                    PoseKeypoint(16, 310f, 340f, 0.9f)
                ),
            timestampMs = 1500L
        )
    detector.processFrame(rightTapFrame)
    assertEquals(1, detector.leftTaps)
    assertEquals(1, detector.rightTaps)
    assertEquals(2, detector.totalTaps)
  }

  @Test
  fun test8_reset_allCountersAndStatesReturnToZero() {
    detector.processFrame(createFrame(footX = 300f, footY = 150f, timestampMs = 1000L))
    detector.processFrame(createFrame(footX = 300f, footY = 340f, timestampMs = 1100L))
    assertEquals(1, detector.totalTaps)

    detector.reset()

    assertEquals(0, detector.totalTaps)
    assertEquals(0, detector.leftTaps)
    assertEquals(0, detector.rightTaps)
    assertEquals(TapState.IDLE, detector.leftState)
    assertEquals(TapState.IDLE, detector.rightState)
  }
}
