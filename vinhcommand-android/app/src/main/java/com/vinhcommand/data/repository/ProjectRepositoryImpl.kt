package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.ProjectMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ProjectRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProjectRepositoryImpl @Inject constructor(
    private val projectDao: ProjectDao
) : ProjectRepository {

    override suspend fun getProjects(): Result<List<Project>> {
        return try {
            val entities = projectDao.getAll().first()
            Result.success(ProjectMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getProject(id: String): Result<Project> {
        return try {
            val entity = projectDao.getById(id)
            entity?.let { Result.success(ProjectMapper.toDomain(it)) } ?: Result.failure(Exception("Project not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getProjectDetail(id: String): Result<ProjectDetail> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun refreshProjects(): Result<List<Project>> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun saveProject(project: Project): Result<Unit> {
        return try {
            projectDao.insertAll(listOf(ProjectMapper.toEntity(project)))
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val projectsFlow: Flow<List<Project>>

        get() = projectDao.getAll().map { ProjectMapper.toDomainList(it) }
}
