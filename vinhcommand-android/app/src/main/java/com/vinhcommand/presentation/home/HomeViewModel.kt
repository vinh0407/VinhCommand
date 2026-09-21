package com.vinhcommand.presentation.home

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.agent.GetAgentsUseCase
import com.vinhcommand.domain.usecase.agent.ObserveAgentsUseCase
import com.vinhcommand.domain.usecase.computer.ObserveComputersUseCase
import com.vinhcommand.domain.usecase.connection.ObservePcStateUseCase
import com.vinhcommand.domain.usecase.notification.ObserveNotificationsUseCase
import com.vinhcommand.domain.usecase.notification.ObserveUnreadCountUseCase
import com.vinhcommand.domain.usecase.project.GetProjectsUseCase
import com.vinhcommand.domain.usecase.project.ObserveProjectsUseCase
import com.vinhcommand.domain.usecase.task.GetTasksUseCase
import com.vinhcommand.domain.usecase.task.ObserveTasksUseCase
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val getProjectsUseCase: GetProjectsUseCase,
    private val getTasksUseCase: GetTasksUseCase,
    private val getAgentsUseCase: GetAgentsUseCase,
    private val observePcStateUseCase: ObservePcStateUseCase,
    private val observeProjectsUseCase: ObserveProjectsUseCase,
    private val observeTasksUseCase: ObserveTasksUseCase,
    private val observeAgentsUseCase: ObserveAgentsUseCase,
    private val observeNotificationsUseCase: ObserveNotificationsUseCase,
    private val observeUnreadCountUseCase: ObserveUnreadCountUseCase
) : BaseViewModel() {

    private val _searchQuery = MutableStateFlow("")
    val searchQuery = _searchQuery.asStateFlow()

    private val _commandPaletteOpen = MutableStateFlow(false)
    val commandPaletteOpen = _commandPaletteOpen.asStateFlow()

    private val _selectedComputer = MutableStateFlow<DesktopComputer?>(null)
    val selectedComputer = _selectedComputer.asStateFlow()

    val pcState = observePcStateUseCase()
    val projects = observeProjectsUseCase()
    val tasks = observeTasksUseCase()
    val agents = observeAgentsUseCase()
    val notifications = observeNotificationsUseCase()
    val unreadCount = observeUnreadCountUseCase()

    private val _hardwareStats = MutableStateFlow<HardwareStats?>(null)
    val hardwareStats = _hardwareStats.asStateFlow()

    init {
        // Combine PC state for hardware stats
        launch {
            pcState.collect { state ->
                state.computer?.stats?.let { _hardwareStats.value = it }
                state.computer?.let { _selectedComputer.value = it }
            }
        }
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun openCommandPalette() {
        _commandPaletteOpen.value = true
    }

    fun closeCommandPalette() {
        _commandPaletteOpen.value = false
        _searchQuery.value = ""
    }

    fun refreshData() {
        setState(UiState.Loading("Refreshing..."))
        launch {
            getProjectsUseCase(Unit)
            getTasksUseCase(Unit)
            getAgentsUseCase(Unit)
            setState(UiState.Idle)
        }
    }

    val runningTasksCount: Int
        get() = tasks.value.count { it.status == TaskStatus.RUNNING }

    val filteredProjects: List<Project>
        get() = if (_searchQuery.value.isBlank()) {
            projects.value
        } else {
            projects.value.filter { it.name.lowercase().contains(_searchQuery.value.lowercase()) }
        }

    val filteredAgents: List<AIAgent>
        get() = if (_searchQuery.value.isBlank()) {
            agents.value
        } else {
            agents.value.filter { it.name.lowercase().contains(_searchQuery.value.lowercase()) }
        }

    val filteredTasks: List<AgentTask>
        get() = if (_searchQuery.value.isBlank()) {
            tasks.value
        } else {
            tasks.value.filter { it.prompt.lowercase().contains(_searchQuery.value.lowercase()) }
        }

    val searchResults: List<SearchResult>
        get() = if (_searchQuery.value.trim().isNotBlank()) {
            val query = _searchQuery.value.lowercase()
            mutableListOf<SearchResult>().apply {
                addAll(filteredProjects.map { SearchResult(SearchType.PROJECT, it.name, { /* navigate */ }) })
                addAll(filteredAgents.map { SearchResult(SearchType.AGENT, it.name, { /* navigate */ }) })
                addAll(filteredTasks.map { SearchResult(SearchType.TASK, it.prompt, { /* navigate */ }) })
            }
        } else emptyList()

    fun onSearchResultClick(result: SearchResult) {
        result.action()
        closeCommandPalette()
    }
}

sealed class SearchType {
    object PROJECT : SearchType()
    object AGENT : SearchType()
    object TASK : SearchType()
    object FILE : SearchType()
    object LOG : SearchType()
}

data class SearchResult(
    val type: SearchType,
    val title: String,
    val action: () -> Unit
)

