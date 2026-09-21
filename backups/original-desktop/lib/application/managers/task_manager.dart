import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';
import '../../application/managers/agent_manager.dart';
import '../../core/utils/generate_id.dart';

class TaskManager {
  final TaskRepository _repository;
  final AgentManager _agentManager;
  final Map<TaskId, StreamController<TaskLog>> _logControllers = {};

  TaskManager(this._repository, this._agentManager);

  Future<Task> createTask({
    required ProjectId projectId,
    required AgentId agentId,
    required String prompt,
    required String permission,
    required String executionMode,
    int maxIterations = 10,
    Map<String, dynamic> metadata = const {},
  }) async {
    final task = Task(
      id: TaskId.generate(),
      projectId: projectId,
      agentId: agentId,
      prompt: prompt,
      permission: permission,
      executionMode: executionMode,
      state: TaskState.queued,
      maxIterations: maxIterations,
      createdAt: DateTime.now(),
      metadata: metadata,
      logs: [],
    );

    await _repository.saveTask(task);
    
    final controller = StreamController<TaskLog>.broadcast();
    _logControllers[task.id] = controller;
    
    return task;
  }

  Future<void> startTask(TaskId taskId) async {
    final task = await _repository.getTaskById(taskId);
    if (task == null) return;

    final updated = task.copyWith(
      state: TaskState.starting,
      startedAt: DateTime.now(),
    );
    await _repository.saveTask(updated);
    await _addLog(taskId, 'Task started', LogLevel.info);

    await _executeTask(updated);
  }

  Future<void> _executeTask(Task task) async {
    final updated = task.copyWith(state: TaskState.running);
    await _repository.saveTask(updated);
    await _addLog(task.id, 'Task running', LogLevel.info);

    try {
      final adapter = await _agentManager.createAdapter(
        (await _agentManager.getAgent(task.agentId))?.name.toLowerCase() ?? '',
      );

      if (adapter == null) {
        throw Exception('Agent adapter not found');
      }

      await adapter.initialize();
      await adapter.launch(
        workingDirectory: (await _getProjectRoot(task.projectId)) ?? '',
        environment: {},
      );

      await _agentManager.sendPrompt(task.agentId, task.prompt);

      final outputStream = await adapter.readOutput();
      await for (final line in outputStream) {
        await _addLog(task.id, line, LogLevel.info);
      }

      await adapter.stop();
      await adapter.dispose();

      final completed = task.copyWith(
        state: TaskState.completed,
        completedAt: DateTime.now(),
      );
      await _repository.saveTask(completed);
      await _addLog(task.id, 'Task completed successfully', LogLevel.info);

    } catch (e) {
      final failed = task.copyWith(
        state: TaskState.failed,
        completedAt: DateTime.now(),
        error: e.toString(),
      );
      await _repository.saveTask(failed);
      await _addLog(task.id, 'Task failed: $e', LogLevel.error);
    }
  }

  Future<String?> _getProjectRoot(ProjectId projectId) async {
    // Would need project repository
    return null;
  }

  Future<void> stopTask(TaskId taskId) async {
    final task = await _repository.getTaskById(taskId);
    if (task == null || !task.state.canStop) return;

    await _agentManager.stopAgent(task.agentId);
    
    final updated = task.copyWith(
      state: TaskState.stopped,
      completedAt: DateTime.now(),
    );
    await _repository.saveTask(updated);
    await _addLog(taskId, 'Task stopped by user', LogLevel.warning);
  }

  Future<void> retryTask(TaskId taskId) async {
    final task = await _repository.getTaskById(taskId);
    if (task == null || !task.state.canRetry) return;

    final updated = task.copyWith(
      state: TaskState.queued,
      iteration: task.iteration + 1,
      error: null,
      output: null,
      startedAt: null,
      completedAt: null,
    );
    await _repository.saveTask(updated);
    await startTask(taskId);
  }

  Future<void> _addLog(TaskId taskId, String message, LogLevel level) async {
    final log = TaskLog(
      id: generateId(),
      taskId: taskId,
      message: message,
      level: level,
      timestamp: DateTime.now(),
    );

    await _repository.addTaskLog(taskId, log);
    
    final controller = _logControllers[taskId];
    controller?.add(log);
  }

  Stream<TaskLog> getTaskLogStream(TaskId taskId) {
    if (!_logControllers.containsKey(taskId)) {
      _logControllers[taskId] = StreamController<TaskLog>.broadcast();
    }
    return _logControllers[taskId]!.stream;
  }

  Future<Task?> getTask(TaskId id) async {
    return await _repository.getTaskById(id);
  }

  Future<List<Task>> getTasksByProject(ProjectId projectId) async {
    return await _repository.getTasksByProject(projectId);
  }

  Future<List<Task>> getTasksByAgent(AgentId agentId) async {
    return await _repository.getTasksByAgent(agentId);
  }

  Future<List<Task>> getTasksByState(TaskState state) async {
    return await _repository.getTasksByState(state);
  }

  Future<List<Task>> getRecentTasks({int limit = 50}) async {
    return await _repository.getRecentTasks(limit: limit);
  }

  Future<int> getTaskCountByState(TaskState state) async {
    return await _repository.getTaskCountByState(state);
  }

  void dispose() {
    for (final controller in _logControllers.values) {
      controller.close();
    }
    _logControllers.clear();
  }
}

final taskManagerProvider = Provider<TaskManager>((ref) {
  throw UnimplementedError('TaskManager requires repository injection');
});
