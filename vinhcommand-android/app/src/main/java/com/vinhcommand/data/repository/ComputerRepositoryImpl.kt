package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.ComputerMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.ComputerRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ComputerRepositoryImpl @Inject constructor(
    private val computerDao: ComputerDao,
    private val recentComputerDao: RecentComputerDao
) : ComputerRepository {

    override suspend fun getComputers(): Result<List<DesktopComputer>> {
        return try {
            val entities = computerDao.getAll().first()
            Result.success(ComputerMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getComputer(id: String): Result<DesktopComputer> {
        return try {
            val entity = computerDao.getById(id)
            entity?.let { Result.success(ComputerMapper.toDomain(it)) } ?: Result.failure(Exception("Computer not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun saveComputer(computer: DesktopComputer): Result<Unit> {
        return try {
            val entity = ComputerMapper.toEntity(computer)
            computerDao.insertAll(listOf(entity))
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

    override suspend fun deleteComputer(id: String): Result<Unit> {
        return try {
            computerDao.getById(id)?.let { computerDao.delete(it) }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val computersFlow: Flow<List<DesktopComputer>>
        get() = computerDao.getAll().map { ComputerMapper.toDomainList(it) }

    suspend fun saveRecentComputer(computer: DesktopComputer) {
        recentComputerDao.insert(RecentComputerEntity(
            desktopId = computer.desktopId,
            computerJson = kotlinx.serialization.json.Json.encodeToString(computer),
            lastUsed = System.currentTimeMillis()
        ))
    }
}
