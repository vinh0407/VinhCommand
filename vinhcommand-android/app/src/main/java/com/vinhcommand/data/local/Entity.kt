package com.vinhcommand.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.vinhcommand.domain.model.*
import kotlinx.serialization.Serializable

@Entity(tableName = "computers")
@Serializable
data class ComputerEntity(
    @PrimaryKey val id: String,
    val name: String,
    val desktopId: String,
    val status: String,
    val os: String,
    val ipAddress: String,
    val trusted: Boolean,
    val lastConnectedAt: String,
    val statsJson: String? = null,
    val statsSummaryJson: String? = null
)

@Entity(tableName = "projects")
@Serializable
data class ProjectEntity(
    @PrimaryKey val id: String,
    val name: String,
    val path: String,
    val framework: String,
    val language: String,
    val gitBranch: String,
    val modifiedFilesCount: Int,
    val runningProcessesCount: Int,
    val activeServersCount: Int,
    val activeTasksCount: Int,
    val availableAgentsJson: String
)

@Entity(tableName = "agents")
@Serializable
data class AgentEntity(
    @PrimaryKey val id: String,
    val name: String,
    val description: String,
    val status: String,
    val version: String,
    val capabilitiesJson: String,
    val path: String? = null,
    val authStatus: String? = null
)

@Entity(tableName = "tasks")
@Serializable
data class TaskEntity(
    @PrimaryKey val id: String,
    val projectId: String,
    val projectName: String,
    val agentId: String,
    val agentName: String,
    val prompt: String,
    val status: String,
    val isAutonomous: Boolean,
    val maxIterations: Int,
    val currentIteration: Int,
    val stopOnTestsPass: Boolean,
    val stopOnBuildPass: Boolean,
    val createdAt: String,
    val runtimeSeconds: Long,
    val logsJson: String,
    val timelineJson: String,
    val changedFilesJson: String,
    val testResultsJson: String? = null,
    val gitDiffJson: String? = null
)

@Entity(tableName = "notifications")
@Serializable
data class NotificationEntity(
    @PrimaryKey val id: String,
    val timestamp: String,
    val title: String,
    val message: String,
    val type: String,
    val read: Boolean,
    val actionUrl: String? = null,
    val metadataJson: String = "{}"
)

@Entity(tableName = "terminal_sessions")
@Serializable
data class TerminalSessionEntity(
    @PrimaryKey val id: String,
    val shellName: String,
    val cwd: String,
    val historyJson: String,
    val logsJson: String
)

@Entity(tableName = "file_nodes")
@Serializable
data class FileNodeEntity(
    @PrimaryKey val id: String,
    val name: String,
    val path: String,
    val isDirectory: Boolean,
    val sizeBytes: Long? = null,
    val modifiedAt: String? = null,
    val childrenJson: String? = null
)

@Entity(tableName = "git_status")
@Serializable
data class GitStatusEntity(
    @PrimaryKey val projectId: String,
    val branch: String,
    val ahead: Int,
    val behind: Int,
    val filesJson: String,
    val recentCommitsJson: String
)

@Entity(tableName = "processes")
@Serializable
data class ProcessEntity(
    @PrimaryKey val pid: Int,
    val name: String,
    val cpuPct: Double,
    val ramMb: Long,
    val status: String
)

@Entity(tableName = "servers")
@Serializable
data class ServerEntity(
    @PrimaryKey val id: String,
    val projectName: String,
    val port: Int,
    val framework: String,
    val url: String,
    val pid: Int,
    val status: String
)

@Entity(tableName = "audit_logs")
@Serializable
data class AuditLogEntity(
    @PrimaryKey val id: String,
    val timestamp: String,
    val event: String,
    val details: String,
    val level: String
)

@Entity(tableName = "approvals")
@Serializable
data class ApprovalEntity(
    @PrimaryKey val approvalId: String,
    val command: String,
    val projectName: String,
    val riskLevel: String,
    val reason: String,
    val timestamp: String
)

@Entity(tableName = "device_info")
@Serializable
data class DeviceInfoEntity(
    @PrimaryKey val deviceId: String,
    val name: String,
    val platform: String,
    val trusted: Boolean,
    val lastConnectedAt: String,
    val appVersion: String
)

@Entity(tableName = "session_state")
@Serializable
data class SessionStateEntity(
    @PrimaryKey val id: String = "current",
    val sessionId: String,
    val deviceId: String,
    val desktopId: String,
    val createdAt: String,
    val expiresAt: String,
    val lastActivity: String,
    val permissionProfile: String,
    val status: String
)

@Entity(tableName = "recent_computers")
@Serializable
data class RecentComputerEntity(
    @PrimaryKey val desktopId: String,
    val computerJson: String,
    val lastUsed: Long
)

@Entity(tableName = "prompt_templates")
@Serializable
data class PromptTemplateEntity(
    @PrimaryKey val id: String,
    val name: String,
    val prompt: String,
    val category: String
)

@Entity(tableName = "prompt_history")
@Serializable
data class PromptHistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val prompt: String,
    val projectId: String? = null,
    val agentId: String? = null,
    val timestamp: Long
)

@Entity(tableName = "settings")
@Serializable
data class SettingsEntity(
    @PrimaryKey val key: String,
    val value: String
)
