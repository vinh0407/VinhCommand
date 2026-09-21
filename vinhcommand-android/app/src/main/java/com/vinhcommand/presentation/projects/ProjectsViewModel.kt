package com.vinhcommand.presentation.projects

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.project.*
import com.vinhcommand.domain.usecase.git.GetGitStatusUseCase
import com.vinhcommand.domain.usecase.git.ObserveGitStatusUseCase
import com.vinhcommand.domain.usecase.file.ListFilesUseCase
import com.vinhcommand.domain.usecase.file.ObserveFileTreeUseCase
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ProjectsViewModel @Inject constructor(
    private val getProjectsUseCase: GetProjectsUseCase,
    private val getProjectDetailUseCase: GetProjectDetailUseCase,
    private val refreshProjectsUseCase: RefreshProjectsUseCase,
    private val observeProjectsUseCase: ObserveProjectsUseCase,
    private val getGitStatusUseCase: GetGitStatusUseCase,
    private val observeGitStatusUseCase: ObserveGitStatusUseCase,
    private val listFilesUseCase: ListFilesUseCase,
    private val observeFileTreeUseCase: ObserveFileTreeUseCase
) : BaseViewModel() {

    private val _selectedProjectId = MutableStateFlow<String?>(null)
    val selectedProjectId = _selectedProjectId.asStateFlow()

    private val _projectDetail = MutableStateFlow<ProjectDetail?>(null)
    val projectDetail = _projectDetail.asStateFlow()

    private val _gitStatus = MutableStateFlow<GitStatusOverview?>(null)
    val gitStatus = _gitStatus.asStateFlow()

    private val _fileTree = MutableStateFlow<List<FileNode>>(emptyList())
    val fileTree = _fileTree.asStateFlow()

    val projects = observeProjectsUseCase()

    fun selectProject(project: Project) {
        _selectedProjectId.value = project.id
        loadProjectDetail(project.id)
    }

    private fun loadProjectDetail(projectId: String) {
        setState(UiState.Loading("Loading project..."))
        launch {
            getProjectDetailUseCase(projectId).onSuccess { detail ->
                _projectDetail.value = detail
                loadGitStatus(projectId)
                loadFileTree(projectId)
                setState(UiState.Success(detail))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to load project"))
            }
        }
    }

    private fun loadGitStatus(projectId: String) {
        launch {
            getGitStatusUseCase(projectId).onSuccess { status ->
                _gitStatus.value = status
            }
        }
    }

    private fun loadFileTree(projectId: String) {
        val project = projects.value.find { it.id == projectId }
        project?.let {
            launch {
                listFilesUseCase(it.path).onSuccess { files ->
                    _fileTree.value = files
                }
            }
        }
    }

    fun refresh() {
        launch {
            refreshProjectsUseCase(Unit).onSuccess { _ ->
                setState(UiState.Success(Unit))
            }
        }
    }

    fun clearSelection() {
        _selectedProjectId.value = null
        _projectDetail.value = null
        _gitStatus.value = null
        _fileTree.value = emptyList()
    }
}

