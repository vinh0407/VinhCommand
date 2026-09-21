package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class ProcessItem(
    val pid: Int,
    val name: String,
    val cpuPct: Double,
    val ramMb: Long,
    val status: ProcessStatus
)

@Keep
@Serializable
enum class ProcessStatus {
    @SerialName("running") RUNNING,
    @SerialName("sleeping") SLEEPING,
    @SerialName("stopped") STOPPED
}

@Keep
@Serializable
data class DevServer(
    val id: String,
    val projectName: String,
    val port: Int,
    val framework: String,
    val url: String,
    val pid: Int,
    val status: ServerStatus
)

@Keep
@Serializable
enum class ServerStatus {
    @SerialName("LIVE") LIVE,
    @SerialName("STOPPED") STOPPED,
    @SerialName("ERROR") ERROR
}
