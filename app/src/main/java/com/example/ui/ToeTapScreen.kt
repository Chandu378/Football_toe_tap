package com.example.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.SmartToy
import androidx.compose.material.icons.filled.Speed
import androidx.compose.material.icons.filled.SportsSoccer
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.example.models.DetectionResult
import com.example.models.TapState
import com.example.ui.theme.FlickitAmber
import com.example.ui.theme.FlickitCyan
import com.example.ui.theme.FlickitGreen
import com.example.ui.theme.FlickitRose
import com.example.ui.theme.Slate400
import com.example.ui.theme.Slate700
import com.example.ui.theme.Slate800
import com.example.ui.theme.Slate900
import com.example.ui.theme.Slate950
import com.example.viewmodel.ToeTapUiState
import com.example.viewmodel.ToeTapViewModel

@Composable
fun ToeTapScreen(viewModel: ToeTapViewModel) {
  val uiState by viewModel.uiState.collectAsState()
  val context = LocalContext.current

  val permissionLauncher =
      rememberLauncherForActivityResult(
          contract = ActivityResultContracts.RequestPermission()
      ) { isGranted ->
        viewModel.onCameraPermissionResult(isGranted)
      }

  LaunchedEffect(Unit) {
    val permissionStatus =
        ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
    if (permissionStatus == PackageManager.PERMISSION_GRANTED) {
      viewModel.onCameraPermissionResult(true)
    } else {
      permissionLauncher.launch(Manifest.permission.CAMERA)
    }
  }

  Column(
      modifier = Modifier
          .fillMaxSize()
          .background(Slate950)
          .statusBarsPadding()
          .navigationBarsPadding()
  ) {
    // Top Bar Header
    HeaderSection(isRunning = uiState.isRunning)

    // Camera Preview + Real-time Detection Overlay Viewport
    Box(
        modifier = Modifier
            .weight(1f)
            .fillMaxWidth()
    ) {
      if (!uiState.isSimulationMode && uiState.isCameraPermissionGranted) {
        CameraPreview(modifier = Modifier.fillMaxSize())
      } else {
        PitchSimulationBackground(modifier = Modifier.fillMaxSize())
      }

      // Live Computer Vision Canvas Overlay
      DetectionOverlayCanvas(
          detection = uiState.currentDetection,
          leftState = uiState.leftState,
          rightState = uiState.rightState,
          modifier = Modifier.fillMaxSize()
      )

      // Top Floating Telemetry Badges
      TelemetryOverlay(uiState = uiState)

      // Idle Prompt Banner
      if (!uiState.isRunning) {
        StatusBanner(
            message = uiState.statusMessage,
            modifier = Modifier.align(Alignment.Center)
        )
      }
    }

    // Lower Dashboard: Total Taps & Left/Right breakdown
    CounterDashboard(uiState = uiState)

    // Action Controls (START/PAUSE, RESET, Simulator Toggle)
    ControlSection(
        isRunning = uiState.isRunning,
        isSimulationMode = uiState.isSimulationMode,
        onStartToggle = {
          if (uiState.isRunning) viewModel.stopSession() else viewModel.startSession()
        },
        onReset = { viewModel.reset() },
        onToggleSimulation = { viewModel.toggleSimulationMode() }
    )
  }
}

@Composable
private fun HeaderSection(isRunning: Boolean) {
  Row(
      modifier = Modifier
          .fillMaxWidth()
          .background(Slate900)
          .padding(horizontal = 20.dp, vertical = 12.dp),
      verticalAlignment = Alignment.CenterVertically
  ) {
    Box(
        modifier = Modifier
            .size(36.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(Slate800),
        contentAlignment = Alignment.Center
    ) {
      Icon(
          imageVector = Icons.Default.SportsSoccer,
          contentDescription = "Soccer Ball Logo",
          tint = FlickitGreen,
          modifier = Modifier.size(22.dp)
      )
    }

    Spacer(modifier = Modifier.width(12.dp))

    Column(modifier = Modifier.weight(1f)) {
      Text(
          text = "FLICKIT TOE TAP COUNTER",
          color = Color.White,
          fontSize = 14.sp,
          fontWeight = FontWeight.ExtraBold,
          letterSpacing = 1.1.sp
      )
      Text(
          text = "Ultralytics YOLO Pose Computer Vision",
          color = Slate400,
          fontSize = 11.sp
      )
    }

    if (isRunning) {
      Row(
          modifier = Modifier
              .clip(RoundedCornerShape(12.dp))
              .background(FlickitGreen.copy(alpha = 0.2f))
              .border(1.dp, FlickitGreen, RoundedCornerShape(12.dp))
              .padding(horizontal = 10.dp, vertical = 4.dp),
          verticalAlignment = Alignment.CenterVertically
      ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(FlickitGreen)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = "LIVE",
            color = FlickitGreen,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold
        )
      }
    }
  }
}

@Composable
private fun PitchSimulationBackground(modifier: Modifier = Modifier) {
  Box(
      modifier = modifier.background(Slate900),
      contentAlignment = Alignment.Center
  ) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
      Icon(
          imageVector = Icons.Default.SportsSoccer,
          contentDescription = "Simulation Pitch",
          tint = FlickitCyan.copy(alpha = 0.5f),
          modifier = Modifier.size(64.dp)
      )
      Spacer(modifier = Modifier.height(12.dp))
      Text(
          text = "YOLO Pose Simulation Active",
          color = Color.White.copy(alpha = 0.8f),
          fontSize = 16.sp,
          fontWeight = FontWeight.Bold
      )
      Spacer(modifier = Modifier.height(4.dp))
      Text(
          text = "Generating synthetic foot motion and contact frames",
          color = Color.White.copy(alpha = 0.4f),
          fontSize = 12.sp
      )
    }
  }
}

@Composable
private fun CameraPreview(modifier: Modifier = Modifier) {
  val context = LocalContext.current
  val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current

  AndroidView(
      modifier = modifier,
      factory = { ctx ->
        val previewView = PreviewView(ctx)
        val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
        cameraProviderFuture.addListener({
          val cameraProvider = cameraProviderFuture.get()
          val preview = Preview.Builder().build().also {
            it.setSurfaceProvider(previewView.surfaceProvider)
          }
          val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
          try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(lifecycleOwner, cameraSelector, preview)
          } catch (e: Exception) {
            e.printStackTrace()
          }
        }, ContextCompat.getMainExecutor(ctx))
        previewView
      }
  )
}

@Composable
private fun DetectionOverlayCanvas(
    detection: DetectionResult,
    leftState: TapState,
    rightState: TapState,
    modifier: Modifier = Modifier
) {
  Canvas(modifier = modifier) {
    if (detection.imageWidth <= 0f || detection.imageHeight <= 0f) return@Canvas

    val scaleX = size.width / detection.imageWidth
    val scaleY = size.height / detection.imageHeight

    // 1. Draw Person Bounding Box
    detection.personBox?.let { box ->
      val pLeft = box.left * scaleX
      val pTop = box.top * scaleY
      val pWidth = box.width * scaleX
      val pHeight = box.height * scaleY

      drawRoundRect(
          color = Color(0xFF3B82F6).copy(alpha = 0.7f),
          topLeft = Offset(pLeft, pTop),
          size = Size(pWidth, pHeight),
          style = Stroke(width = 2.dp.toPx())
      )
    }

    // 2. Draw Football Bounding Box & Contact Ring
    detection.ball?.let { ball ->
      val bBox = ball.box
      val bCenter = Offset(bBox.centerX * scaleX, bBox.centerY * scaleY)
      val bRadius = bBox.approximateRadius * scaleX

      // Ball Circle
      drawCircle(
          color = FlickitAmber,
          center = bCenter,
          radius = bRadius,
          style = Stroke(width = 3.dp.toPx())
      )

      // Center point
      drawCircle(
          color = FlickitAmber,
          center = bCenter,
          radius = 4.dp.toPx()
      )

      // Hysteresis Contact Threshold Ring
      val contactRingRadius = (bBox.approximateRadius + 45f) * scaleX
      drawCircle(
          color = FlickitGreen.copy(alpha = 0.3f),
          center = bCenter,
          radius = contactRingRadius,
          style = Stroke(width = 1.5.dp.toPx())
      )

      // 3. Draw Left Foot Keypoint & Distance Vector
      detection.leftFoot?.let { lf ->
        val footPos = Offset(lf.x * scaleX, lf.y * scaleY)
        val color = when (leftState) {
          TapState.CONTACT -> FlickitGreen
          TapState.APPROACHING -> FlickitCyan
          else -> Color.White
        }

        drawLine(
            color = color.copy(alpha = 0.6f),
            start = footPos,
            end = bCenter,
            strokeWidth = 2.dp.toPx()
        )

        drawCircle(
            color = color.copy(alpha = 0.3f),
            center = footPos,
            radius = 12.dp.toPx()
        )
        drawCircle(
            color = color,
            center = footPos,
            radius = 6.dp.toPx()
        )
      }

      // 4. Draw Right Foot Keypoint & Distance Vector
      detection.rightFoot?.let { rf ->
        val footPos = Offset(rf.x * scaleX, rf.y * scaleY)
        val color = when (rightState) {
          TapState.CONTACT -> FlickitGreen
          TapState.APPROACHING -> FlickitCyan
          else -> Color.White
        }

        drawLine(
            color = color.copy(alpha = 0.6f),
            start = footPos,
            end = bCenter,
            strokeWidth = 2.dp.toPx()
        )

        drawCircle(
            color = color.copy(alpha = 0.3f),
            center = footPos,
            radius = 12.dp.toPx()
        )
        drawCircle(
            color = color,
            center = footPos,
            radius = 6.dp.toPx()
        )
      }
    }
  }
}

@Composable
private fun TelemetryOverlay(uiState: ToeTapUiState) {
  Box(modifier = Modifier.fillMaxSize().padding(12.dp)) {
    // Top-left: FPS & Inference Latency
    Column(modifier = Modifier.align(Alignment.TopStart)) {
      TelemetryBadge(
          icon = Icons.Default.Speed,
          label = "FPS",
          value = "${uiState.fps}",
          color = FlickitCyan
      )
      Spacer(modifier = Modifier.height(6.dp))
      TelemetryBadge(
          icon = Icons.Default.Timer,
          label = "Inference",
          value = "${uiState.latencyMs} ms",
          color = Color(0xFFA78BFA)
      )
    }

    // Top-right: Mode Badge
    Box(modifier = Modifier.align(Alignment.TopEnd)) {
      TelemetryBadge(
          icon = if (uiState.isSimulationMode) Icons.Default.SmartToy else Icons.Default.CameraAlt,
          label = "Engine",
          value = if (uiState.isSimulationMode) "Simulator" else "Camera",
          color = if (uiState.isSimulationMode) FlickitAmber else FlickitGreen
      )
    }
  }
}

@Composable
private fun TelemetryBadge(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    value: String,
    color: Color
) {
  Row(
      modifier = Modifier
          .clip(RoundedCornerShape(8.dp))
          .background(Color.Black.copy(alpha = 0.65f))
          .border(1.dp, color.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
          .padding(horizontal = 8.dp, vertical = 4.dp),
      verticalAlignment = Alignment.CenterVertically
  ) {
    Icon(
        imageVector = icon,
        contentDescription = label,
        tint = color,
        modifier = Modifier.size(13.dp)
    )
    Spacer(modifier = Modifier.width(4.dp))
    Text(
        text = "$label: ",
        color = color.copy(alpha = 0.7f),
        fontSize = 11.sp,
        fontWeight = FontWeight.Medium
    )
    Text(
        text = value,
        color = color,
        fontSize = 11.sp,
        fontWeight = FontWeight.Bold
    )
  }
}

@Composable
private fun StatusBanner(message: String, modifier: Modifier = Modifier) {
  Box(
      modifier = modifier
          .padding(horizontal = 28.dp)
          .clip(RoundedCornerShape(16.dp))
          .background(Color.Black.copy(alpha = 0.8f))
          .border(1.dp, FlickitCyan.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
          .padding(horizontal = 24.dp, vertical = 16.dp),
      contentAlignment = Alignment.Center
  ) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
      Icon(
          imageVector = Icons.Default.SportsSoccer,
          contentDescription = "Ready Icon",
          tint = FlickitCyan,
          modifier = Modifier.size(36.dp)
      )
      Spacer(modifier = Modifier.height(8.dp))
      Text(
          text = "Ready to Track Toe Taps",
          color = Color.White,
          fontSize = 16.sp,
          fontWeight = FontWeight.Bold
      )
      Spacer(modifier = Modifier.height(4.dp))
      Text(
          text = message,
          color = Color.White.copy(alpha = 0.7f),
          fontSize = 12.sp,
          textAlign = TextAlign.Center
      )
    }
  }
}

@Composable
private fun CounterDashboard(uiState: ToeTapUiState) {
  Row(
      modifier = Modifier
          .fillMaxWidth()
          .background(Slate900)
          .padding(horizontal = 20.dp, vertical = 14.dp),
      verticalAlignment = Alignment.CenterVertically
  ) {
    // Total Toe Taps Counter Card
    Box(
        modifier = Modifier
            .weight(1.3f)
            .clip(RoundedCornerShape(16.dp))
            .background(Slate800)
            .border(1.5.dp, FlickitCyan.copy(alpha = 0.4f), RoundedCornerShape(16.dp))
            .padding(horizontal = 16.dp, vertical = 10.dp)
            .testTag("total_taps_counter")
    ) {
      Column {
        Text(
            text = "TOTAL TOE TAPS",
            color = Slate400,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.sp
        )
        Row(verticalAlignment = Alignment.Bottom) {
          Text(
              text = "${uiState.totalTaps}",
              color = Color.White,
              fontSize = 38.sp,
              fontWeight = FontWeight.Black,
              lineHeight = 38.sp
          )
          Spacer(modifier = Modifier.width(6.dp))
          Text(
              text = "taps",
              color = Color.White.copy(alpha = 0.5f),
              fontSize = 13.sp,
              modifier = Modifier.padding(bottom = 4.dp)
          )
        }
      }
    }

    Spacer(modifier = Modifier.width(12.dp))

    // Left & Right Foot Badges
    Column(modifier = Modifier.weight(1f)) {
      FootPill(
          label = "Left Foot",
          count = uiState.leftTaps,
          state = uiState.leftState,
          accentColor = FlickitCyan
      )
      Spacer(modifier = Modifier.height(8.dp))
      FootPill(
          label = "Right Foot",
          count = uiState.rightTaps,
          state = uiState.rightState,
          accentColor = FlickitGreen
      )
    }
  }
}

@Composable
private fun FootPill(
    label: String,
    count: Int,
    state: TapState,
    accentColor: Color
) {
  val isContact = state == TapState.CONTACT
  Row(
      modifier = Modifier
          .fillMaxWidth()
          .clip(RoundedCornerShape(10.dp))
          .background(Slate800)
          .border(
              width = if (isContact) 1.5.dp else 1.dp,
              color = if (isContact) accentColor else Slate700,
              shape = RoundedCornerShape(10.dp)
          )
          .padding(horizontal = 12.dp, vertical = 6.dp),
      horizontalArrangement = Arrangement.SpaceBetween,
      verticalAlignment = Alignment.CenterVertically
  ) {
    Row(verticalAlignment = Alignment.CenterVertically) {
      Box(
          modifier = Modifier
              .size(8.dp)
              .clip(CircleShape)
              .background(if (isContact) accentColor else Color.White.copy(alpha = 0.3f))
      )
      Spacer(modifier = Modifier.width(6.dp))
      Text(
          text = label,
          color = Color.White.copy(alpha = 0.8f),
          fontSize = 11.sp,
          fontWeight = FontWeight.SemiBold
      )
    }
    Text(
        text = "$count",
        color = accentColor,
        fontSize = 15.sp,
        fontWeight = FontWeight.ExtraBold
    )
  }
}

@Composable
private fun ControlSection(
    isRunning: Boolean,
    isSimulationMode: Boolean,
    onStartToggle: () -> Unit,
    onReset: () -> Unit,
    onToggleSimulation: () -> Unit
) {
  Row(
      modifier = Modifier
          .fillMaxWidth()
          .background(Slate900)
          .padding(horizontal = 20.dp, vertical = 12.dp),
      verticalAlignment = Alignment.CenterVertically
  ) {
    // Mode Switch Button (Camera vs Simulator)
    IconButton(
        onClick = onToggleSimulation,
        modifier = Modifier
            .size(48.dp)
            .testTag("toggle_mode_button"),
        colors = IconButtonDefaults.iconButtonColors(
            containerColor = Slate800,
            contentColor = if (isSimulationMode) FlickitCyan else Color.White
        )
    ) {
      Icon(
          imageVector = if (isSimulationMode) Icons.Default.CameraAlt else Icons.Default.SmartToy,
          contentDescription = "Toggle Simulation Mode"
      )
    }

    Spacer(modifier = Modifier.width(12.dp))

    // Main START / PAUSE Button
    Button(
        onClick = onStartToggle,
        modifier = Modifier
            .weight(1.5f)
            .height(52.dp)
            .testTag("start_button"),
        shape = RoundedCornerShape(14.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isRunning) FlickitRose else FlickitGreen,
            contentColor = Color.White
        )
    ) {
      Icon(
          imageVector = if (isRunning) Icons.Default.Pause else Icons.Default.PlayArrow,
          contentDescription = if (isRunning) "Pause" else "Start"
      )
      Spacer(modifier = Modifier.width(6.dp))
      Text(
          text = if (isRunning) "PAUSE" else "START",
          fontSize = 15.sp,
          fontWeight = FontWeight.Bold,
          letterSpacing = 1.sp
      )
    }

    Spacer(modifier = Modifier.width(12.dp))

    // RESET Button
    OutlinedButton(
        onClick = onReset,
        modifier = Modifier
            .weight(1f)
            .height(52.dp)
            .testTag("reset_button"),
        shape = RoundedCornerShape(14.dp),
        colors = ButtonDefaults.outlinedButtonColors(
            containerColor = Slate800,
            contentColor = Color.White
        ),
        border = androidx.compose.foundation.BorderStroke(1.dp, Slate700)
    ) {
      Icon(
          imageVector = Icons.Default.Refresh,
          contentDescription = "Reset",
          modifier = Modifier.size(18.dp)
      )
      Spacer(modifier = Modifier.width(4.dp))
      Text(
          text = "RESET",
          fontSize = 14.sp,
          fontWeight = FontWeight.Bold
      )
    }
  }
}
