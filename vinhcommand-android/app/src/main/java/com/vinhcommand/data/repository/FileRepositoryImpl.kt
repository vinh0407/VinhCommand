package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.FileMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.FileRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FileRepositoryImpl @Inject constructor(
    private val fileNodeDao: FileNodeDao
) : FileRepository {

    override suspend fun listFiles(path: String): Result<List<FileNode>> {
        return try {
            val entity = fileNodeDao.getByPath(path)
            val domain = entity?.let { FileMapper.toDomain(it) }
            Result.success(domain?.children ?: emptyList())
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun readFile(path: String): Result<FileContent> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun writeFile(path: String, content: String): Result<FileOperationResponse> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun createFile(path: String, content: String): Result<FileOperationResponse> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun deleteFile(path: String): Result<FileOperationResponse> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override suspend fun renameFile(oldPath: String, newPath: String): Result<FileOperationResponse> {
        return Result.failure(Exception("Must be implemented with network"))
    }

    override val fileTreeFlow: Flow<List<FileNode>>
        get() = fileNodeDao.getAll().map { FileMapper.toDomainList(it) }
}
