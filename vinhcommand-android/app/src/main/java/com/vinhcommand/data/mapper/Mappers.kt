package com.vinhcommand.data.mapper

import com.vinhcommand.domain.model.*
import com.vinhcommand.network.model.*
import com.vinhcommand.data.local.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString

object ComputerMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: ComputerEntity): DesktopComputer {
        return DesktopComputer(
            id = entity.id,
            name = entity.name,
            desktopId = entity.desktopId,
            status = try { ComputerStatus.valueOf(entity.status.uppercase()) } catch(e: Exception) { ComputerStatus.OFFLINE },
            os = entity.os,
            ipAddress = entity.ipAddress,
            trusted = entity.trusted,
            lastConnectedAt = entity.lastConnectedAt,
            stats = entity.statsJson?.let { json.decodeFromString<HardwareStats>(it) },
            statsSummary = entity.statsSummaryJson?.let { json.decodeFromString<StatsSummary>(it) }
        )
    }

    fun toDomainList(entities: List<ComputerEntity>): List<DesktopComputer> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: DesktopComputer): ComputerEntity {
        return ComputerEntity(
            id = domain.id,
            name = domain.name,
            desktopId = domain.desktopId,
            status = domain.status.name,
            os = domain.os,
            ipAddress = domain.ipAddress,
            trusted = domain.trusted,
            lastConnectedAt = domain.lastConnectedAt,
            statsJson = domain.stats?.let { json.encodeToString(it) },
            statsSummaryJson = domain.statsSummary?.let { json.encodeToString(it) }
        )
    }
}

object ProjectMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: ProjectEntity): Project {
        return Project(
            id = entity.id,
            name = entity.name,
            path = entity.path,
            framework = entity.framework,
            language = entity.language,
            gitBranch = entity.gitBranch,
            modifiedFilesCount = entity.modifiedFilesCount,
            runningProcessesCount = entity.runningProcessesCount,
            activeServersCount = entity.activeServersCount,
            activeTasksCount = entity.activeTasksCount,
            availableAgents = try { json.decodeFromString(entity.availableAgentsJson) } catch(e: Exception) { emptyList() }
        )
    }

    fun toDomainList(entities: List<ProjectEntity>): List<Project> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: Project): ProjectEntity {
        return ProjectEntity(
            id = domain.id,
            name = domain.name,
            path = domain.path,
            framework = domain.framework,
            language = domain.language,
            gitBranch = domain.gitBranch,
            modifiedFilesCount = domain.modifiedFilesCount,
            runningProcessesCount = domain.runningProcessesCount,
            activeServersCount = domain.activeServersCount,
            activeTasksCount = domain.activeTasksCount,
            availableAgentsJson = json.encodeToString(domain.availableAgents)
        )
    }

    fun toDomainDetail(dto: ProjectDetailResponse): ProjectDetail {
        return ProjectDetail(
            project = dto.project,
            gitStatus = dto.gitStatus,
            devServers = dto.devServers,
            processes = dto.processes,
            recentTasks = dto.recentTasks
        )
    }
}

object AgentMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: AgentEntity): AIAgent {
        return AIAgent(
            id = entity.id,
            name = entity.name,
            description = entity.description,
            status = try { AgentStatus.valueOf(entity.status.uppercase()) } catch(e: Exception) { AgentStatus.UNKNOWN },
            version = entity.version,
            capabilities = try { json.decodeFromString(entity.capabilitiesJson) } catch(e: Exception) { AgentCapabilities(false, false, false, false, false, false, false) },
            path = entity.path,
            authStatus = entity.authStatus?.let { try { AuthStatus.valueOf(it.uppercase()) } catch(e: Exception) { AuthStatus.NOT_AUTHENTICATED } }
        )
    }

    fun toDomainList(entities: List<AgentEntity>): List<AIAgent> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: AIAgent): AgentEntity {
        return AgentEntity(
            id = domain.id,
            name = domain.name,
            description = domain.description,
            status = domain.status.name,
            version = domain.version,
            capabilitiesJson = json.encodeToString(domain.capabilities),
            path = domain.path,
            authStatus = domain.authStatus?.name
        )
    }

    fun toDomainDetail(dto: AgentDetailResponse): AgentDetail {
        return AgentDetail(
            agent = dto.agent,
            runningTasks = dto.runningTasks,
            recentLogs = dto.recentLogs
        )
    }
}

object TaskMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: TaskEntity): AgentTask {
        return AgentTask(
            id = entity.id,
            projectId = entity.projectId,
            projectName = entity.projectName,
            agentId = entity.agentId,
            agentName = entity.agentName,
            prompt = entity.prompt,
            status = try { TaskStatus.valueOf(entity.status.uppercase()) } catch(e: Exception) { TaskStatus.QUEUED },
            isAutonomous = entity.isAutonomous,
            maxIterations = entity.maxIterations,
            currentIteration = entity.currentIteration,
            stopOnTestsPass = entity.stopOnTestsPass,
            stopOnBuildPass = entity.stopOnBuildPass,
            createdAt = entity.createdAt,
            runtimeSeconds = entity.runtimeSeconds,
            logs = try { json.decodeFromString(entity.logsJson) } catch(e: Exception) { emptyList() },
            timeline = try { json.decodeFromString(entity.timelineJson) } catch(e: Exception) { emptyList() },
            changedFiles = try { json.decodeFromString(entity.changedFilesJson) } catch(e: Exception) { emptyList() },
            testResults = entity.testResultsJson?.let { try { json.decodeFromString<TestResults>(it) } catch(e: Exception) { null } },
            gitDiff = entity.gitDiffJson?.let { try { json.decodeFromString<GitDiff>(it) } catch(e: Exception) { null } }
        )
    }

    fun toDomainList(entities: List<TaskEntity>): List<AgentTask> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: AgentTask): TaskEntity {
        return TaskEntity(
            id = domain.id,
            projectId = domain.projectId,
            projectName = domain.projectName,
            agentId = domain.agentId,
            agentName = domain.agentName,
            prompt = domain.prompt,
            status = domain.status.name,
            isAutonomous = domain.isAutonomous,
            maxIterations = domain.maxIterations,
            currentIteration = domain.currentIteration,
            stopOnTestsPass = domain.stopOnTestsPass,
            stopOnBuildPass = domain.stopOnBuildPass,
            createdAt = domain.createdAt,
            runtimeSeconds = domain.runtimeSeconds,
            logsJson = json.encodeToString(domain.logs),
            timelineJson = json.encodeToString(domain.timeline),
            changedFilesJson = json.encodeToString(domain.changedFiles),
            testResultsJson = domain.testResults?.let { json.encodeToString(it) },
            gitDiffJson = domain.gitDiff?.let { json.encodeToString(it) }
        )
    }

    fun toDomainDetail(dto: TaskDetailResponse): Pair<AgentTask, List<String>> {
        return dto.task to dto.logs
    }
}

object TerminalMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: TerminalSessionEntity): TerminalSession {
        return TerminalSession(
            id = entity.id,
            shellName = try { ShellType.valueOf(entity.shellName.uppercase()) } catch(e: Exception) { ShellType.BASH },
            cwd = entity.cwd,
            history = try { json.decodeFromString(entity.historyJson) } catch(e: Exception) { emptyList() },
            logs = try { json.decodeFromString(entity.logsJson) } catch(e: Exception) { emptyList() }
        )
    }

    fun toDomainList(entities: List<TerminalSessionEntity>): List<TerminalSession> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: TerminalSession): TerminalSessionEntity {
        return TerminalSessionEntity(
            id = domain.id,
            shellName = domain.shellName.name,
            cwd = domain.cwd,
            historyJson = json.encodeToString(domain.history),
            logsJson = json.encodeToString(domain.logs)
        )
    }
}

object FileMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: FileNodeEntity): FileNode {
        return FileNode(
            id = entity.id,
            name = entity.name,
            path = entity.path,
            isDirectory = entity.isDirectory,
            sizeBytes = entity.sizeBytes ?: 0L,
            modifiedAt = entity.modifiedAt ?: "",
            children = entity.childrenJson?.let { try { json.decodeFromString(it) } catch(e: Exception) { null } }
        )
    }

    fun toDomainList(entities: List<FileNodeEntity>): List<FileNode> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: FileNode): FileNodeEntity {
        return FileNodeEntity(
            id = domain.id,
            name = domain.name,
            path = domain.path,
            isDirectory = domain.isDirectory,
            sizeBytes = domain.sizeBytes,
            modifiedAt = domain.modifiedAt,
            childrenJson = domain.children?.let { json.encodeToString(it) }
        )
    }

    fun toDomainContent(dto: FileReadResponse): FileContent {
        return FileContent(
            path = dto.path,
            content = dto.content,
            encoding = dto.encoding,
            sizeBytes = dto.sizeBytes,
            modifiedAt = dto.modifiedAt
        )
    }
}

object GitMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: GitStatusEntity): GitStatusOverview {
        return GitStatusOverview(
            branch = entity.branch,
            ahead = entity.ahead,
            behind = entity.behind,
            files = try { json.decodeFromString(entity.filesJson) } catch(e: Exception) { emptyList() },
            recentCommits = try { json.decodeFromString(entity.recentCommitsJson) } catch(e: Exception) { emptyList() }
        )
    }

    fun toEntity(domain: GitStatusOverview, projectId: String): GitStatusEntity {
        return GitStatusEntity(
            projectId = projectId,
            branch = domain.branch,
            ahead = domain.ahead,
            behind = domain.behind,
            filesJson = json.encodeToString(domain.files),
            recentCommitsJson = json.encodeToString(domain.recentCommits)
        )
    }

    fun toDomainDiff(dto: GitDiffResponse): GitDiff {
        return GitDiff(
            filePath = dto.filePath,
            oldContent = dto.oldContent,
            newContent = dto.newContent,
            hunks = dto.hunks
        )
    }
}

object ProcessMapper {
    fun toDomain(entity: ProcessEntity): ProcessItem {
        return ProcessItem(
            pid = entity.pid,
            name = entity.name,
            cpuPct = entity.cpuPct,
            ramMb = entity.ramMb,
            status = try { ProcessStatus.valueOf(entity.status.uppercase()) } catch(e: Exception) { ProcessStatus.RUNNING }
        )
    }

    fun toDomainList(entities: List<ProcessEntity>): List<ProcessItem> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: ProcessItem): ProcessEntity {
        return ProcessEntity(
            pid = domain.pid,
            name = domain.name,
            cpuPct = domain.cpuPct,
            ramMb = domain.ramMb,
            status = domain.status.name
        )
    }
}

object ServerMapper {
    fun toDomain(entity: ServerEntity): DevServer {
        return DevServer(
            id = entity.id,
            projectName = entity.projectName,
            port = entity.port,
            framework = entity.framework,
            url = entity.url,
            pid = entity.pid,
            status = try { ServerStatus.valueOf(entity.status.uppercase()) } catch(e: Exception) { ServerStatus.STOPPED }
        )
    }

    fun toDomainList(entities: List<ServerEntity>): List<DevServer> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: DevServer): ServerEntity {
        return ServerEntity(
            id = domain.id,
            projectName = domain.projectName,
            port = domain.port,
            framework = domain.framework,
            url = domain.url,
            pid = domain.pid,
            status = domain.status.name
        )
    }
}

object SecurityMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: AuditLogEntity): SecurityAuditLog {
        return SecurityAuditLog(
            id = entity.id,
            timestamp = entity.timestamp,
            event = entity.event,
            details = entity.details,
            level = try { SecurityLevel.valueOf(entity.level.uppercase()) } catch(e: Exception) { SecurityLevel.INFO }
        )
    }

    fun toDomainList(entities: List<AuditLogEntity>): List<SecurityAuditLog> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: SecurityAuditLog): AuditLogEntity {
        return AuditLogEntity(
            id = domain.id,
            timestamp = domain.timestamp,
            event = domain.event,
            details = domain.details,
            level = domain.level.name
        )
    }

    fun toDomainApproval(entity: ApprovalEntity): CommandApprovalRequest {
        return CommandApprovalRequest(
            approvalId = entity.approvalId,
            command = entity.command,
            projectName = entity.projectName,
            riskLevel = try { CommandRiskLevel.valueOf(entity.riskLevel.uppercase()) } catch(e: Exception) { CommandRiskLevel.WARNING },
            reason = entity.reason,
            timestamp = entity.timestamp
        )
    }

    fun toDomainApprovalList(entities: List<ApprovalEntity>): List<CommandApprovalRequest> {
        return entities.map { toDomainApproval(it) }
    }

    fun toEntity(domain: CommandApprovalRequest): ApprovalEntity {
        return ApprovalEntity(
            approvalId = domain.approvalId,
            command = domain.command,
            projectName = domain.projectName,
            riskLevel = domain.riskLevel.name,
            reason = domain.reason,
            timestamp = domain.timestamp
        )
    }

    fun toDomainDevice(entity: DeviceInfoEntity): DeviceInfo {
        return DeviceInfo(
            deviceId = entity.deviceId,
            name = entity.name,
            platform = entity.platform,
            trusted = entity.trusted,
            lastConnectedAt = entity.lastConnectedAt,
            appVersion = entity.appVersion
        )
    }

    fun toEntity(domain: DeviceInfo): DeviceInfoEntity {
        return DeviceInfoEntity(
            deviceId = domain.deviceId,
            name = domain.name,
            platform = domain.platform,
            trusted = domain.trusted,
            lastConnectedAt = domain.lastConnectedAt,
            appVersion = domain.appVersion
        )
    }
}

object NotificationMapper {
    private val json = Json { ignoreUnknownKeys = true }

    fun toDomain(entity: NotificationEntity): NotificationItem {
        return NotificationItem(
            id = entity.id,
            timestamp = entity.timestamp,
            title = entity.title,
            message = entity.message,
            type = try { NotificationType.valueOf(entity.type.uppercase()) } catch(e: Exception) { NotificationType.SYSTEM },
            read = entity.read,
            actionUrl = entity.actionUrl,
            metadata = try { json.decodeFromString(entity.metadataJson) } catch(e: Exception) { emptyMap() }
        )
    }

    fun toDomainList(entities: List<NotificationEntity>): List<NotificationItem> {
        return entities.map { toDomain(it) }
    }

    fun toEntity(domain: NotificationItem): NotificationEntity {
        return NotificationEntity(
            id = domain.id,
            timestamp = domain.timestamp,
            title = domain.title,
            message = domain.message,
            type = domain.type.name,
            read = domain.read,
            actionUrl = domain.actionUrl,
            metadataJson = json.encodeToString(domain.metadata)
        )
    }
}