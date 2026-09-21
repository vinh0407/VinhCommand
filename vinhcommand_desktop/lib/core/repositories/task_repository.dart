import '../entities/task.dart';
import '../value_objects/ids.dart';
import '../enums/task_state.dart';

abstract class TaskRepository {
  Future<List<Task>> getAllTasks();

  Future<Task?> getTaskById(TaskId id);

  Future<List<Task>> getTasksByProject(ProjectId projectId);

  Future<List<Task>> getTasksByAgent(AgentId agentId);

  Future<List<Task>> getTasksByState(TaskState state);

  Future<Task> saveTask(Task task);

  Future<void> deleteTask(TaskId id);

  Future<void> addTaskLog(TaskId taskId, TaskLog log);

  Future<List<TaskLog>> getTaskLogs(TaskId taskId);

  Future<int> getTaskCountByState(TaskState state);

  Future<List<Task>> getRecentTasks({int limit = 50});
}

abstract class TaskPipelineRepository {
  Future<List<TaskPipeline>> getAllPipelines();

  Future<TaskPipeline?> getPipelineById(String id);

  Future<TaskPipeline> savePipeline(TaskPipeline pipeline);

  Future<void> deletePipeline(String id);

  Future<void> updatePipelineStage(String pipelineId, int stageIndex, PipelineStage stage);
}