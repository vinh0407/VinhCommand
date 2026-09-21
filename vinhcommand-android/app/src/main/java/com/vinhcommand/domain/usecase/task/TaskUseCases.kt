package com.vinhcommand.domain.usecase.task

import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.TaskRepository
import com.vinhcommand.domain.usecase.BaseUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.*

class GetTasksUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<Unit, Result<List<AgentTask>>>(coroutineScope) {

    override suspend operator fun invoke(params: Unit): Result<List<AgentTask>> {
        return taskRepository.getTasks()
    }
}

class GetTaskUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<AgentTask>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<AgentTask> {
        return taskRepository.getTask(params)
    }
}

class CreateTaskUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<CreateTaskRequest, Result<AgentTask>>(coroutineScope) {

    override suspend operator fun invoke(params: CreateTaskRequest): Result<AgentTask> {
        return taskRepository.createTask(params)
    }
}

class ControlTaskUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<TaskControlRequest, Result<Unit>>(coroutineScope) {

    override suspend operator fun invoke(params: TaskControlRequest): Result<Unit> {
        return taskRepository.controlTask(params)
    }
}

class GetTaskOutputUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<List<String>>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<List<String>> {
        return taskRepository.getTaskOutput(params)
    }
}

class GetTaskTimelineUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<List<TaskTimelineEvent>>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<List<TaskTimelineEvent>> {
        return taskRepository.getTaskTimeline(params)
    }
}

class GetTaskDiffUseCase(
    private val taskRepository: TaskRepository,
    coroutineScope: CoroutineScope
) : BaseUseCase<String, Result<GitDiff?>>(coroutineScope) {

    override suspend operator fun invoke(params: String): Result<GitDiff?> {
        return taskRepository.getTaskDiff(params)
    }
}

class ObserveTasksUseCase(
    private val taskRepository: TaskRepository
) {
    operator fun invoke(): StateFlow<List<AgentTask>> {
        return taskRepository.tasksFlow
            
            .stateIn(
                scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.Main),
                started = kotlinx.coroutines.flow.SharingStarted.WhileSubscribed(),
                initialValue = emptyList()
            )
    }
}

class ObserveTaskOutputUseCase(
    private val taskRepository: TaskRepository
) {
    operator fun invoke(): kotlinx.coroutines.flow.Flow<Pair<String, String>> {
        return taskRepository.taskOutputFlow
    }
}

