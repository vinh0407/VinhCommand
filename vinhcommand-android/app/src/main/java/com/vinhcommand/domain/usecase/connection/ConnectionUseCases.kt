package com.vinhcommand.domain.usecase.connection

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ConnectionRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.flow.asStateFlow

class ConnectToPcUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<ConnectionConfig, Result<AuthResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: ConnectionConfig): Result<AuthResponse> {
        return connectionRepository.connect(params)
    }
}

class DisconnectFromPcUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<Unit> {
        return connectionRepository.disconnect()
    }
}

class PairWithPcUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<PairingRequest, Result<PairingChallenge>>(coroutineScope) {

    override suspend operator fun invoke(params: PairingRequest): Result<PairingChallenge> {
        return connectionRepository.pair(params)
    }
}

class AuthenticateWithPcUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<AuthRequest, Result<AuthResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: AuthRequest): Result<AuthResponse> {
        return connectionRepository.authenticate(params)
    }
}

class TrustDeviceUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<DeviceTrustRequest, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: DeviceTrustRequest): Result<Unit> {
        return connectionRepository.trustDevice(params)
    }
}

class RefreshSessionUseCase(
    private val connectionRepository: ConnectionRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<AuthResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<AuthResponse> {
        return connectionRepository.refreshSession()
    }
}

class ObserveConnectionStateUseCase(
    private val connectionRepository: ConnectionRepository
) {
    operator fun invoke(): StateFlow<ConnectionState> {
        return connectionRepository.connectionStateFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = ConnectionState.DISCONNECTED
            ) 
    }
}

class ObservePcStateUseCase(
    private val connectionRepository: ConnectionRepository
) {
    operator fun invoke(): StateFlow<PcState> {
        return connectionRepository.pcStateFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = PcState(null)
            ) 
    }
}

