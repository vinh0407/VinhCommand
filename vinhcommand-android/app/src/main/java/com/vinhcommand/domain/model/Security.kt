package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class SecurityAuditLog(
    val id: String,
    val timestamp: String,
    val event: String,
    val details: String,
    val level: SecurityLevel
)

@Keep
@Serializable
enum class SecurityLevel {
    @SerialName("info") INFO,
    @SerialName("warning") WARNING,
    @SerialName("critical") CRITICAL
}

@Keep
@Serializable
data class CommandApprovalRequest(
    val approvalId: String,
    val command: String,
    val projectName: String,
    val riskLevel: CommandRiskLevel,
    val reason: String,
    val timestamp: String
)

@Keep
@Serializable
enum class CommandRiskLevel {
    @SerialName("SAFE") SAFE,
    @SerialName("WARNING") WARNING,
    @SerialName("DANGEROUS") DANGEROUS,
    @SerialName("BLOCKED") BLOCKED
}

@Keep
@Serializable
data class CommandApprovalResponse(
    val approvalId: String,
    val allowed: Boolean
)

@Keep
@Serializable
data class EvaluatedCommand(
    val command: String,
    val riskLevel: CommandRiskLevel,
    val reason: String
)

@Keep
@Serializable
data class SessionState(
    val sessionId: String,
    val deviceId: String,
    val desktopId: String,
    val createdAt: String,
    val expiresAt: String,
    val lastActivity: String,
    val permissionProfile: PermissionProfile,
    val status: SessionStatus
)

@Keep
@Serializable
enum class PermissionProfile {
    @SerialName("Developer") DEVELOPER,
    @SerialName("Admin") ADMIN,
    @SerialName("Read Only") READ_ONLY
}

@Keep
@Serializable
enum class SessionStatus {
    @SerialName("CONNECTING") CONNECTING,
    @SerialName("AUTHENTICATING") AUTHENTICATING,
    @SerialName("CONNECTED") CONNECTED,
    @SerialName("IDLE") IDLE,
    @SerialName("EXPIRED") EXPIRED,
    @SerialName("REVOKED") REVOKED,
    @SerialName("DISCONNECTED") DISCONNECTED,
    @SerialName("FAILED") FAILED
}
