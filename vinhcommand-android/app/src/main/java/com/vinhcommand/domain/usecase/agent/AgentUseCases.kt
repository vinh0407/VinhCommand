package com.vinhcommand.domain.usecase.agent

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.AgentRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetAgentsUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<AIAgent>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<AIAgent>> {
        return agentRepository.getAgents()
    }
}

class GetAgentUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<AIAgent>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<AIAgent> {
        return agentRepository.getAgent(params)
    }
}

class GetAgentDetailUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<AgentDetail>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<AgentDetail> {
        return agentRepository.getAgentDetail(params)
    }
}

class LaunchAgentUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String?>, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String?>): Result<Unit> {
        return agentRepository.launchAgent(params.first, params.second)
    }
}

class StopAgentUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<Unit> {
        return agentRepository.stopAgent(params)
    }
}

class SendAgentPromptUseCase(
    private val agentRepository: AgentRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Triple<String, String, String>, Result<String>>(coroutineScope) {

    override suspend operator fun invoke(params: Triple<String, String, String>): Result<String> {
        return agentRepository.sendPrompt(params.first, params.second, params.third)
    }
}

class ObserveAgentsUseCase(
    private val agentRepository: AgentRepository
) {
    operator fun invoke(): StateFlow<List<AIAgent>> {
        return agentRepository.agentsFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

