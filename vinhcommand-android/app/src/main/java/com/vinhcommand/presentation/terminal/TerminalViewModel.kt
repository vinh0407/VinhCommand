package com.vinhcommand.presentation.terminal

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.terminal.*
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TerminalViewModel @Inject constructor(
    private val createTerminalSessionUseCase: CreateTerminalSessionUseCase,
    private val sendTerminalCommandUseCase: SendTerminalCommandUseCase,
    private val resizeTerminalSessionUseCase: ResizeTerminalSessionUseCase,
    private val closeTerminalSessionUseCase: CloseTerminalSessionUseCase,
    private val observeTerminalSessionUseCase: ObserveTerminalSessionUseCase,
    private val observeTerminalOutputUseCase: ObserveTerminalOutputUseCase
) : BaseViewModel() {

    private val _activeSessionId = MutableStateFlow<String?>(null)
    val activeSessionId = _activeSessionId.asStateFlow()

    private val _session = MutableStateFlow<TerminalSession?>(null)
    val session = _session.asStateFlow()

    private val _commandHistory = MutableStateFlow<List<String>>(emptyList())
    val commandHistory = _commandHistory.asStateFlow()

    private val _outputBuffer = MutableStateFlow<List<TerminalOutput>>(emptyList())
    val outputBuffer = _outputBuffer.asStateFlow()

    private val _pendingCommand = MutableStateFlow("")
    val pendingCommand = _pendingCommand.asStateFlow()

    private val _cols = MutableStateFlow(80)
    val cols = _cols.asStateFlow()

    private val _rows = MutableStateFlow(24)
    val rows = _rows.asStateFlow()

    fun createSession(shell: ShellType = ShellType.POWERSHELL, cwd: String = "~") {
        setState(UiState.Loading("Creating terminal..."))
        launch {
            createTerminalSessionUseCase(shell to cwd).onSuccess { session ->
                _activeSessionId.value = session.id
                _session.value = session
                _commandHistory.value = session.history
                observeSession(session.id)
                observeOutput(session.id)
                setState(UiState.Success(session))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to create terminal"))
            }
        }
    }

    private fun observeSession(sessionId: String) {
        launch {
            observeTerminalSessionUseCase(sessionId).collect { session ->
                _session.value = session
            }
        }
    }

    private fun observeOutput(sessionId: String) {
        launch {
            observeTerminalOutputUseCase(sessionId).collect { output ->
                _outputBuffer.update { it + output }
            }
        }
    }

    fun sendCommand(command: String) {
        val sessionId = _activeSessionId.value ?: return
        if (command.isBlank()) return

        _commandHistory.update { it + command }
        _pendingCommand.value = command
        
        launch {
            sendTerminalCommandUseCase(sessionId to command).onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to send command"))
            }
        }
    }

    fun resize(cols: Int, rows: Int) {
        val sessionId = _activeSessionId.value ?: return
        _cols.value = cols
        _rows.value = rows
        launch {
            resizeTerminalSessionUseCase(Triple(sessionId, cols, rows)).onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to resize"))
            }
        }
    }

    fun closeSession() {
        val sessionId = _activeSessionId.value ?: return
        launch {
            closeTerminalSessionUseCase(sessionId).onSuccess {
                _activeSessionId.value = null
                _session.value = null
                _outputBuffer.value = emptyList()
            }
        }
    }

    fun setPendingCommand(command: String) {
        _pendingCommand.value = command
    }

    fun clearOutput() {
        _outputBuffer.value = emptyList()
    }
}

