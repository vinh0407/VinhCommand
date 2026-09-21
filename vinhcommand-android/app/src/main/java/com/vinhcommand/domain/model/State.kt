package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.Serializable

@Keep
@Serializable
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    AUTHENTICATING,
    CONNECTED,
    RECONNECTING,
    OFFLINE,
    SESSION_EXPIRED,
    ACCESS_REVOKED,
    FAILED
}

@Keep
@Serializable
data class PcState(
    val computer: DesktopComputer? = null,
    val projects: List<Project> = emptyList(),
    val agents: List<AIAgent> = emptyList(),
    val tasks: List<AgentTask> = emptyList(),
    val processes: List<ProcessItem> = emptyList(),
    val servers: List<DevServer> = emptyList(),
    val hardwareStats: HardwareStats? = null,
    val lastUpdated: Long = System.currentTimeMillis()
)

@Keep
@Serializable
data class AgentState(
    val agents: List<AIAgent> = emptyList(),
    val selectedAgentId: String? = null,
    val runningTasks: Map<String, List<AgentTask>> = emptyMap()
)

@Keep
@Serializable
data class TaskState(
    val tasks: List<AgentTask> = emptyList(),
    val selectedTaskId: String? = null,
    val activeTaskIds: List<String> = emptyList(),
    val streamingOutput: Map<String, List<String>> = emptyMap()
)

@Keep
@Serializable
data class TerminalState(
    val sessions: List<TerminalSession> = emptyList(),
    val activeSessionId: String? = null,
    val commandHistory: List<String> = emptyList()
)

@Keep
@Serializable
data class ProjectState(
    val projects: List<Project> = emptyList(),
    val selectedProjectId: String? = null,
    val projectDetail: ProjectDetail? = null,
    val fileTree: List<FileNode> = emptyList(),
    val gitStatus: GitStatusOverview? = null
)

@Keep
@Serializable
data class SecurityState(
    val sessionState: SessionState? = null,
    val deviceInfo: DeviceInfo? = null,
    val auditLogs: List<SecurityAuditLog> = emptyList(),
    val pendingApprovals: List<CommandApprovalRequest> = emptyList(),
    val remoteControlEnabled: Boolean = false
)

@Keep
@Serializable
data class NotificationState(
    val notifications: List<NotificationItem> = emptyList(),
    val unreadCount: Int = 0
)

@Keep
@Serializable
data class UIState(
    val isAppLocked: Boolean = false,
    val isCommandPaletteOpen: Boolean = false,
    val isGlobalSearchOpen: Boolean = false,
    val searchQuery: String = "",
    val theme: AppTheme = AppTheme.DARK,
    val sidebarOpen: Boolean = false
)

@Keep
@Serializable
enum class AppTheme {
    DARK, LIGHT, SYSTEM
}
