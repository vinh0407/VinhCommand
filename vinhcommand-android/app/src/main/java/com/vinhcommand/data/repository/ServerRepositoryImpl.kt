package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.ServerMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ServerRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ServerRepositoryImpl @Inject constructor(
    private val serverDao: ServerDao
) : ServerRepository {

    override suspend fun getServers(): Result<List<DevServer>> {
        return try {
            val entities = serverDao.getAll().first()
            Result.success(ServerMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun startServer(projectId: String, port: Int): Result<DevServer> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun stopServer(serverId: String): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override val serversFlow: Flow<List<DevServer>>
        get() = serverDao.getAll().map { ServerMapper.toDomainList(it) }
}
