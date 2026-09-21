package com.vinhcommand.network.api

import com.vinhcommand.domain.model.*
import com.vinhcommand.network.model.*
import retrofit2.Response
import retrofit2.http.*

interface VinhCommandApi {
    @POST("/api/tasks/{operation}")
    suspend fun workflowAction(@Path("operation") operation: String, @Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @GET("/api/state")
    suspend fun getPcState(): Response<ApiResponse<PcState>>

    @POST("/api/auth/disconnect")
    suspend fun disconnect(): Response<ApiResponse<Map<String, String>>>

    @POST("/api/auth/connect")
    suspend fun connect(@Body request: ConnectRequest): Response<ApiResponse<ConnectResponse>>

    @GET("/api/projects")
    suspend fun getProjects(): Response<ApiResponse<ProjectsResponse>>

    @POST("/api/projects/add")
    suspend fun addProject(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @POST("/api/projects/delete")
    suspend fun deleteProject(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @GET("/api/fs/browse")
    suspend fun browseDesktopFs(@Query("path") path: String? = null): Response<ApiResponse<FsBrowseResponse>>

    @GET("/api/runner/detect")
    suspend fun detectRunners(@Query("path") path: String): Response<ApiResponse<RunnerDetectResponse>>

    @POST("/api/runner/build-apk")
    suspend fun buildApk(@Body body: Map<String, String>): Response<ApiResponse<BuildApkResponse>>

    @POST("/api/runner/start")
    suspend fun startRunner(@Body body: Map<String, String>): Response<ApiResponse<RunnerStartResponse>>

    @POST("/api/runner/stop")
    suspend fun stopRunner(@Body body: Map<String, Int>): Response<ApiResponse<Map<String, String>>>

    @GET("/api/runner/list")
    suspend fun listRunners(): Response<ApiResponse<RunnersListResponse>>

    @GET("/api/opencode/models")
    suspend fun getOpencodeModels(): Response<ApiResponse<OpencodeModelsResponse>>

    @POST("/api/ai/automate")
    suspend fun aiAutomate(@Body body: Map<String, String>): Response<ApiResponse<AiAutomateResponse>>

    @POST("/api/ai/apply-patch")
    suspend fun applyAiPatch(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @POST("/api/git/clone")
    suspend fun cloneRepo(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @POST("/api/github/login")
    suspend fun githubLogin(@Body body: Map<String, String>): Response<ApiResponse<Map<String, String>>>

    @GET("/api/projects/{projectId}")
    suspend fun getProjectDetail(@Path("projectId") projectId: String): Response<ApiResponse<ProjectDetailResponse>>

    @GET("/api/agents")
    suspend fun getAgents(): Response<ApiResponse<AgentsResponse>>

    @POST("/api/agents/scan")
    suspend fun scanAgents(): Response<ApiResponse<AgentsResponse>>

    @GET("/api/agents/{agentId}")
    suspend fun getAgentDetail(@Path("agentId") agentId: String): Response<ApiResponse<AgentDetailResponse>>

    @POST("/api/agents/{agentId}/launch")
    suspend fun launchAgent(@Path("agentId") agentId: String, @Body projectId: String?): Response<ApiResponse<Unit>>

    @POST("/api/agents/{agentId}/stop")
    suspend fun stopAgent(@Path("agentId") agentId: String): Response<ApiResponse<Unit>>

    @POST("/api/agents/{agentId}/prompt")
    suspend fun sendPrompt(
        @Path("agentId") agentId: String,
        @Body prompt: Map<String, String>
    ): Response<ApiResponse<Map<String, String>>>

    @GET("/api/tasks")
    suspend fun getTasks(): Response<ApiResponse<TasksResponse>>

    @GET("/api/tasks/{taskId}")
    suspend fun getTaskDetail(@Path("taskId") taskId: String): Response<ApiResponse<TaskDetailResponse>>

    @POST("/api/tasks")
    suspend fun createTask(@Body request: CreateTaskRequestDto): Response<ApiResponse<CreateTaskResponse>>

    @POST("/api/tasks/control")
    suspend fun controlTask(@Body request: TaskControlRequestDto): Response<ApiResponse<Unit>>

    @POST("/api/terminal/create")
    suspend fun createTerminal(@Body request: TerminalCreateRequest): Response<ApiResponse<TerminalCreateResponse>>

    @POST("/api/terminal/command")
    suspend fun sendTerminalCommand(@Body request: TerminalCommandRequest): Response<ApiResponse<Unit>>

    @POST("/api/terminal/resize")
    suspend fun resizeTerminal(@Body request: TerminalResizeRequest): Response<ApiResponse<Unit>>

    @DELETE("/api/terminal/{sessionId}")
    suspend fun closeTerminal(@Path("sessionId") sessionId: String): Response<ApiResponse<Unit>>

    @GET("/api/files/list")
    suspend fun listFiles(@Query("path") path: String): Response<ApiResponse<FileListResponse>>

    @GET("/api/files/read")
    suspend fun readFile(@Query("path") path: String): Response<ApiResponse<FileReadResponse>>

    @POST("/api/files/write")
    suspend fun writeFile(@Body request: FileWriteRequest): Response<ApiResponse<FileWriteResponse>>

    @POST("/api/files/operation")
    suspend fun fileOperation(@Body request: FileOperationRequestDto): Response<ApiResponse<FileWriteResponse>>

    @GET("/api/git/status")
    suspend fun getGitStatus(@Query("projectId") projectId: String): Response<ApiResponse<GitStatusResponse>>

    @GET("/api/git/diff")
    suspend fun getGitDiff(
        @Query("projectId") projectId: String,
        @Query("filePath") filePath: String
    ): Response<ApiResponse<GitDiffResponse>>

    @POST("/api/git/stage")
    suspend fun stageFile(@Query("projectId") projectId: String, @Query("filePath") filePath: String): Response<ApiResponse<Unit>>

    @POST("/api/git/unstage")
    suspend fun unstageFile(@Query("projectId") projectId: String, @Query("filePath") filePath: String): Response<ApiResponse<Unit>>

    @POST("/api/git/commit")
    suspend fun commit(@Query("projectId") projectId: String, @Body request: GitCommitRequest): Response<ApiResponse<Unit>>

    @GET("/api/git/branches")
    suspend fun getBranches(@Query("projectId") projectId: String): Response<ApiResponse<List<String>>>

    @POST("/api/git/checkout")
    suspend fun checkoutBranch(@Query("projectId") projectId: String, @Query("branch") branch: String): Response<ApiResponse<Unit>>

    @GET("/api/processes")
    suspend fun getProcesses(): Response<ApiResponse<ProcessesResponse>>

    @POST("/api/processes/{pid}/kill")
    suspend fun killProcess(@Path("pid") pid: Int): Response<ApiResponse<Unit>>

    @GET("/api/servers")
    suspend fun getServers(): Response<ApiResponse<ServersResponse>>

    @POST("/api/servers/start")
    suspend fun startServer(@Body request: StartServerRequest): Response<ApiResponse<DevServer>>

    @POST("/api/servers/{serverId}/stop")
    suspend fun stopServer(@Path("serverId") serverId: String): Response<ApiResponse<Unit>>

    @GET("/api/security/audit")
    suspend fun getAuditLogs(): Response<ApiResponse<SecurityAuditResponse>>

    @GET("/api/security/approvals")
    suspend fun getPendingApprovals(): Response<ApiResponse<ApprovalsResponse>>

    @POST("/api/security/approval")
    suspend fun approveCommand(@Body request: ApprovalRequestDto): Response<ApiResponse<Unit>>

    @GET("/api/security/device")
    suspend fun getDeviceTrust(): Response<ApiResponse<DeviceTrustResponse>>

    @POST("/api/security/device/trust")
    suspend fun setDeviceTrust(@Body trust: Boolean): Response<ApiResponse<Unit>>

    @POST("/api/system/kill-switch")
    suspend fun triggerKillSwitch(): Response<ApiResponse<KillSwitchResponse>>

    @GET("/api/notifications")
    suspend fun getNotifications(): Response<ApiResponse<NotificationsResponse>>

    @POST("/api/notifications/{id}/read")
    suspend fun markNotificationRead(@Path("id") id: String): Response<ApiResponse<Unit>>

    @POST("/api/notifications/read-all")
    suspend fun markAllNotificationsRead(): Response<ApiResponse<Unit>>

    @DELETE("/api/notifications")
    suspend fun clearNotifications(): Response<ApiResponse<Unit>>

    @GET("/api/system/metrics")
    suspend fun getMetrics(): Response<ApiResponse<MetricsResponse>>
}
