package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class AIAgent(
    val id: String,
    val name: String,
    val description: String,
    val status: AgentStatus,
    val version: String,
    val capabilities: AgentCapabilities,
    val path: String? = null,
    val authStatus: AuthStatus? = null
)

@Keep
@Serializable
enum class AgentStatus {
    @SerialName("INSTALLED") INSTALLED,
    @SerialName("AVAILABLE") AVAILABLE,
    @SerialName("RUNNING") RUNNING,
    @SerialName("AUTHENTICATED") AUTHENTICATED,
    @SerialName("NOT_AUTHENTICATED") NOT_AUTHENTICATED,
    @SerialName("UNAVAILABLE") UNAVAILABLE,
    @SerialName("UNKNOWN") UNKNOWN
}

@Keep
@Serializable
enum class AuthStatus {
    @SerialName("authenticated") AUTHENTICATED,
    @SerialName("not_authenticated") NOT_AUTHENTICATED,
    @SerialName("expired") EXPIRED,
    @SerialName("error") ERROR
}

@Keep
@Serializable
data class AgentCapabilities(
    val prompt: Boolean,
    val streaming: Boolean,
    val terminal: Boolean,
    val projectContext: Boolean,
    val stopControl: Boolean,
    val screenStream: Boolean,
    val remoteInput: Boolean,
    val successRatePct: Int? = null
)

@Keep
@Serializable
data class AgentDetail(
    val agent: AIAgent,
    val runningTasks: List<AgentTask>,
    val recentLogs: List<String>
)
