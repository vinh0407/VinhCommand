package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.SecurityMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.SecurityRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecurityRepositoryImpl @Inject constructor(
    private val auditLogDao: AuditLogDao,
    private val approvalDao: ApprovalDao,
    private val deviceInfoDao: DeviceInfoDao,
    private val sessionStateDao: SessionStateDao
) : SecurityRepository {

    private val sessionStateChannel = Channel<SessionState>()
    private val approvalsChannel = Channel<List<CommandApprovalRequest>>()

    override suspend fun getSessionState(): Result<SessionState> {
        return try {
            val entity = sessionStateDao.getCurrent()
            entity?.let { Result.success(toDomain(it)) } ?: Result.failure(Exception("Session state not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getAuditLogs(): Result<List<SecurityAuditLog>> {
        return try {
            val entities = auditLogDao.getRecent().first()
            Result.success(entities.map { SecurityMapper.toDomain(it) })
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getPendingApprovals(): Result<List<CommandApprovalRequest>> {
        return try {
            val entities = approvalDao.getAll().first()
            Result.success(entities.map { SecurityMapper.toDomainApproval(it) })
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun approveCommand(response: CommandApprovalResponse): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun getDeviceTrust(): Result<DeviceInfo> {
        return try {
            val entities = deviceInfoDao.getAll().first()
            entities.firstOrNull()?.let { Result.success(SecurityMapper.toDomainDevice(it)) } ?: Result.failure(Exception("Device info not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun setDeviceTrust(trust: Boolean): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun triggerKillSwitch(): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override val sessionStateFlow: Flow<SessionState>
        get() = sessionStateChannel.receiveAsFlow()

    override val approvalsFlow: Flow<List<CommandApprovalRequest>>
        get() = approvalsChannel.receiveAsFlow()

    fun onSessionStateChanged(state: SessionState) {
        sessionStateChannel.trySend(state)
    }

    fun onApprovalsChanged(approvals: List<CommandApprovalRequest>) {
        approvalsChannel.trySend(approvals)
    }

    private fun toDomain(entity: SessionStateEntity): SessionState {
        return SessionState(
            sessionId = entity.sessionId,
            deviceId = entity.deviceId,
            desktopId = entity.desktopId,
            createdAt = entity.createdAt,
            expiresAt = entity.expiresAt,
            lastActivity = entity.lastActivity,
            permissionProfile = when (entity.permissionProfile) {
                "Developer" -> PermissionProfile.DEVELOPER
                "Admin" -> PermissionProfile.ADMIN
                "Read Only" -> PermissionProfile.READ_ONLY
                else -> PermissionProfile.DEVELOPER
            },
            status = when (entity.status) {
                "CONNECTING" -> SessionStatus.CONNECTING
                "AUTHENTICATING" -> SessionStatus.AUTHENTICATING
                "CONNECTED" -> SessionStatus.CONNECTED
                "IDLE" -> SessionStatus.IDLE
                "EXPIRED" -> SessionStatus.EXPIRED
                "REVOKED" -> SessionStatus.REVOKED
                "DISCONNECTED" -> SessionStatus.DISCONNECTED
                "FAILED" -> SessionStatus.FAILED
                else -> SessionStatus.DISCONNECTED
            }
        )
    }
}
