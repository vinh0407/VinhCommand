package com.vinhcommand.presentation.security

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.security.*
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SecurityViewModel @Inject constructor(
    private val getSessionStateUseCase: GetSessionStateUseCase,
    private val getAuditLogsUseCase: GetAuditLogsUseCase,
    private val getPendingApprovalsUseCase: GetPendingApprovalsUseCase,
    private val approveCommandUseCase: ApproveCommandUseCase,
    private val getDeviceTrustUseCase: GetDeviceTrustUseCase,
    private val setDeviceTrustUseCase: SetDeviceTrustUseCase,
    private val triggerKillSwitchUseCase: TriggerKillSwitchUseCase,
    private val observeSessionStateUseCase: ObserveSessionStateUseCase,
    private val observeApprovalsUseCase: ObserveApprovalsUseCase
) : BaseViewModel() {

    private val _sessionState = MutableStateFlow<SessionState?>(null)
    val sessionState = _sessionState.asStateFlow()

    private val _auditLogs = MutableStateFlow<List<SecurityAuditLog>>(emptyList())
    val auditLogs = _auditLogs.asStateFlow()

    val pendingApprovals = observeApprovalsUseCase()

    private val _deviceTrust = MutableStateFlow<DeviceInfo?>(null)
    val deviceTrust = _deviceTrust.asStateFlow()

    private val _remoteControlEnabled = MutableStateFlow(false)
    val remoteControlEnabled = _remoteControlEnabled.asStateFlow()

    init {
        loadData()
    }

    private fun loadData() {
        launch {
            getSessionStateUseCase(Unit).onSuccess { state ->
                _sessionState.value = state
            }
            getAuditLogsUseCase(Unit).onSuccess { logs ->
                _auditLogs.value = logs
            }
            getDeviceTrustUseCase(Unit).onSuccess { device ->
                _deviceTrust.value = device
            }
        }
    }

    fun approveCommand(approvalId: String, allow: Boolean) {
        launch {
            approveCommandUseCase(CommandApprovalResponse(approvalId, allow)).onSuccess {
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to approve command"))
            }
        }
    }

    fun setDeviceTrust(trust: Boolean) {
        launch {
            setDeviceTrustUseCase(trust).onSuccess {
                _deviceTrust.value = _deviceTrust.value?.copy(trusted = trust)
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to set device trust"))
            }
        }
    }

    fun triggerKillSwitch() {
        setState(UiState.Loading("Triggering kill switch..."))
        launch {
            triggerKillSwitchUseCase(Unit).onSuccess {
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to trigger kill switch"))
            }
        }
    }

    fun refresh() {
        loadData()
    }

    val isConnected: Boolean
        get() = _sessionState.value?.status == SessionStatus.CONNECTED

    val isDeviceTrusted: Boolean
        get() = _deviceTrust.value?.trusted == true
}

