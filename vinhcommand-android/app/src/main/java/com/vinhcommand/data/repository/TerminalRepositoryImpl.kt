package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.TerminalMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.TerminalRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TerminalRepositoryImpl @Inject constructor(
    private val terminalDao: TerminalSessionDao
) : TerminalRepository {

    private val sessionChannel = Channel<TerminalSession>()
    private val outputChannel = Channel<TerminalOutput>()

    override suspend fun createSession(shell: ShellType, cwd: String): Result<TerminalSession> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun sendCommand(sessionId: String, command: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun resizeSession(sessionId: String, cols: Int, rows: Int): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun closeSession(sessionId: String): Result<Unit> {
        return try {
            terminalDao.getById(sessionId)?.let { terminalDao.delete(it) }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val sessionFlow: Flow<TerminalSession>
        get() = terminalDao.getAll()
            .map { entities -> entities.firstOrNull()?.let { TerminalMapper.toDomain(it) } }
            .filterNotNull()

    override val outputFlow: Flow<TerminalOutput>
        get() = outputChannel.receiveAsFlow()

    fun onSessionCreated(session: TerminalSession) {
        sessionChannel.trySend(session)
    }

    fun onOutput(output: TerminalOutput) {
        outputChannel.trySend(output)
    }
}
