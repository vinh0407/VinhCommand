package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.GitMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.GitRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GitRepositoryImpl @Inject constructor(
    private val gitStatusDao: GitStatusDao
) : GitRepository {

    override suspend fun getStatus(projectId: String): Result<GitStatusOverview> {
        return try {
            val entity = gitStatusDao.getByProject(projectId)
            entity?.let { Result.success(GitMapper.toDomain(it)) } ?: Result.failure(Exception("Git status not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getDiff(projectId: String, filePath: String): Result<GitDiff> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun stageFile(projectId: String, filePath: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun unstageFile(projectId: String, filePath: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun commit(projectId: String, message: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun getBranches(projectId: String): Result<List<String>> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun checkoutBranch(projectId: String, branch: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override val gitStatusFlow: Flow<GitStatusOverview>
        get() = gitStatusDao.getAll()
            .map { entities -> entities.firstOrNull()?.let { GitMapper.toDomain(it) } }
            .filterNotNull()
}
