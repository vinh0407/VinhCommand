package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.*
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.CacheRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CacheRepositoryImpl @Inject constructor(
    private val recentComputerDao: RecentComputerDao,
    private val projectDao: ProjectDao,
    private val taskDao: TaskDao,
    private val promptTemplateDao: PromptTemplateDao,
    private val promptHistoryDao: PromptHistoryDao
) : CacheRepository {

    override suspend fun saveRecentComputer(computer: DesktopComputer): Result<Unit> {
        return try {
            recentComputerDao.insert(RecentComputerEntity(
                desktopId = computer.desktopId,
                computerJson = kotlinx.serialization.json.Json.encodeToString(computer),
                lastUsed = System.currentTimeMillis()
            ))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getRecentComputers(): Result<List<DesktopComputer>> {
        return try {
            val entities = recentComputerDao.getRecent().first()
            val computers = entities.mapNotNull { entity ->
                try {
                    kotlinx.serialization.json.Json { ignoreUnknownKeys = true }
                        .decodeFromString<DesktopComputer>(entity.computerJson)
                } catch (e: Exception) {
                    null
                }
            }
            Result.success(computers)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun saveProjectMetadata(project: Project): Result<Unit> {
        return try {
            projectDao.insertAll(listOf(ProjectMapper.toEntity(project)))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getCachedProjects(): Result<List<Project>> {
        return try {
            val entities = projectDao.getAll().first()
            Result.success(ProjectMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun saveTaskHistory(task: AgentTask): Result<Unit> {
        return try {
            taskDao.insertAll(listOf(TaskMapper.toEntity(task)))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getCachedTasks(): Result<List<AgentTask>> {
        return try {
            val entities = taskDao.getAll().first()
            Result.success(TaskMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun clearCache(): Result<Unit> {
        return try {
            recentComputerDao.clearAll()
            projectDao.clearAll()
            taskDao.clearAll()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

