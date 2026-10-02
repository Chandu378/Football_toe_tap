package com.example.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val DarkColorScheme =
    darkColorScheme(
        primary = FlickitGreen,
        secondary = FlickitCyan,
        tertiary = FlickitAmber,
        background = Slate950,
        surface = Slate900,
        onPrimary = Color.Black,
        onSecondary = Color.Black,
        onTertiary = Color.Black,
        onBackground = Slate100,
        onSurface = Slate100,
        error = FlickitRose,
    )

@Composable
fun FlickitTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
  MaterialTheme(
      colorScheme = DarkColorScheme,
      typography = Typography,
      content = content,
  )
}
