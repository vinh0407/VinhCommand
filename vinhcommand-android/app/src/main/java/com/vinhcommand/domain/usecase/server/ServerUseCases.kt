package com.vinhcommand.domain.usecase.server

import com.vinhcommand.domain.model.DevServer
import com.vinhcommand.domain.repository.ServerRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetServersUseCase(
    private val serverRepository: ServerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<DevServer>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<DevServer>> {
        return serverRepository.getServers()
    }
}

class StartServerUseCase(
    private val serverRepository: ServerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, Int>, Result<DevServer>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, Int>): Result<DevServer> {
        return serverRepository.startServer(params.first, params.second)
    }
}

class StopServerUseCase(
    private val serverRepository: ServerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Unit> {
        return serverRepository.stopServer(params)
    }
}

class ObserveServersUseCase(
    private val serverRepository: ServerRepository
) {
    operator fun invoke(): StateFlow<List<DevServer>> {
        return serverRepository.serversFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

