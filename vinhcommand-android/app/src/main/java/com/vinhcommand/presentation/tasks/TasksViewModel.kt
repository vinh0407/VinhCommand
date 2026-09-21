package com.vinhcommand.presentation.tasks

import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel


import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.usecase.task.*
import com.vinhcommand.domain.usecase.project.GetProjectsUseCase
import com.vinhcommand.domain.usecase.agent.GetAgentsUseCase
import com.vinhcommand.presentation.common.BaseViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TasksViewModel @Inject constructor(
    private val getTasksUseCase: GetTasksUseCase,
    private val getTaskUseCase: GetTaskUseCase,
    private val getTaskOutputUseCase: GetTaskOutputUseCase,
    private val getTaskTimelineUseCase: GetTaskTimelineUseCase,
    private val getTaskDiffUseCase: GetTaskDiffUseCase,
    private val createTaskUseCase: CreateTaskUseCase,
    private val controlTaskUseCase: ControlTaskUseCase,
    private val observeTasksUseCase: ObserveTasksUseCase,
    private val observeTaskOutputUseCase: ObserveTaskOutputUseCase,
    private val getProjectsUseCase: GetProjectsUseCase,
    private val getAgentsUseCase: GetAgentsUseCase
) : BaseViewModel() {

    private val _selectedTaskId = MutableStateFlow<String?>(null)
    val selectedTaskId = _selectedTaskId.asStateFlow()

    private val _selectedTask = MutableStateFlow<AgentTask?>(null)
    val selectedTask = _selectedTask.asStateFlow()

    private val _taskOutput = MutableStateFlow<List<String>>(emptyList())
    val taskOutput = _taskOutput.asStateFlow()

    private val _taskTimeline = MutableStateFlow<List<TaskTimelineEvent>>(emptyList())
    val taskTimeline = _taskTimeline.asStateFlow()

    private val _taskDiff = MutableStateFlow<GitDiff?>(null)
    val taskDiff = _taskDiff.asStateFlow()

    private val _newTaskPrompt = MutableStateFlow("")
    val newTaskPrompt = _newTaskPrompt.asStateFlow()

    private val _selectedProjectId = MutableStateFlow<String?>(null)
    val selectedProjectId = _selectedProjectId.asStateFlow()

    private val _selectedAgentId = MutableStateFlow<String?>(null)
    val selectedAgentId = _selectedAgentId.asStateFlow()

    private val _isAutonomous = MutableStateFlow(true)
    val isAutonomous = _isAutonomous.asStateFlow()

    private val _maxIterations = MutableStateFlow(10)
    val maxIterations = _maxIterations.asStateFlow()

    private val _stopOnTestsPass = MutableStateFlow(true)
    val stopOnTestsPass = _stopOnTestsPass.asStateFlow()

    private val _stopOnBuildPass = MutableStateFlow(true)
    val stopOnBuildPass = _stopOnBuildPass.asStateFlow()

    val tasks = observeTasksUseCase()
    val streamingOutput = observeTaskOutputUseCase()

    private val _availableProjects = MutableStateFlow<List<Project>>(emptyList())
    val availableProjects = _availableProjects.asStateFlow()

    private val _availableAgents = MutableStateFlow<List<AIAgent>>(emptyList())
    val availableAgents = _availableAgents.asStateFlow()

    init {
        loadAvailableData()
    }

    private fun loadAvailableData() {
        launch {
            getProjectsUseCase(Unit).onSuccess { projects ->
                _availableProjects.value = projects
            }
            getAgentsUseCase(Unit).onSuccess { agents ->
                _availableAgents.value = agents
            }
        }
    }

    fun selectTask(task: AgentTask) {
        _selectedTaskId.value = task.id
        _selectedTask.value = task
        loadTaskDetails(task.id)
    }

    private fun loadTaskDetails(taskId: String) {
        launch {
            getTaskUseCase(taskId).onSuccess { task ->
                _selectedTask.value = task
            }
            getTaskOutputUseCase(taskId).onSuccess { output ->
                _taskOutput.value = output
            }
            getTaskTimelineUseCase(taskId).onSuccess { timeline ->
                _taskTimeline.value = timeline
            }
            getTaskDiffUseCase(taskId).onSuccess { diff ->
                _taskDiff.value = diff
            }
        }
    }

    fun createTask() {
        val prompt = _newTaskPrompt.value
        val projectId = _selectedProjectId.value
        val agentId = _selectedAgentId.value
        
        if (prompt.isBlank() || projectId == null || agentId == null) {
            setState(UiState.Error("Please fill all fields"))
            return
        }

        setState(UiState.Loading("Creating task..."))
        launch {
            val request = CreateTaskRequest(
                name = "Task ${System.currentTimeMillis()}",
                agent = agentId,
                project = projectId,
                prompt = prompt,
                isAutonomous = _isAutonomous.value,
                maxIterations = _maxIterations.value,
                stopOnTestsPass = _stopOnTestsPass.value,
                stopOnBuildPass = _stopOnBuildPass.value
            )
            
            createTaskUseCase(request).onSuccess { task ->
                _newTaskPrompt.value = ""
                _selectedTaskId.value = task.id
                selectTask(task)
                setState(UiState.Success(task))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to create task"))
            }
        }
    }

    fun controlTask(action: TaskAction) {
        val taskId = _selectedTaskId.value ?: return
        launch {
            controlTaskUseCase(TaskControlRequest(taskId, action)).onSuccess {
                loadTaskDetails(taskId)
                setState(UiState.Success(Unit))
            }.onFailure { e ->
                setState(UiState.Error(e.message ?: "Failed to control task"))
            }
        }
    }

    fun setNewTaskPrompt(prompt: String) {
        _newTaskPrompt.value = prompt
    }

    fun setSelectedProject(projectId: String) {
        _selectedProjectId.value = projectId
    }

    fun setSelectedAgent(agentId: String) {
        _selectedAgentId.value = agentId
    }

    fun setAutonomous(autonomous: Boolean) {
        _isAutonomous.value = autonomous
    }

    fun setMaxIterations(iterations: Int) {
        _maxIterations.value = iterations
    }

    fun setStopOnTestsPass(stop: Boolean) {
        _stopOnTestsPass.value = stop
    }

    fun setStopOnBuildPass(stop: Boolean) {
        _stopOnBuildPass.value = stop
    }

    fun clearSelection() {
        _selectedTaskId.value = null
        _selectedTask.value = null
        _taskOutput.value = emptyList()
        _taskTimeline.value = emptyList()
        _taskDiff.value = null
    }
}

