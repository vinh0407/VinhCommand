package com.vinhcommand.domain.usecase.file

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.FileRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class ListFilesUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<List<FileNode>>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<List<FileNode>> {
        return fileRepository.listFiles(params)
    }
}

class ReadFileUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<FileContent>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<FileContent> {
        return fileRepository.readFile(params)
    }
}

class WriteFileUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<FileOperationResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<FileOperationResponse> {
        return fileRepository.writeFile(params.first, params.second)
    }
}

class CreateFileUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<FileOperationResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<FileOperationResponse> {
        return fileRepository.createFile(params.first, params.second)
    }
}

class DeleteFileUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<FileOperationResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<FileOperationResponse> {
        return fileRepository.deleteFile(params)
    }
}

class RenameFileUseCase(
    private val fileRepository: FileRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Pair<String, String>, Result<FileOperationResponse>>(coroutineScope) {

    override suspend operator fun invoke(params: Pair<String, String>): Result<FileOperationResponse> {
        return fileRepository.renameFile(params.first, params.second)
    }
}

class ObserveFileTreeUseCase(
    private val fileRepository: FileRepository
) {
    operator fun invoke(): StateFlow<List<FileNode>> {
        return fileRepository.fileTreeFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

