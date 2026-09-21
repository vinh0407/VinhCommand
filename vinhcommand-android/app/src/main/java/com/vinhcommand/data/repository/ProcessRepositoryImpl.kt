package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.ProcessMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ProcessRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProcessRepositoryImpl @Inject constructor(
    private val processDao: ProcessDao
) : ProcessRepository {

    override suspend fun getProcesses(): Result<List<ProcessItem>> {
        return try {
            val entities = processDao.getAll().first()
            Result.success(ProcessMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun killProcess(pid: Int): Result<Unit> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override val processesFlow: Flow<List<ProcessItem>>
        get() = processDao.getAll().map { ProcessMapper.toDomainList(it) }
}
