package com.vinhcommand.network.websocket

import com.vinhcommand.domain.model.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed class WsEvent {
    @SerialName("connection.status") data class ConnectionStatus(
        val status: String,
        val url: String? = null
    ) : WsEvent()

    @SerialName("hardware.stats") data class HardwareStats(
        val cpuUsagePct: Int,
        val ramUsagePct: Int,
        val diskUsagePct: Int,
        val networkKbps: Int,
        val os: String,
        val uptimeSeconds: Long
    ) : WsEvent()

    @SerialName("agent.status") data class AgentStatus(
        val agentId: String,
        val status: String,
        val message: String? = null
    ) : WsEvent()

    @SerialName("agent.output") data class AgentOutput(
        val taskId: String,
        val line: String,
        val timestamp: String,
        val isError: Boolean = false
    ) : WsEvent()

    @SerialName("task.created") data class TaskCreated(
        val task: AgentTask
    ) : WsEvent()

    @SerialName("task.started") data class TaskStarted(
        val taskId: String
    ) : WsEvent()

    @SerialName("task.progress") data class TaskProgress(
        val taskId: String,
        val currentIteration: Int,
        val maxIterations: Int,
        val status: String,
        val message: String
    ) : WsEvent()

    @SerialName("task.completed") data class TaskCompleted(
        val taskId: String,
        val result: TaskResult
    ) : WsEvent()

    @SerialName("task.failed") data class TaskFailed(
        val taskId: String,
        val error: String
    ) : WsEvent()

    @SerialName("terminal.output") data class TerminalOutput(
        val sessionId: String,
        val output: String,
        val isError: Boolean = false
    ) : WsEvent()

    @SerialName("process.updated") data class ProcessUpdated(
        val processes: List<ProcessItem>
    ) : WsEvent()

    @SerialName("server.updated") data class ServerUpdated(
        val servers: List<DevServer>
    ) : WsEvent()

    @SerialName("security.alert") data class SecurityAlert(
        val level: String,
        val event: String,
        val details: String,
        val timestamp: String
    ) : WsEvent()

    @SerialName("notification.created") data class NotificationCreated(
        val notification: NotificationItem
    ) : WsEvent()

    @SerialName("screen.frame") data class ScreenFrame(
        val imageData: String,
        val width: Int,
        val height: Int,
        val timestamp: Long
    ) : WsEvent()

    @SerialName("project.updated") data class ProjectUpdated(
        val project: Project
    ) : WsEvent()

    @SerialName("git.updated") data class GitUpdated(
        val projectId: String,
        val status: GitStatusOverview
    ) : WsEvent()

    @SerialName("approval.requested") data class ApprovalRequested(
        val approval: CommandApprovalRequest
    ) : WsEvent()

    @SerialName("approval.resolved") data class ApprovalResolved(
        val approvalId: String,
        val allowed: Boolean
    ) : WsEvent()
}

@Serializable
data class TaskResult(
    val success: Boolean,
    val changedFiles: List<String>,
    val testResults: TestResults?,
    val gitDiff: GitDiff?
)

@Serializable
data class WsEnvelope(
    val event: String,
    val payload: String // JSON string of the actual event
)

@Serializable
data class WsSendEnvelope(
    val event: String,
    val payload: kotlinx.serialization.json.JsonElement
)

// Events sent from Android to Desktop
@Serializable
sealed class WsOutgoingEvent {
    @SerialName("subscribe") data class Subscribe(
        val events: List<String>
    ) : WsOutgoingEvent()

    @SerialName("unsubscribe") data class Unsubscribe(
        val events: List<String>
    ) : WsOutgoingEvent()

    @SerialName("terminal.command") data class TerminalCommand(
        val sessionId: String,
        val command: String
    ) : WsOutgoingEvent()

    @SerialName("terminal.resize") data class TerminalResize(
        val sessionId: String,
        val cols: Int,
        val rows: Int
    ) : WsOutgoingEvent()

    @SerialName("task.control") data class TaskControl(
        val taskId: String,
        val action: String
    ) : WsOutgoingEvent()

    @SerialName("agent.prompt") data class AgentPrompt(
        val agentId: String,
        val prompt: String,
        val projectId: String
    ) : WsOutgoingEvent()

    @SerialName("screen.control") data class ScreenControl(
        val enabled: Boolean,
        val mode: String? = null
    ) : WsOutgoingEvent()

    @SerialName("input.event") data class InputEvent(
        val type: String,
        val x: Float,
        val y: Float,
        val button: String? = null,
        val keyCode: Int? = null,
        val keyAction: String? = null,
        val text: String? = null,
        val modifiers: List<String> = emptyList()
    ) : WsOutgoingEvent()

    @SerialName("ping") data class Ping(
        val timestamp: Long
    ) : WsOutgoingEvent()
}
