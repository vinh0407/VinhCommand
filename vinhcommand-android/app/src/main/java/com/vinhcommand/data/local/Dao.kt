package com.vinhcommand.data.local

import androidx.room.*
import com.vinhcommand.domain.model.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ComputerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(computers: List<ComputerEntity>)

    @Query("SELECT * FROM computers ORDER BY lastConnectedAt DESC")
    fun getAll(): Flow<List<ComputerEntity>>

    @Query("SELECT * FROM computers WHERE id = :id")
    suspend fun getById(id: String): ComputerEntity?

    @Query("SELECT * FROM computers WHERE trusted = 1")
    fun getTrusted(): Flow<List<ComputerEntity>>

    @Delete
    suspend fun delete(computer: ComputerEntity)

    @Query("DELETE FROM computers")
    suspend fun clearAll()
}

@Dao
interface ProjectDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(projects: List<ProjectEntity>)

    @Query("SELECT * FROM projects ORDER BY name ASC")
    fun getAll(): Flow<List<ProjectEntity>>

    @Query("SELECT * FROM projects WHERE id = :id")
    suspend fun getById(id: String): ProjectEntity?

    @Delete
    suspend fun delete(project: ProjectEntity)

    @Query("DELETE FROM projects")
    suspend fun clearAll()
}

@Dao
interface AgentDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(agents: List<AgentEntity>)

    @Query("SELECT * FROM agents ORDER BY name ASC")
    fun getAll(): Flow<List<AgentEntity>>

    @Query("SELECT * FROM agents WHERE id = :id")
    suspend fun getById(id: String): AgentEntity?

    @Query("SELECT * FROM agents WHERE status = 'RUNNING'")
    fun getRunning(): Flow<List<AgentEntity>>

    @Delete
    suspend fun delete(agent: AgentEntity)

    @Query("DELETE FROM agents")
    suspend fun clearAll()
}

@Dao
interface TaskDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("SELECT * FROM tasks ORDER BY createdAt DESC")
    fun getAll(): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE id = :id")
    suspend fun getById(id: String): TaskEntity?

    @Query("SELECT * FROM tasks WHERE projectId = :projectId ORDER BY createdAt DESC")
    fun getByProject(projectId: String): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE status = 'RUNNING'")
    fun getRunning(): Flow<List<TaskEntity>>

    @Query("SELECT * FROM tasks WHERE status IN ('RUNNING', 'QUEUED', 'STARTING', 'WAITING_FOR_INPUT', 'WAITING_FOR_APPROVAL')")
    fun getActive(): Flow<List<TaskEntity>>

    @Delete
    suspend fun delete(task: TaskEntity)

    @Query("DELETE FROM tasks WHERE createdAt < :cutoffDate")
    suspend fun deleteOld(cutoffDate: String)

    @Query("DELETE FROM tasks")
    suspend fun clearAll()
}

@Dao
interface NotificationDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(notifications: List<NotificationEntity>)

    @Query("SELECT * FROM notifications ORDER BY timestamp DESC")
    fun getAll(): Flow<List<NotificationEntity>>

    @Query("SELECT * FROM notifications WHERE read = 0 ORDER BY timestamp DESC")
    fun getUnread(): Flow<List<NotificationEntity>>

    @Query("SELECT COUNT(*) FROM notifications WHERE read = 0")
    fun getUnreadCount(): Flow<Int>

    @Query("UPDATE notifications SET read = 1 WHERE id = :id")
    suspend fun markAsRead(id: String)

    @Query("UPDATE notifications SET read = 1")
    suspend fun markAllAsRead()

    @Delete
    suspend fun delete(notification: NotificationEntity)

    @Query("DELETE FROM notifications WHERE timestamp < :cutoffDate")
    suspend fun deleteOld(cutoffDate: String)

    @Query("DELETE FROM notifications")
    suspend fun clearAll()
}

@Dao
interface TerminalSessionDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(session: TerminalSessionEntity)

    @Query("SELECT * FROM terminal_sessions WHERE id = :id")
    suspend fun getById(id: String): TerminalSessionEntity?

    @Query("SELECT * FROM terminal_sessions")
    fun getAll(): Flow<List<TerminalSessionEntity>>

    @Delete
    suspend fun delete(session: TerminalSessionEntity)

    @Query("DELETE FROM terminal_sessions")
    suspend fun clearAll()
}

@Dao
interface FileNodeDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(nodes: List<FileNodeEntity>)

    @Query("SELECT * FROM file_nodes WHERE path = :path")
    suspend fun getByPath(path: String): FileNodeEntity?

    @Query("SELECT * FROM file_nodes")
    fun getAll(): Flow<List<FileNodeEntity>>

    @Delete
    suspend fun delete(node: FileNodeEntity)

    @Query("DELETE FROM file_nodes")
    suspend fun clearAll()
}

@Dao
interface GitStatusDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(status: GitStatusEntity)

    @Query("SELECT * FROM git_status WHERE projectId = :projectId")
    suspend fun getByProject(projectId: String): GitStatusEntity?

    @Query("SELECT * FROM git_status")
    fun getAll(): Flow<List<GitStatusEntity>>

    @Delete
    suspend fun delete(status: GitStatusEntity)

    @Query("DELETE FROM git_status")
    suspend fun clearAll()
}

@Dao
interface ProcessDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(processes: List<ProcessEntity>)

    @Query("SELECT * FROM processes")
    fun getAll(): Flow<List<ProcessEntity>>

    @Delete
    suspend fun delete(process: ProcessEntity)

    @Query("DELETE FROM processes")
    suspend fun clearAll()
}

@Dao
interface ServerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(servers: List<ServerEntity>)

    @Query("SELECT * FROM servers")
    fun getAll(): Flow<List<ServerEntity>>

    @Query("SELECT * FROM servers WHERE status = 'LIVE'")
    fun getLive(): Flow<List<ServerEntity>>

    @Delete
    suspend fun delete(server: ServerEntity)

    @Query("DELETE FROM servers")
    suspend fun clearAll()
}

@Dao
interface AuditLogDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(logs: List<AuditLogEntity>)

    @Query("SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 100")
    fun getRecent(): Flow<List<AuditLogEntity>>

    @Delete
    suspend fun delete(log: AuditLogEntity)

    @Query("DELETE FROM audit_logs WHERE timestamp < :cutoffDate")
    suspend fun deleteOld(cutoffDate: String)

    @Query("DELETE FROM audit_logs")
    suspend fun clearAll()
}

@Dao
interface ApprovalDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(approvals: List<ApprovalEntity>)

    @Query("SELECT * FROM approvals ORDER BY timestamp DESC")
    fun getAll(): Flow<List<ApprovalEntity>>

    @Query("SELECT * FROM approvals WHERE approvalId = :id")
    suspend fun getById(id: String): ApprovalEntity?

    @Delete
    suspend fun delete(approval: ApprovalEntity)

    @Query("DELETE FROM approvals")
    suspend fun clearAll()
}

@Dao
interface DeviceInfoDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(device: DeviceInfoEntity)

    @Query("SELECT * FROM device_info WHERE deviceId = :deviceId")
    suspend fun getById(deviceId: String): DeviceInfoEntity?

    @Query("SELECT * FROM device_info")
    fun getAll(): Flow<List<DeviceInfoEntity>>

    @Delete
    suspend fun delete(device: DeviceInfoEntity)

    @Query("DELETE FROM device_info")
    suspend fun clearAll()
}

@Dao
interface SessionStateDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(state: SessionStateEntity)

    @Query("SELECT * FROM session_state WHERE id = 'current'")
    suspend fun getCurrent(): SessionStateEntity?

    @Delete
    suspend fun delete(state: SessionStateEntity)

    @Query("DELETE FROM session_state")
    suspend fun clearAll()
}

@Dao
interface RecentComputerDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(computer: RecentComputerEntity)

    @Query("SELECT * FROM recent_computers ORDER BY lastUsed DESC LIMIT 10")
    fun getRecent(): Flow<List<RecentComputerEntity>>

    @Delete
    suspend fun delete(computer: RecentComputerEntity)

    @Query("DELETE FROM recent_computers")
    suspend fun clearAll()
}

@Dao
interface PromptTemplateDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(templates: List<PromptTemplateEntity>)

    @Query("SELECT * FROM prompt_templates ORDER BY category, name")
    fun getAll(): Flow<List<PromptTemplateEntity>>

    @Query("SELECT * FROM prompt_templates WHERE category = :category")
    fun getByCategory(category: String): Flow<List<PromptTemplateEntity>>

    @Delete
    suspend fun delete(template: PromptTemplateEntity)

    @Query("DELETE FROM prompt_templates")
    suspend fun clearAll()
}

@Dao
interface PromptHistoryDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(history: PromptHistoryEntity)

    @Query("SELECT * FROM prompt_history ORDER BY timestamp DESC LIMIT 50")
    fun getRecent(): Flow<List<PromptHistoryEntity>>

    @Query("DELETE FROM prompt_history WHERE timestamp < :cutoff")
    suspend fun deleteOld(cutoff: Long)

    @Query("DELETE FROM prompt_history")
    suspend fun clearAll()
}

@Dao
interface SettingsDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(setting: SettingsEntity)

    @Query("SELECT * FROM settings WHERE key = :key")
    suspend fun get(key: String): SettingsEntity?

    @Query("SELECT * FROM settings")
    fun getAll(): Flow<List<SettingsEntity>>

    @Delete
    suspend fun delete(setting: SettingsEntity)

    @Query("DELETE FROM settings")
    suspend fun clearAll()
}
