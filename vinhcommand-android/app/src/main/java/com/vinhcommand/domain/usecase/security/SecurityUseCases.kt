package com.vinhcommand.domain.usecase.security

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.SecurityRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetSessionStateUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<SessionState>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<SessionState> {
        return securityRepository.getSessionState()
    }
}

class GetAuditLogsUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<SecurityAuditLog>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<SecurityAuditLog>> {
        return securityRepository.getAuditLogs()
    }
}

class GetPendingApprovalsUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<CommandApprovalRequest>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<CommandApprovalRequest>> {
        return securityRepository.getPendingApprovals()
    }
}

class ApproveCommandUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<CommandApprovalResponse, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: CommandApprovalResponse): Result<Unit> {
        return securityRepository.approveCommand(params)
    }
}

class GetDeviceTrustUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<DeviceInfo>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<DeviceInfo> {
        return securityRepository.getDeviceTrust()
    }
}

class SetDeviceTrustUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Boolean, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Boolean): Result<Unit> {
        return securityRepository.setDeviceTrust(params)
    }
}

class TriggerKillSwitchUseCase(
    private val securityRepository: SecurityRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<Unit> {
        return securityRepository.triggerKillSwitch()
    }
}

class ObserveSessionStateUseCase(
    private val securityRepository: SecurityRepository
) {
    operator fun invoke(): StateFlow<SessionState> {
        return securityRepository.sessionStateFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = SessionState("", "", "", "", "", "", PermissionProfile.DEVELOPER, SessionStatus.DISCONNECTED)
            ) 
    }
}

class ObserveApprovalsUseCase(
    private val securityRepository: SecurityRepository
) {
    operator fun invoke(): StateFlow<List<CommandApprovalRequest>> {
        return securityRepository.approvalsFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

