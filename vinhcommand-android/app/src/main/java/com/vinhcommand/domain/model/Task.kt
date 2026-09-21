package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class AgentTask(
    val id: String,
    val projectId: String,
    val projectName: String,
    val agentId: String,
    val agentName: String,
    val prompt: String,
    val status: TaskStatus,
    val isAutonomous: Boolean,
    val maxIterations: Int,
    val currentIteration: Int,
    val stopOnTestsPass: Boolean,
    val stopOnBuildPass: Boolean,
    val createdAt: String,
    val runtimeSeconds: Long,
    val logs: List<String>,
    val timeline: List<TaskTimelineEvent>,
    val changedFiles: List<String> = emptyList(),
    val testResults: TestResults? = null,
    val gitDiff: GitDiff? = null,
    val workflow: TaskWorkflow = TaskWorkflow()
)

@Keep
@Serializable
enum class TaskStatus {
    @SerialName("QUEUED") QUEUED,
    @SerialName("STARTING") STARTING,
    @SerialName("RUNNING") RUNNING,
    @SerialName("WAITING_FOR_INPUT") WAITING_FOR_INPUT,
    @SerialName("WAITING_FOR_APPROVAL") WAITING_FOR_APPROVAL,
    @SerialName("COMPLETED") COMPLETED,
    @SerialName("FAILED") FAILED,
    @SerialName("STOPPED") STOPPED,
    @SerialName("CANCELLED") CANCELLED
}

@Keep
@Serializable
data class TaskTimelineEvent(
    val timestamp: String,
    val label: String,
    val status: TimelineStatus
)

@Keep
@Serializable
enum class TimelineStatus {
    @SerialName("info") INFO,
    @SerialName("success") SUCCESS,
    @SerialName("warning") WARNING,
    @SerialName("error") ERROR
}

@Keep
@Serializable
data class TestResults(
    val total: Int,
    val passed: Int,
    val failed: Int
)

@Keep
@Serializable
data class CreateTaskRequest(
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

@Keep
@Serializable
data class TaskControlRequest(
    val taskId: String,
    val action: TaskAction,
    val approvalId: String? = null
)

@Keep
@Serializable
enum class TaskAction {
    START, APPROVE, DENY, ACCEPT,
    @SerialName("continue") CONTINUE,
    @SerialName("stop") STOP,
    @SerialName("cancel") CANCEL,
    @SerialName("retry") RETRY
}

@Keep
@Serializable
data class TaskWorkflow(
    val cwd: String = "", val branch: String = "", val permission: String = "read-only",
    val agentSessionId: String = "", val testStatus: String = "not-run", val reviewState: String = "pending",
    val diff: String = "", val testCommands: List<TaskCommand> = emptyList(), val approval: TaskApproval? = null
)
@Keep
@Serializable
data class TaskCommand(val command: String = "", val exitCode: Int? = null, val status: String? = null)
@Keep
@Serializable
data class TaskApproval(val id: String, val command: String = "", val reason: String = "", val kind: String = "")

