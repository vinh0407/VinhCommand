package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.AgentMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.AgentRepository
import com.vinhcommand.network.api.VinhCommandApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AgentRepositoryImpl @Inject constructor(
    private val agentDao: AgentDao,
    private val api: VinhCommandApi
) : AgentRepository {

    override suspend fun getAgents(): Result<List<AIAgent>> {
        return try {
            val response = api.getAgents()
            val list = response.body()?.data?.agents
            if (response.isSuccessful && list != null) {
                Result.success(list)
            } else {
                val entities = agentDao.getAll().first()
                Result.success(AgentMapper.toDomainList(entities))
            }
        } catch (e: Exception) {
            try {
                val entities = agentDao.getAll().first()
                Result.success(AgentMapper.toDomainList(entities))
            } catch (ex: Exception) {
                Result.failure(e)
            }
        }
    }

    override suspend fun getAgent(id: String): Result<AIAgent> {
        return try {
            val agentsRes = getAgents()
            val found = agentsRes.getOrNull()?.firstOrNull { it.id == id }
            found?.let { Result.success(it) } ?: run {
                val entity = agentDao.getById(id)
                entity?.let { Result.success(AgentMapper.toDomain(it)) } ?: Result.failure(Exception("Agent not found"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getAgentDetail(id: String): Result<AgentDetail> {
        return try {
            val agentRes = getAgent(id)
            val agent = agentRes.getOrNull() ?: return Result.failure(Exception("Agent not found"))
            Result.success(AgentDetail(agent, emptyList(), listOf("Agent status: ${agent.status}", "Version: ${agent.version}")))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun launchAgent(agentId: String, projectId: String?): Result<Unit> {
        return try {
            api.launchAgent(agentId, projectId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun stopAgent(agentId: String): Result<Unit> {
        return try {
            api.stopAgent(agentId)
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun sendPrompt(agentId: String, prompt: String, projectId: String): Result<String> {
        return try {
            val res = api.sendPrompt(agentId, mapOf("prompt" to prompt, "projectId" to projectId))
            Result.success(res.body()?.data?.get("taskId") ?: "task_queued")
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val agentsFlow: Flow<List<AIAgent>>
        get() = agentDao.getAll().map { AgentMapper.toDomainList(it) }
}
