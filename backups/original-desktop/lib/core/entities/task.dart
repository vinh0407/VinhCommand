import 'package:equatable/equatable.dart';
import '../enums/task_state.dart';
import '../value_objects/ids.dart';

class Task extends Equatable {
  final TaskId id;
  final ProjectId projectId;
  final AgentId agentId;
  final String prompt;
  final String permission;
  final String executionMode;
  final TaskState state;
  final int iteration;
  final int maxIterations;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? output;
  final String? error;
  final Map<String, dynamic> metadata;
  final List<TaskLog> logs;

  const Task({
    required this.id,
    required this.projectId,
    required this.agentId,
    required this.prompt,
    required this.permission,
    required this.executionMode,
    required this.state,
    this.iteration = 0,
    this.maxIterations = 10,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.output,
    this.error,
    required this.metadata,
    required this.logs,
  });

  @override
  List<Object?> get props => [
        id,
        projectId,
        agentId,
        prompt,
        permission,
        executionMode,
        state,
        iteration,
        maxIterations,
        createdAt,
        startedAt,
        completedAt,
        output,
        error,
        metadata,
        logs,
      ];

  Task copyWith({
    TaskId? id,
    ProjectId? projectId,
    AgentId? agentId,
    String? prompt,
    String? permission,
    String? executionMode,
    TaskState? state,
    int? iteration,
    int? maxIterations,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? output,
    String? error,
    Map<String, dynamic>? metadata,
    List<TaskLog>? logs,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      agentId: agentId ?? this.agentId,
      prompt: prompt ?? this.prompt,
      permission: permission ?? this.permission,
      executionMode: executionMode ?? this.executionMode,
      state: state ?? this.state,
      iteration: iteration ?? this.iteration,
      maxIterations: maxIterations ?? this.maxIterations,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      output: output ?? this.output,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      logs: logs ?? this.logs,
    );
  }

  bool get isTerminal => state.isTerminal;

  bool get isActive => state.isActive;

  bool get canStop => state.canStop;

  bool get canRetry => state.canRetry;

  Duration? get duration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }
}

class TaskLog extends Equatable {
  final String id;
  final TaskId taskId;
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const TaskLog({
    required this.id,
    required this.taskId,
    required this.message,
    required this.level,
    required this.timestamp,
    this.metadata,
  });

  @override
  List<Object?> get props => [id, taskId, message, level, timestamp, metadata];
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class TaskPipeline extends Equatable {
  final String id;
  final String name;
  final List<PipelineStage> stages;
  final PipelineStatus status;
  final int currentStageIndex;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const TaskPipeline({
    required this.id,
    required this.name,
    required this.stages,
    required this.status,
    this.currentStageIndex = 0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        stages,
        status,
        currentStageIndex,
        createdAt,
        startedAt,
        completedAt,
      ];
}

class PipelineStage extends Equatable {
  final String id;
  final String name;
  final AgentId agentId;
  final String prompt;
  final StageStatus status;
  final TaskId? taskId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? output;
  final String? error;

  const PipelineStage({
    required this.id,
    required this.name,
    required this.agentId,
    required this.prompt,
    required this.status,
    this.taskId,
    this.startedAt,
    this.completedAt,
    this.output,
    this.error,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        agentId,
        prompt,
        status,
        taskId,
        startedAt,
        completedAt,
        output,
        error,
      ];
}

enum PipelineStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum StageStatus {
  pending,
  running,
  completed,
  failed,
  skipped,
}