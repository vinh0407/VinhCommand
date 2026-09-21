package com.vinhcommand.domain.usecase.computer

import com.vinhcommand.domain.model.DesktopComputer
import com.vinhcommand.domain.repository.ComputerRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetComputersUseCase(
    private val computerRepository: ComputerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<DesktopComputer>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<DesktopComputer>> {
        return computerRepository.getComputers()
    }
}

class GetComputerUseCase(
    private val computerRepository: ComputerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<DesktopComputer>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<DesktopComputer> {
        return computerRepository.getComputer(params)
    }
}

class SaveComputerUseCase(
    private val computerRepository: ComputerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<DesktopComputer, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: DesktopComputer): Result<Unit> {
        return computerRepository.saveComputer(params)
    }
}

class DeleteComputerUseCase(
    private val computerRepository: ComputerRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Unit> {
        return computerRepository.deleteComputer(params)
    }
}

class ObserveComputersUseCase(
    private val computerRepository: ComputerRepository
) {
    operator fun invoke(): StateFlow<List<DesktopComputer>> {
        return computerRepository.computersFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

