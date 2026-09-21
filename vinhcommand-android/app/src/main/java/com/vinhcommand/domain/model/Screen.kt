package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class ScreenStreamConfig(
    val mode: ScreenMode,
    val fps: Int = 15,
    val quality: Int = 70,
    val scale: Float = 1.0f,
    val captureCursor: Boolean = true
)

@Keep
@Serializable
enum class ScreenMode {
    @SerialName("desktop") DESKTOP,
    @SerialName("application") APPLICATION,
    @SerialName("window") WINDOW
}

@Keep
@Serializable
data class ScreenFrame(
    val imageData: String,
    val width: Int,
    val height: Int,
    val timestamp: Long,
    val format: String = "jpeg"
)

@Keep
@Serializable
data class RemoteInputEvent(
    val type: InputEventType,
    val x: Float,
    val y: Float,
    val button: MouseButton? = null,
    val keyCode: Int? = null,
    val keyAction: KeyAction? = null,
    val text: String? = null,
    val modifiers: List<String> = emptyList()
)

@Keep
@Serializable
enum class InputEventType {
    @SerialName("mouse_move") MOUSE_MOVE,
    @SerialName("mouse_down") MOUSE_DOWN,
    @SerialName("mouse_up") MOUSE_UP,
    @SerialName("mouse_scroll") MOUSE_SCROLL,
    @SerialName("key_down") KEY_DOWN,
    @SerialName("key_up") KEY_UP,
    @SerialName("text_input") TEXT_INPUT
}

@Keep
@Serializable
enum class MouseButton {
    LEFT, RIGHT, MIDDLE, BACK, FORWARD
}

@Keep
@Serializable
enum class KeyAction {
    DOWN, UP
}

@Keep
@Serializable
data class RemoteControlState(
    val enabled: Boolean,
    val mode: ScreenMode,
    val permissions: RemoteControlPermissions
)

@Keep
@Serializable
data class RemoteControlPermissions(
    val mouse: Boolean,
    val keyboard: Boolean,
    val clipboard: Boolean,
    val fileTransfer: Boolean
)
