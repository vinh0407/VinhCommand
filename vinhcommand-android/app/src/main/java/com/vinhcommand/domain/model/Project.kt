package com.vinhcommand.domain.model

import androidx.annotation.Keep
import kotlinx.serialization.Serializable

@Keep
@Serializable
data class Project(
    val id: String,
    val name: String,
    val path: String,
    val framework: String,
    val language: String,
    val gitBranch: String,
    val modifiedFilesCount: Int,
    val runningProcessesCount: Int,
    val activeServersCount: Int,
    val activeTasksCount: Int,
    val availableAgents: List<String>,
    val accessMode: String = "denied"
)

@Keep
@Serializable
data class ProjectDetail(
    val project: Project,
    val gitStatus: GitStatusOverview?,
    val devServers: List<DevServer>,
    val processes: List<ProcessItem>,
    val recentTasks: List<AgentTask>
)
