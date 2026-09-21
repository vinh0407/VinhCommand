package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class DesktopComputer(
    val id: String,
    val name: String,
    val desktopId: String,
    val status: ComputerStatus,
    val os: String,
    val ipAddress: String,
    val trusted: Boolean,
    val lastConnectedAt: String,
    val stats: HardwareStats? = null,
    val statsSummary: StatsSummary? = null
)

@Keep
@Serializable
enum class ComputerStatus {
    @SerialName("online") ONLINE,
    @SerialName("offline") OFFLINE
}

@Keep
@Serializable
data class HardwareStats(
    val cpuUsagePct: Int,
    val ramUsagePct: Int,
    val diskUsagePct: Int,
    val networkKbps: Int,
    val os: String,
    val uptimeSeconds: Long
)

@Keep
@Serializable
data class StatsSummary(
    val agentsCount: Int,
    val projectsCount: Int,
    val tasksCount: Int,
    val processesCount: Int,
    val serversCount: Int
)
