package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.example.ui.ToeTapScreen
import com.example.ui.theme.FlickitTheme
import com.example.viewmodel.ToeTapViewModel

class MainActivity : ComponentActivity() {
  private val viewModel: ToeTapViewModel by viewModels()

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableEdgeToEdge()
    setContent {
      FlickitTheme {
        ToeTapScreen(viewModel = viewModel)
      }
    }
  }

  override fun onPause() {
    super.onPause()
    if (viewModel.uiState.value.isRunning) {
      viewModel.stopSession()
    }
  }
}
