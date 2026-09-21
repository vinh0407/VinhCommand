package com.vinhcommand.ui.theme

import android.app.Activity
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

private val DarkGreenBlackColors = darkColorScheme(
    primary = PrimaryGreen,
    onPrimary = Color.White,
    primaryContainer = PrimaryGreenDark,
    onPrimaryContainer = Color(0xFFD1E7DD),
    inversePrimary = AccentGreen,

    secondary = PrimaryGreenLight,
    onSecondary = Color.White,
    secondaryContainer = SurfaceMedium,
    onSecondaryContainer = TextPrimary,

    tertiary = AccentGreen,
    onTertiary = Color.Black,
    tertiaryContainer = SurfaceLight,
    onTertiaryContainer = TextPrimary,

    background = BackgroundBlack,
    onBackground = TextPrimary,

    surface = SurfaceDark,
    onSurface = TextPrimary,
    surfaceVariant = SurfaceMedium,
    onSurfaceVariant = TextSecondary,
    surfaceTint = Color.Transparent,
    inverseSurface = TextPrimary,
    inverseOnSurface = BackgroundBlack,

    outline = BorderColor,
    outlineVariant = BorderColor,

    error = ErrorRed,
    onError = Color.White,
    errorContainer = Color(0xFF3B1E1E),
    onErrorContainer = Color(0xFFF8D7DA),

    surfaceBright = SurfaceLight,
    surfaceDim = BackgroundBlack,
    surfaceContainer = SurfaceDark,
    surfaceContainerHigh = SurfaceMedium,
    surfaceContainerHighest = SurfaceLight,
    surfaceContainerLow = BackgroundBlack,
    surfaceContainerLowest = Color.Black
)

@Composable
fun VinhCommandTheme(content: @Composable () -> Unit) {
    val view = LocalView.current
    if(!view.isInEditMode) SideEffect {
        val window = (view.context as Activity).window
        WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
    }
    MaterialTheme(
        colorScheme = DarkGreenBlackColors,
        typography = Typography,
        shapes = Shapes(
            extraSmall = RoundedCornerShape(0.dp),
            small = RoundedCornerShape(0.dp),
            medium = RoundedCornerShape(2.dp),
            large = RoundedCornerShape(2.dp),
            extraLarge = RoundedCornerShape(2.dp)
        ),
        content = content
    )
}
