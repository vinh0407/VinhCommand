package com.vinhcommand.presentation.files

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.file.*
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FilesViewModel @Inject constructor(
    private val listFilesUseCase: ListFilesUseCase,
    private val readFileUseCase: ReadFileUseCase,
    private val writeFileUseCase: WriteFileUseCase,
    private val createFileUseCase: CreateFileUseCase,
    private val deleteFileUseCase: DeleteFileUseCase,
    private val renameFileUseCase: RenameFileUseCase,
    private val observeFileTreeUseCase: ObserveFileTreeUseCase
) : BaseViewModel() {

    private val _currentPath = MutableStateFlow("/")
    val currentPath = _currentPath.asStateFlow()

    private val _fileTree = MutableStateFlow<List<FileNode>>(emptyList())
    val fileTree = _fileTree.asStateFlow()

    private val _selectedFile = MutableStateFlow<FileNode?>(null)
    val selectedFile = _selectedFile.asStateFlow()

    private val _fileContent = MutableStateFlow<String>("")
    val fileContent = _fileContent.asStateFlow()

    private val _isEditing = MutableStateFlow(false)
    val isEditing = _isEditing.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery = _searchQuery.asStateFlow()

    fun navigateTo(path: String) {
        _currentPath.value = path
        loadFiles(path)
    }

    fun loadFiles(path: String) {
        setState(UiState.Loading("Loading files..."))
        launch {
            listFilesUseCase(path).onSuccess { files ->
                _fileTree.value = files
                setState(UiState.Success(files))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to load files"))
            }
        }
    }

    fun selectFile(file: FileNode) {
        _selectedFile.value = file
        if (!file.isDirectory) {
            readFile(file.path)
        } else {
            navigateTo(file.path)
        }
    }

    private fun readFile(path: String) {
        launch {
            readFileUseCase(path).onSuccess { content ->
                _fileContent.value = content.content
                _isEditing.value = false
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to read file"))
            }
        }
    }

    fun saveFile() {
        val file = _selectedFile.value ?: return
        launch {
            writeFileUseCase(file.path to _fileContent.value).onSuccess { _ ->
                _isEditing.value = false
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to save file"))
            }
        }
    }

    fun createFile(name: String, content: String = "") {
        val path = "${_currentPath.value}/$name"
        launch {
            createFileUseCase(path to content).onSuccess { _ ->
                loadFiles(_currentPath.value)
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to create file"))
            }
        }
    }

    fun deleteFile(file: FileNode) {
        launch {
            deleteFileUseCase(file.path).onSuccess { _ ->
                loadFiles(_currentPath.value)
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to delete file"))
            }
        }
    }

    fun renameFile(file: FileNode, newName: String) {
        val newPath = "${file.path.substringBeforeLast("/")}/$newName"
        launch {
            renameFileUseCase(file.path to newPath).onSuccess { _ ->
                loadFiles(_currentPath.value)
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to rename file"))
            }
        }
    }

    fun startEditing() {
        _isEditing.value = true
    }

    fun cancelEditing() {
        val file = _selectedFile.value
        file?.let { readFile(it.path) }
        _isEditing.value = false
    }

    fun setFileContent(content: String) {
        _fileContent.value = content
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    val filteredFiles: List<FileNode>
        get() = if (_searchQuery.value.isBlank()) {
            _fileTree.value
        } else {
            _fileTree.value.filter { it.name.lowercase().contains(_searchQuery.value.lowercase()) }
        }
}

