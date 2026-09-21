package com.vinhcommand.data.repository

import com.vinhcommand.data.local.*
import com.vinhcommand.data.mapper.TaskMapper
import com.vinhcommand.domain.model.*
import com.vinhcommand.domain.repository.TaskRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import javax.inject.Inject
import javax.inject.Singleton
import com.vinhcommand.network.api.VinhCommandApi
import com.vinhcommand.network.model.CreateTaskRequestDto
import kotlinx.coroutines.CancellationException

@Singleton
class TaskRepositoryImpl @Inject constructor(
    private val taskDao: TaskDao,
    private val api: VinhCommandApi
) : TaskRepository {

    private val outputChannel = Channel<Pair<String, String>>()

    override suspend fun getTasks(): Result<List<AgentTask>> {
        return try {
            val entities = taskDao.getAll().first()
            Result.success(TaskMapper.toDomainList(entities))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getTask(id: String): Result<AgentTask> {
        return try {
            val entity = taskDao.getById(id)
            entity?.let { Result.success(TaskMapper.toDomain(it)) } ?: Result.failure(Exception("Task not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createTask(request: CreateTaskRequest): Result<AgentTask> {
        return try {
            val response = api.createTask(CreateTaskRequestDto(request.name, request.agent, request.project, request.prompt, false, 1, false, false, request.permission, request.parentTaskId))
            val task = response.body()?.data?.task
            check(response.isSuccessful && response.body()?.success == true && task != null) {
                response.body()?.error?.message ?: "Unable to queue task (${response.code()})"
            }
            taskDao.insertAll(listOf(TaskMapper.toEntity(task)))
            Result.success(task)
        } catch(e: CancellationException) { throw e }
        catch(e: Exception) { Result.failure(e) }
    }

    override suspend fun controlTask(request: TaskControlRequest): Result<Unit> {
        return try {
            val operation = when(request.action) { TaskAction.APPROVE, TaskAction.DENY -> "approval"; TaskAction.ACCEPT -> "result"; else -> "control" }
            val body = mutableMapOf("taskId" to request.taskId, "action" to request.action.name.lowercase())
            request.approvalId?.let { body["approvalId"] = it }
            val response = api.workflowAction(operation, body)
            check(response.isSuccessful && response.body()?.success == true) { response.errorBody()?.string() ?: "Task action failed" }
            Result.success(Unit)
        } catch(e: CancellationException) { throw e } catch(e: Exception) { Result.failure(e) }
    }

    override suspend fun getTaskOutput(taskId: String): Result<List<String>> {
        return try {
            val entity = taskDao.getById(taskId)
            entity?.let { Result.success(TaskMapper.toDomain(it).logs) } ?: Result.failure(Exception("Task not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getTaskTimeline(taskId: String): Result<List<TaskTimelineEvent>> {
        return try {
            val entity = taskDao.getById(taskId)
            entity?.let { Result.success(TaskMapper.toDomain(it).timeline) } ?: Result.failure(Exception("Task not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun getTaskDiff(taskId: String): Result<GitDiff?> {
        return try {
            val entity = taskDao.getById(taskId)
            entity?.let { Result.success(TaskMapper.toDomain(it).gitDiff) } ?: Result.failure(Exception("Task not found"))
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override val tasksFlow: Flow<List<AgentTask>>
        get() = taskDao.getAll().map { TaskMapper.toDomainList(it) }

    override val taskOutputFlow: Flow<Pair<String, String>>
        get() = outputChannel.receiveAsFlow()

    fun onTaskOutput(taskId: String, line: String) {
        outputChannel.trySend(taskId to line)
    }
}
