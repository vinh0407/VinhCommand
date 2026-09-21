package com.vinhcommand.domain.usecase.terminal

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.TerminalRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class CreateTerminalSessionUseCase(
    private val terminalRepository: TerminalRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<ShellType, String>, Result<TerminalSession>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<ShellType, String>): Result<TerminalSession> {
        return terminalRepository.createSession(params.first, params.second)
    }
}

class SendTerminalCommandUseCase(
    private val terminalRepository: TerminalRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<Unit> {
        return terminalRepository.sendCommand(params.first, params.second)
    }
}

class ResizeTerminalSessionUseCase(
    private val terminalRepository: TerminalRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Triple<String, Int, Int>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Triple<String, Int, Int>): Result<Unit> {
        return terminalRepository.resizeSession(params.first, params.second, params.third)
    }
}

class CloseTerminalSessionUseCase(
    private val terminalRepository: TerminalRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Unit> {
        return terminalRepository.closeSession(params)
    }
}

class ObserveTerminalSessionUseCase(
    private val terminalRepository: TerminalRepository
) {
    operator fun invoke(sessionId: String): StateFlow<TerminalSession> {
        return terminalRepository.sessionFlow
            .filter { it.id == sessionId }
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = TerminalSession("", ShellType.BASH, "", emptyList(), emptyList())
            ) 
    }
}

class ObserveTerminalOutputUseCase(
    private val terminalRepository: TerminalRepository
) {
    operator fun invoke(sessionId: String): kotlinx.coroutines.flow.Flow<TerminalOutput> {
        return terminalRepository.outputFlow
            .filter { it.sessionId == sessionId }
    }
}

