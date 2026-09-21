package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class NotificationItem(
    val id: String,
    val timestamp: String,
    val title: String,
    val message: String,
    val type: NotificationType,
    val read: Boolean,
    val actionUrl: String? = null,
    val metadata: Map<String, String> = emptyMap()
)

@Keep
@Serializable
enum class NotificationType {
    @SerialName("agent") AGENT,
    @SerialName("build") BUILD,
    @SerialName("test") TEST,
    @SerialName("approval") APPROVAL,
    @SerialName("process") PROCESS,
    @SerialName("security") SECURITY,
    @SerialName("system") SYSTEM
}

@Keep
@Serializable
data class PushNotificationPayload(
    val notification: NotificationItem,
    val priority: PushPriority = PushPriority.HIGH
)

@Keep
@Serializable
enum class PushPriority {
    LOW, NORMAL, HIGH, URGENT
}
