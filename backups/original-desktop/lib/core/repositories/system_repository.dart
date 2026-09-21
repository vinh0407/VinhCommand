import 'package:equatable/equatable.dart';
import '../entities/system.dart';
import '../value_objects/ids.dart';
import '../value_objects/system_info.dart';
import '../enums/task_state.dart';
import '../enums/security_enums.dart';

abstract class ProcessRepository {
  Future<List<ProcessInfo>> getAllProcesses();

  Future<ProcessInfo?> getProcessByPid(int pid);

  Future<List<ProcessInfo>> getProcessesByName(String name);

  Future<List<ProcessInfo>> getDevelopmentProcesses();

  Future<void> killProcess(int pid, {bool force = false});

  Future<int> startProcess({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
  });

  Future<ProcessOutput> runCommand({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
    Duration? timeout,
  });
}

class ProcessOutput extends Equatable {
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;

  const ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  @override
  List<Object?> get props => [exitCode, stdout, stderr, duration];

  bool get success => exitCode == 0;
}

abstract class ServerRepository {
  Future<List<DevelopmentServer>> discoverServers();

  Future<DevelopmentServer?> getServerByPort(int port);

  Future<DevelopmentServer?> getServerByPid(int pid);

  Future<void> refreshServer(DevelopmentServer server);

  Future<void> stopServer(int port);

  Future<bool> isPortInUse(int port);

  Future<int?> getPidByPort(int port);
}

abstract class ScreenRepository {
  Future<List<ScreenSourceInfo>> getAvailableSources();

  Future<ScreenCapture> captureScreen(ScreenConfig config);

  Future<Stream<ScreenCapture>> startScreenStream(ScreenConfig config);

  Future<void> stopScreenStream(String streamId);

  Future<bool> hasPermission();
}

class ScreenSourceInfo extends Equatable {
  final String id;
  final String name;
  final ScreenSource type;
  final int width;
  final int height;
  final bool isPrimary;

  const ScreenSourceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.width,
    required this.height,
    required this.isPrimary,
  });

  @override
  List<Object?> get props => [id, name, type, width, height, isPrimary];
}

abstract class NotificationRepository {
  Future<List<Notification>> getNotifications({bool unreadOnly = false, int limit = 50});

  Future<int> getUnreadCount();

  Future<Notification> createNotification(Notification notification);

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String id);

  Future<void> clearAll();
}

abstract class SystemRepository {
  Future<SystemInfo> getSystemInfo();

  Future<CpuInfo> getCpuInfo();

  Future<MemoryInfo> getMemoryInfo();

  Future<List<DiskInfo>> getDiskInfo();

  Future<List<GpuInfo>> getGpuInfo();

  Future<List<NetworkInterface>> getNetworkInterfaces();

  Future<DateTime> getBootTime();
}

class CpuInfo extends Equatable {
  final String name;
  final int cores;
  final int threads;
  final double frequencyGhz;
  final double usagePercent;
  final List<double> perCoreUsage;

  const CpuInfo({
    required this.name,
    required this.cores,
    required this.threads,
    required this.frequencyGhz,
    required this.usagePercent,
    required this.perCoreUsage,
  });

  @override
  List<Object?> get props => [name, cores, threads, frequencyGhz, usagePercent, perCoreUsage];
}

class MemoryInfo extends Equatable {
  final int totalBytes;
  final int availableBytes;
  final int usedBytes;
  final double usagePercent;

  const MemoryInfo({
    required this.totalBytes,
    required this.availableBytes,
    required this.usedBytes,
    required this.usagePercent,
  });

  @override
  List<Object?> get props => [totalBytes, availableBytes, usedBytes, usagePercent];

  int get totalGb => (totalBytes / (1024 * 1024 * 1024)).round();
  int get availableGb => (availableBytes / (1024 * 1024 * 1024)).round();
  int get usedGb => (usedBytes / (1024 * 1024 * 1024)).round();
}

abstract class AutomationRepository {
  Future<List<AutomationWorkflow>> getAllWorkflows();

  Future<AutomationWorkflow?> getWorkflowById(String id);

  Future<AutomationWorkflow> saveWorkflow(AutomationWorkflow workflow);

  Future<void> deleteWorkflow(String id);

  Future<AutomationExecution> executeWorkflow(String workflowId, Map<String, dynamic> params);

  Future<List<AutomationExecution>> getExecutions(String workflowId, {int limit = 50});
}

class AutomationWorkflow extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<AutomationStep> steps;
  final bool enabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AutomationWorkflow({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.enabled,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, description, steps, enabled, createdAt, updatedAt];
}

class AutomationStep extends Equatable {
  final String id;
  final String name;
  final AutomationStepType type;
  final Map<String, dynamic> config;
  final List<String> nextStepIds;
  final Map<String, String>? conditions;

  const AutomationStep({
    required this.id,
    required this.name,
    required this.type,
    required this.config,
    required this.nextStepIds,
    this.conditions,
  });

  @override
  List<Object?> get props => [id, name, type, config, nextStepIds, conditions];
}

enum AutomationStepType {
  runCommand,
  runTask,
  runAgent,
  runTests,
  buildProject,
  checkCondition,
  sendNotification,
  wait,
  custom,
}

class AutomationExecution extends Equatable {
  final String id;
  final String workflowId;
  final AutomationExecutionStatus status;
  final int currentStepIndex;
  final Map<String, dynamic> variables;
  final List<AutomationStepResult> stepResults;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? error;

  const AutomationExecution({
    required this.id,
    required this.workflowId,
    required this.status,
    this.currentStepIndex = 0,
    required this.variables,
    required this.stepResults,
    required this.startedAt,
    this.completedAt,
    this.error,
  });

  @override
  List<Object?> get props => [
        id,
        workflowId,
        status,
        currentStepIndex,
        variables,
        stepResults,
        startedAt,
        completedAt,
        error,
      ];
}

enum AutomationExecutionStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

class AutomationStepResult extends Equatable {
  final String stepId;
  final AutomationExecutionStatus status;
  final Map<String, dynamic> output;
  final String? error;
  final DateTime startedAt;
  final DateTime? completedAt;

  const AutomationStepResult({
    required this.stepId,
    required this.status,
    required this.output,
    this.error,
    required this.startedAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [stepId, status, output, error, startedAt, completedAt];
}

abstract class DiagnosticsRepository {
  Future<DiagnosticsReport> runFullDiagnostics();

  Future<DiagnosticsCheck> runCheck(String checkId);

  Future<List<DiagnosticsCheck>> getAllChecks();

  Future<DiagnosticsCheck> getCheckById(String checkId);
}

class DiagnosticsReport extends Equatable {
  final DateTime timestamp;
  final List<DiagnosticsCheck> checks;
  final int passed;
  final int warnings;
  final int failed;

  const DiagnosticsReport({
    required this.timestamp,
    required this.checks,
    required this.passed,
    required this.warnings,
    required this.failed,
  });

  @override
  List<Object?> get props => [timestamp, checks, passed, warnings, failed];

  DiagnosticsStatus get overallStatus {
    if (failed > 0) return DiagnosticsStatus.fail;
    if (warnings > 0) return DiagnosticsStatus.warning;
    return DiagnosticsStatus.pass;
  }
}

enum DiagnosticsStatus {
  pass,
  warning,
  fail,
}

class DiagnosticsCheck extends Equatable {
  final String id;
  final String name;
  final String category;
  final DiagnosticsStatus status;
  final String message;
  final String? details;
  final String? suggestedFix;
  final Duration duration;

  const DiagnosticsCheck({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.message,
    this.details,
    this.suggestedFix,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, name, category, status, message, details, suggestedFix, duration];
}