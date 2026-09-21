package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class ConnectionConfig(
    val desktopId: String,
    val host: String,
    val port: Int = 8444,
    val useHttps: Boolean = true,
    val wsPort: Int = 8000,
    val useWss: Boolean = true,
    val accessCode: String = ""
)

@Keep
@Serializable
data class PairingRequest(
    val desktopId: String,
    val deviceName: String,
    val deviceType: String = "android",
    val platform: String = "Android",
    val appVersion: String
)

@Keep
@Serializable
data class PairingChallenge(
    val challengeId: String,
    val desktopId: String,
    val qrCodeData: String,
    val expiresAt: String
)

@Keep
@Serializable
data class AuthRequest(
    val desktopId: String,
    val accessCode: String,
    val deviceId: String,
    val deviceName: String
)

@Keep
@Serializable
data class AuthResponse(
    val success: Boolean,
    val sessionToken: String? = null,
    val refreshToken: String? = null,
    val expiresIn: Long? = null,
    val deviceTrusted: Boolean = false,
    val error: String? = null
)

@Keep
@Serializable
data class DeviceTrustRequest(
    val deviceId: String,
    val trust: Boolean,
    val sessionToken: String
)

@Keep
@Serializable
data class DeviceInfo(
    val deviceId: String,
    val name: String,
    val platform: String,
    val trusted: Boolean,
    val lastConnectedAt: String,
    val appVersion: String
)
