package com.vinhcommand.presentation.agents

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.agent.*
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AgentsViewModel @Inject constructor(
    private val getAgentsUseCase: GetAgentsUseCase,
    private val getAgentDetailUseCase: GetAgentDetailUseCase,
    private val launchAgentUseCase: LaunchAgentUseCase,
    private val stopAgentUseCase: StopAgentUseCase,
    private val sendAgentPromptUseCase: SendAgentPromptUseCase,
    private val observeAgentsUseCase: ObserveAgentsUseCase
) : BaseViewModel() {

    private val _selectedAgentId = MutableStateFlow<String?>(null)
    val selectedAgentId = _selectedAgentId.asStateFlow()

    private val _agentDetail = MutableStateFlow<AgentDetail?>(null)
    val agentDetail = _agentDetail.asStateFlow()

    private val _prompt = MutableStateFlow("")
    val prompt = _prompt.asStateFlow()

    val agents = observeAgentsUseCase()

    fun selectAgent(agent: AIAgent) {
        _selectedAgentId.value = agent.id
        loadAgentDetail(agent.id)
    }

    private fun loadAgentDetail(agentId: String) {
        launch {
            getAgentDetailUseCase(agentId).onSuccess { detail ->
                _agentDetail.value = detail
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to load agent detail"))
            }
        }
    }

    fun launchAgent(projectId: String?) {
        val agentId = _selectedAgentId.value ?: return
        launch {
            launchAgentUseCase(agentId to projectId).onSuccess {
                setState(UiState.Success(Unit))
                loadAgentDetail(agentId)
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to launch agent"))
            }
        }
    }

    fun stopAgent() {
        val agentId = _selectedAgentId.value ?: return
        launch {
            stopAgentUseCase(agentId).onSuccess {
                setState(UiState.Success(Unit))
                loadAgentDetail(agentId)
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to stop agent"))
            }
        }
    }

    fun sendPrompt(projectId: String) {
        val agentId = _selectedAgentId.value ?: return
        val promptText = _prompt.value
        if (promptText.isBlank()) return

        launch {
            sendAgentPromptUseCase(Triple(agentId, promptText, projectId)).onSuccess { taskId ->
                _prompt.value = ""
                setState(UiState.Success(taskId))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to send prompt"))
            }
        }
    }

    fun setPrompt(text: String) {
        _prompt.value = text
    }

    fun clearSelection() {
        _selectedAgentId.value = null
        _agentDetail.value = null
    }
}

