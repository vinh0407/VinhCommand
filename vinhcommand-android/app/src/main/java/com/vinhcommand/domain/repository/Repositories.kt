package com.vinhcommand.domain.repository

import com.vinhcommand.domain.model.*
import kotlinx.coroutines.flow.Flow

interface ComputerRepository {
    suspend fun getComputers(): Result<List<DesktopComputer>>
    suspend fun getComputer(id: String): Result<DesktopComputer>
    suspend fun saveComputer(computer: DesktopComputer): Result<Unit>
    suspend fun deleteComputer(id: String): Result<Unit>
    val computersFlow: Flow<List<DesktopComputer>>
}

interface ProjectRepository {
    suspend fun getProjects(): Result<List<Project>>
    suspend fun getProject(id: String): Result<Project>
    suspend fun getProjectDetail(id: String): Result<ProjectDetail>
    suspend fun saveProject(project: Project): Result<Unit>
    suspend fun refreshProjects(): Result<List<Project>>
    val projectsFlow: Flow<List<Project>>
}

interface AgentRepository {
    suspend fun getAgents(): Result<List<AIAgent>>
    suspend fun getAgent(id: String): Result<AIAgent>
    suspend fun getAgentDetail(id: String): Result<AgentDetail>
    suspend fun launchAgent(agentId: String, projectId: String?): Result<Unit>
    suspend fun stopAgent(agentId: String): Result<Unit>
    suspend fun sendPrompt(agentId: String, prompt: String, projectId: String): Result<String>
    val agentsFlow: Flow<List<AIAgent>>
}

interface TaskRepository {
    suspend fun getTasks(): Result<List<AgentTask>>
    suspend fun getTask(id: String): Result<AgentTask>
    suspend fun createTask(request: CreateTaskRequest): Result<AgentTask>
    suspend fun controlTask(request: TaskControlRequest): Result<Unit>
    suspend fun getTaskOutput(taskId: String): Result<List<String>>
    suspend fun getTaskTimeline(taskId: String): Result<List<TaskTimelineEvent>>
    suspend fun getTaskDiff(taskId: String): Result<GitDiff?>
    val tasksFlow: Flow<List<AgentTask>>
    val taskOutputFlow: Flow<Pair<String, String>> // taskId, output line
}

interface TerminalRepository {
    suspend fun createSession(shell: ShellType, cwd: String): Result<TerminalSession>
    suspend fun sendCommand(sessionId: String, command: String): Result<Unit>
    suspend fun resizeSession(sessionId: String, cols: Int, rows: Int): Result<Unit>
    suspend fun closeSession(sessionId: String): Result<Unit>
    val sessionFlow: Flow<TerminalSession>
    val outputFlow: Flow<TerminalOutput>
}

interface FileRepository {
    suspend fun listFiles(path: String): Result<List<FileNode>>
    suspend fun readFile(path: String): Result<FileContent>
    suspend fun writeFile(path: String, content: String): Result<FileOperationResponse>
    suspend fun createFile(path: String, content: String): Result<FileOperationResponse>
    suspend fun deleteFile(path: String): Result<FileOperationResponse>
    suspend fun renameFile(oldPath: String, newPath: String): Result<FileOperationResponse>
    val fileTreeFlow: Flow<List<FileNode>>
}

interface GitRepository {
    suspend fun getStatus(projectId: String): Result<GitStatusOverview>
    suspend fun getDiff(projectId: String, filePath: String): Result<GitDiff>
    suspend fun stageFile(projectId: String, filePath: String): Result<Unit>
    suspend fun unstageFile(projectId: String, filePath: String): Result<Unit>
    suspend fun commit(projectId: String, message: String): Result<Unit>
    suspend fun getBranches(projectId: String): Result<List<String>>
    suspend fun checkoutBranch(projectId: String, branch: String): Result<Unit>
    val gitStatusFlow: Flow<GitStatusOverview>
}

interface ProcessRepository {
    suspend fun getProcesses(): Result<List<ProcessItem>>
    suspend fun killProcess(pid: Int): Result<Unit>
    val processesFlow: Flow<List<ProcessItem>>
}

interface ServerRepository {
    suspend fun getServers(): Result<List<DevServer>>
    suspend fun startServer(projectId: String, port: Int): Result<DevServer>
    suspend fun stopServer(serverId: String): Result<Unit>
    val serversFlow: Flow<List<DevServer>>
}

interface SecurityRepository {
    suspend fun getSessionState(): Result<SessionState>
    suspend fun getAuditLogs(): Result<List<SecurityAuditLog>>
    suspend fun getPendingApprovals(): Result<List<CommandApprovalRequest>>
    suspend fun approveCommand(response: CommandApprovalResponse): Result<Unit>
    suspend fun getDeviceTrust(): Result<DeviceInfo>
    suspend fun setDeviceTrust(trust: Boolean): Result<Unit>
    suspend fun triggerKillSwitch(): Result<Unit>
    val sessionStateFlow: Flow<SessionState>
    val approvalsFlow: Flow<List<CommandApprovalRequest>>
}

interface NotificationRepository {
    suspend fun getNotifications(): Result<List<NotificationItem>>
    suspend fun markAsRead(id: String): Result<Unit>
    suspend fun markAllAsRead(): Result<Unit>
    suspend fun clearNotifications(): Result<Unit>
    val notificationsFlow: Flow<List<NotificationItem>>
    val unreadCountFlow: Flow<Int>
}

interface ConnectionRepository {
    suspend fun connect(config: ConnectionConfig): Result<AuthResponse>
    suspend fun disconnect(): Result<Unit>
    suspend fun pair(request: PairingRequest): Result<PairingChallenge>
    suspend fun authenticate(request: AuthRequest): Result<AuthResponse>
    suspend fun trustDevice(request: DeviceTrustRequest): Result<Unit>
    suspend fun refreshSession(): Result<AuthResponse>
    suspend fun refreshPcState(): Result<PcState>
    val connectionStateFlow: Flow<ConnectionState>
    val pcStateFlow: Flow<PcState>
}

interface CacheRepository {
    suspend fun saveRecentComputer(computer: DesktopComputer): Result<Unit>
    suspend fun getRecentComputers(): Result<List<DesktopComputer>>
    suspend fun saveProjectMetadata(project: Project): Result<Unit>
    suspend fun getCachedProjects(): Result<List<Project>>
    suspend fun saveTaskHistory(task: AgentTask): Result<Unit>
    suspend fun getCachedTasks(): Result<List<AgentTask>>
    suspend fun clearCache(): Result<Unit>
}
