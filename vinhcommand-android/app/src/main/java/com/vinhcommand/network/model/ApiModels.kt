package com.vinhcommand.network.model

import com.vinhcommand.domain.model.*
import kotlinx.serialization.Serializable

@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: ApiError? = null
)

@Serializable
data class ApiError(
    val code: String,
    val message: String,
    val details: String? = null
)

@Serializable
data class PaginatedResponse<T>(
    val items: List<T>,
    val total: Int,
    val page: Int,
    val pageSize: Int,
    val hasMore: Boolean
)

// Request/Response DTOs for API
@Serializable
data class ConnectRequest(
    val desktopId: String,
    val accessCode: String,
    val deviceId: String,
    val deviceName: String,
    val deviceType: String = "android",
    val platform: String = "Android",
    val appVersion: String
)

@Serializable
data class ConnectResponse(
    val success: Boolean,
    val sessionToken: String?,
    val refreshToken: String?,
    val expiresIn: Long?,
    val deviceTrusted: Boolean = false,
    val computer: DesktopComputer?,
    val error: String?
)

@Serializable
data class PairRequest(
    val desktopId: String,
    val deviceName: String,
    val deviceType: String = "android",
    val platform: String = "Android",
    val appVersion: String
)

@Serializable
data class PairResponse(
    val success: Boolean,
    val challengeId: String?,
    val qrCodeData: String?,
    val expiresAt: String?,
    val error: String?
)

@Serializable
data class RefreshTokenRequest(
    val refreshToken: String
)

@Serializable
data class RefreshTokenResponse(
    val success: Boolean,
    val sessionToken: String?,
    val expiresIn: Long?,
    val error: String?
)

@Serializable
data class ProjectsResponse(
    val projects: List<Project>
)

@Serializable
data class ProjectDetailResponse(
    val project: Project,
    val gitStatus: GitStatusOverview?,
    val devServers: List<DevServer>,
    val processes: List<ProcessItem>,
    val recentTasks: List<AgentTask>
)

@Serializable
data class AgentsResponse(
    val agents: List<AIAgent>
)

@Serializable
data class AgentDetailResponse(
    val agent: AIAgent,
    val runningTasks: List<AgentTask>,
    val recentLogs: List<String>
)

@Serializable
data class TasksResponse(
    val tasks: List<AgentTask>
)

@Serializable
data class TaskDetailResponse(
    val task: AgentTask,
    val logs: List<String>,
    val timeline: List<TaskTimelineEvent>,
    val diff: GitDiff?
)

@Serializable
data class CreateTaskRequestDto(
    val name: String,
    val agent: String,
    val project: String,
    val prompt: String,
    val isAutonomous: Boolean = true,
    val maxIterations: Int = 10,
    val stopOnTestsPass: Boolean = true,
    val stopOnBuildPass: Boolean = true,
    val permission: String = "read-only",
    val parentTaskId: String? = null
)

@Serializable
data class CreateTaskResponse(
    val success: Boolean,
    val task: AgentTask?,
    val error: String?
)

@Serializable
data class TaskControlRequestDto(
    val taskId: String,
    val action: String
)

@Serializable
data class TerminalCreateRequest(
    val shell: String,
    val cwd: String
)

@Serializable
data class TerminalCreateResponse(
    val success: Boolean,
    val sessionId: String?,
    val error: String?
)

@Serializable
data class TerminalCommandRequest(
    val sessionId: String,
    val command: String
)

@Serializable
data class TerminalResizeRequest(
    val sessionId: String,
    val cols: Int,
    val rows: Int
)

@Serializable
data class FileListRequest(
    val path: String
)

@Serializable
data class FileListResponse(
    val files: List<FileNode>
)

@Serializable
data class FileReadRequest(
    val path: String
)

@Serializable
data class FileReadResponse(
    val path: String,
    val content: String = "",
    val encoding: String = "utf-8",
    val sizeBytes: Long = 0,
    val modifiedAt: String = "",
    val name: String? = null,
    val extension: String? = null
)

@Serializable
data class FileWriteRequest(
    val path: String,
    val content: String
)

@Serializable
data class FileWriteResponse(
    val success: Boolean = true,
    val path: String = "",
    val error: String? = null
)

@Serializable
data class FileOperationRequestDto(
    val operation: String,
    val path: String,
    val content: String? = null,
    val newPath: String? = null
)

@Serializable
data class GitStatusResponse(
    val branch: String,
    val ahead: Int,
    val behind: Int,
    val files: List<GitFileStatus>,
    val recentCommits: List<GitCommit>
)

@Serializable
data class GitDiffResponse(
    val filePath: String,
    val oldContent: String?,
    val newContent: String?,
    val hunks: List<GitDiffHunk>
)

@Serializable
data class GitCommitRequest(
    val message: String
)

@Serializable
data class ProcessesResponse(
    val processes: List<ProcessItem>
)

@Serializable
data class ServersResponse(
    val servers: List<DevServer>
)

@Serializable
data class StartServerRequest(
    val projectId: String,
    val port: Int
)

@Serializable
data class SecurityAuditResponse(
    val logs: List<SecurityAuditLog>
)

@Serializable
data class ApprovalsResponse(
    val approvals: List<CommandApprovalRequest>
)

@Serializable
data class ApprovalRequestDto(
    val approvalId: String,
    val allow: Boolean
)

@Serializable
data class DeviceTrustResponse(
    val deviceId: String,
    val name: String,
    val platform: String,
    val trusted: Boolean,
    val lastConnectedAt: String,
    val appVersion: String
)

@Serializable
data class KillSwitchResponse(
    val success: Boolean,
    val terminatedTasksCount: Int
)

@Serializable
data class NotificationsResponse(
    val notifications: List<NotificationItem>
)

@Serializable
data class MetricsResponse(
    val desktopId: String,
    val remoteAccessEnabled: Boolean,
    val cpuUsagePct: Int,
    val ramUsagePct: Int,
    val diskUsagePct: Int,
    val uptimeSeconds: Long
)

@Serializable
data class FsBrowseResponse(
    val currentPath: String,
    val parentPath: String? = null,
    val folders: List<FsFolderItem> = emptyList(),
    val files: List<FsFileItem> = emptyList()
)

@Serializable
data class FsFolderItem(
    val name: String,
    val path: String,
    val isDrive: Boolean? = false,
    val isProject: Boolean? = false,
    val framework: String? = "Folder",
    val isFolder: Boolean? = true
)

@Serializable
data class FsFileItem(
    val name: String,
    val path: String,
    val extension: String = "",
    val sizeBytes: Long = 0,
    val isFolder: Boolean? = false
)

@Serializable
data class RunnerItem(
    val name: String,
    val command: String,
    val description: String = "",
    val type: String = "dev",
    val port: Int? = null,
    val previewUrl: String? = null
)

@Serializable
data class RunnerDetectResponse(
    val framework: String = "Custom",
    val projectPath: String = "",
    val isMobile: Boolean = false,
    val isWeb: Boolean = false,
    val isLightweight: Boolean = false,
    val runners: List<RunnerItem> = emptyList()
)

@Serializable
data class BuildApkResponse(
    val success: Boolean = false,
    val apkPath: String? = null,
    val fileName: String? = null,
    val downloadUrl: String? = null,
    val sizeBytes: Long? = null,
    val message: String? = null,
    val output: String? = null
)

@Serializable
data class RunnerStartResponse(
    val success: Boolean = true,
    val pid: Int = 0,
    val command: String = "",
    val port: Int? = null,
    val previewUrl: String? = null,
    val status: String = "RUNNING"
)

@Serializable
data class ActiveRunnerItem(
    val pid: Int,
    val command: String,
    val port: Int? = null,
    val previewUrl: String? = null,
    val status: String = "RUNNING",
    val startTime: String = "",
    val logs: List<String> = emptyList()
)

@Serializable
data class RunnersListResponse(
    val runners: List<ActiveRunnerItem> = emptyList()
)

@Serializable
data class AiPatchItem(
    val path: String,
    val content: String
)

@Serializable
data class AiAutomateResponse(
    val success: Boolean = true,
    val provider: String = "gemini",
    val reply: String = "",
    val diff: String = "",
    val changedFiles: List<String> = emptyList(),
    val patches: List<AiPatchItem> = emptyList(),
    val mode: String = "assisted"
)

@Serializable
data class OpencodeProviderDto(
    val id: String,
    val name: String,
    val description: String = "",
    val hasFreeModels: Boolean = true
)

@Serializable
data class OpencodeModelDto(
    val id: String,
    val providerId: String,
    val displayName: String,
    val isFree: Boolean = false,
    val description: String = ""
)

@Serializable
data class OpencodeModelsResponse(
    val providers: List<OpencodeProviderDto> = emptyList(),
    val models: List<OpencodeModelDto> = emptyList()
)

