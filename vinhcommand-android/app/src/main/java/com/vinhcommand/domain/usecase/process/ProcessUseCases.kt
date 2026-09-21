package com.vinhcommand.domain.usecase.process

import com.vinhcommand.domain.model.ProcessItem
import com.vinhcommand.domain.repository.ProcessRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetProcessesUseCase(
    private val processRepository: ProcessRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<ProcessItem>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<ProcessItem>> {
        return processRepository.getProcesses()
    }
}

class KillProcessUseCase(
    private val processRepository: ProcessRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Int, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Int): Result<Unit> {
        return processRepository.killProcess(params)
    }
}

class ObserveProcessesUseCase(
    private val processRepository: ProcessRepository
) {
    operator fun invoke(): StateFlow<List<ProcessItem>> {
        return processRepository.processesFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

