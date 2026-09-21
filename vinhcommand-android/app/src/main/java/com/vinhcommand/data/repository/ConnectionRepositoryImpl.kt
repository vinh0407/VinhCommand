package com.vinhcommand.data.repository

import androidx.room.withTransaction
import com.vinhcommand.data.local.VinhCommandDatabase
import com.vinhcommand.data.mapper.*
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ConnectionRepository
import com.vinhcommand.network.CompanionSession
import com.vinhcommand.network.api.VinhCommandApi
import com.vinhcommand.network.model.ConnectRequest
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ConnectionRepositoryImpl @Inject constructor(
    private val api: VinhCommandApi,
    private val session: CompanionSession,
    private val database: VinhCommandDatabase
) : ConnectionRepository {
    private val connectionState = MutableStateFlow(ConnectionState.DISCONNECTED)
    private val pcState = MutableStateFlow(PcState())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var syncJob: Job? = null
    private val deviceId = UUID.randomUUID().toString()
    private var generation = 0
    override val connectionStateFlow: Flow<ConnectionState> = connectionState.asStateFlow()
    override val pcStateFlow: Flow<PcState> = pcState.asStateFlow()

    override suspend fun connect(config: ConnectionConfig): Result<AuthResponse> {
        syncJob?.cancelAndJoin()
        val current = ++generation
        connectionState.value = ConnectionState.CONNECTING
        return try {
            session.configure("${if(config.useHttps) "https" else "http"}://${config.host}:${config.port}/")
            val response = api.connect(ConnectRequest(config.desktopId.replace(" ", ""), config.accessCode, deviceId, "Android Device", appVersion = "1.0.0"))
            val data = response.body()?.data
            if (!response.isSuccessful || response.body()?.success != true || data?.success != true || data.sessionToken.isNullOrBlank()) {
                error(response.body()?.error?.message ?: "Pairing failed (${response.code()})")
            }
            if(current != generation) throw CancellationException("Connection replaced")
            session.token = data.sessionToken
            pcState.value = PcState(computer = data.computer)
            syncOnce()
            connectionState.value = ConnectionState.CONNECTED
            syncJob = scope.launch {
                while(isActive) {
                    delay(3000)
                    try { syncOnce(); connectionState.value = ConnectionState.CONNECTED }
                    catch(e: CancellationException) { throw e }
                    catch(e: SessionExpiredException) { session.token = null; connectionState.value = ConnectionState.SESSION_EXPIRED; break }
                    catch(_: Exception) { connectionState.value = ConnectionState.RECONNECTING }
                }
            }
            Result.success(AuthResponse(true, data.sessionToken, expiresIn = data.expiresIn, deviceTrusted = false))
        } catch(e: CancellationException) { throw e }
        catch(e: Exception) { session.token = null; connectionState.value = ConnectionState.FAILED; Result.failure(e) }
    }
    private suspend fun syncOnce() {
        val response = api.getPcState()
        if(response.code() == 401) throw SessionExpiredException()
        val snapshot = response.body()?.data
        check(response.isSuccessful && response.body()?.success == true && snapshot != null) { "Desktop sync failed" }
        database.withTransaction {
            database.projectDao().clearAll()
            database.projectDao().insertAll(snapshot.projects.map(ProjectMapper::toEntity))
            database.agentDao().clearAll()
            database.agentDao().insertAll(snapshot.agents.map(AgentMapper::toEntity))
            database.taskDao().clearAll()
            database.taskDao().insertAll(snapshot.tasks.map(TaskMapper::toEntity))
            snapshot.computer?.let { database.computerDao().insertAll(listOf(ComputerMapper.toEntity(it))) }
        }
        pcState.value = snapshot
    }
    override suspend fun disconnect(): Result<Unit> {
        ++generation
        syncJob?.cancelAndJoin()
        syncJob = null
        try { if(session.token != null) api.disconnect() } catch(e: CancellationException) { throw e } catch(_: Exception) { }
        session.token = null
        pcState.value = PcState()
        connectionState.value = ConnectionState.DISCONNECTED
        return Result.success(Unit)
    }
    override suspend fun pair(request: PairingRequest): Result<PairingChallenge> = Result.failure(UnsupportedOperationException("Use the code displayed in desktop Settings"))
    override suspend fun authenticate(request: AuthRequest): Result<AuthResponse> = connect(ConnectionConfig(request.desktopId, session.endpoint.host, session.endpoint.port, session.endpoint.isHttps, accessCode = request.accessCode))
    override suspend fun trustDevice(request: DeviceTrustRequest): Result<Unit> = Result.failure(UnsupportedOperationException("Persistent device trust is not enabled"))
    override suspend fun refreshSession(): Result<AuthResponse> = Result.failure(UnsupportedOperationException("Pair again when the one-hour session expires"))
    override suspend fun refreshPcState(): Result<PcState> = try {
        syncOnce()
        Result.success(pcState.value)
    } catch (e: Exception) {
        Result.failure(e)
    }
    private class SessionExpiredException : Exception()
}
