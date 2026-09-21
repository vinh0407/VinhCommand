import '../workflow/project_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';
import '../../infrastructure/database/database_service.dart';
import '../vinhcommand_application.dart';

final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService.memory());
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return DatabaseAgentRepository(ref.read(databaseProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return DatabaseProjectRepository(ref.read(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return DatabaseTaskRepository(ref.read(databaseProvider));
});

final terminalRepositoryProvider = Provider<TerminalRepository>((ref) {
  return DatabaseTerminalRepository(ref.read(databaseProvider));
});

final fileSystemRepositoryProvider = Provider<FileSystemRepository>((ref) {
  return FileSystemService();
});

final gitRepositoryProvider = Provider<GitRepository>((ref) {
  return GitService();
});

final processRepositoryProvider = Provider<ProcessRepository>((ref) {
  return ProcessMonitorService();
});

final screenRepositoryProvider = Provider<ScreenRepository>((ref) {
  return ScreenCaptureService();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return DatabaseSessionRepository(ref.read(databaseProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DatabaseDeviceRepository(ref.read(databaseProvider));
});

final accessCodeRepositoryProvider = Provider<AccessCodeRepository>((ref) {
  return DatabaseAccessCodeRepository(ref.read(databaseProvider));
});

final workspacePermissionRepositoryProvider = Provider<WorkspacePermissionRepository>((ref) {
  return DatabaseWorkspacePermissionRepository(ref.read(databaseProvider));
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return DatabaseAuditRepository(ref.read(databaseProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return DatabaseNotificationRepository(ref.read(databaseProvider));
});

final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  return WindowsSystemRepository();
});

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  throw UnsupportedError('This module is not enabled in the MVP');
});

final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  throw UnsupportedError('This module is not enabled in the MVP');
});

final agentAdapterRepositoryProvider = Provider<AgentAdapterRepository>((ref) {
  return DatabaseAgentAdapterRepository(ref.read(databaseProvider));
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return DatabaseWorkspaceRepository(ref.read(databaseProvider));
});

final shellRepositoryProvider = Provider<ShellRepository>((ref) {
  return WindowsShellRepository();
});

// ============================================================================
// Infrastructure Services
// ============================================================================

final systemRepositoryImplProvider = Provider<SystemRepository>((ref) {
  return WindowsSystemRepository();
});

final agentDiscoveryServiceProvider = Provider<AgentDiscoveryService>((ref) {
  return AgentDiscoveryService(
    ref.read(agentRepositoryProvider),
    ref.read(agentAdapterRepositoryProvider),
  );
});

final projectDiscoveryServiceProvider = Provider<ProjectDiscoveryService>((ref) {
  return ProjectDiscoveryService(
    ref.read(projectRepositoryProvider),
    ref.read(workspaceRepositoryProvider),
  );
});

final terminalServiceProvider = Provider<TerminalService>((ref) {
  final service = TerminalService(
    ref.read(terminalRepositoryProvider),
    ref.read(shellRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final fileSystemServiceProvider = Provider<FileSystemService>((ref) {
  return FileSystemService();
});

final gitServiceProvider = Provider<GitService>((ref) {
  return GitService();
});

final processMonitorServiceProvider = Provider<ProcessMonitorService>((ref) {
  return ProcessMonitorService();
});

final screenCaptureServiceProvider = Provider<ScreenCaptureService>((ref) {
  return ScreenCaptureService();
});

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(
    ref.read(sessionRepositoryProvider),
    ref.read(deviceRepositoryProvider),
    ref.read(accessCodeRepositoryProvider),
    ref.read(workspacePermissionRepositoryProvider),
    ref.read(auditRepositoryProvider),
  );
});

// ============================================================================
// Managers
// ============================================================================

final agentManagerProvider = Provider<AgentManager>((ref) {
  return AgentManager(
    ref.read(agentRepositoryProvider),
    ref.read(agentAdapterRepositoryProvider),
  );
});

final projectManagerProvider = Provider<ProjectManager>((ref) {
  return ProjectManager(
    ref.read(projectRepositoryProvider),
    ref.read(workspaceRepositoryProvider),
  );
});

final projectAccessProvider = Provider<ProjectAccess>((ref) => ProjectAccess(ref.read(databaseProvider)));

final taskManagerProvider = Provider<TaskManager>((ref) {
  final manager = TaskManager(
    ref.read(taskRepositoryProvider),
    ref.read(agentManagerProvider),
    ref.read(projectRepositoryProvider),
    access: ref.read(projectAccessProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final securityManagerProvider = Provider<SecurityManager>((ref) {
  return SecurityManager(
    ref.read(sessionRepositoryProvider),
    ref.read(deviceRepositoryProvider),
    ref.read(accessCodeRepositoryProvider),
    ref.read(workspacePermissionRepositoryProvider),
    ref.read(auditRepositoryProvider),
  );
});

final terminalManagerProvider = Provider<TerminalManager>((ref) {
  return TerminalManager(
    ref.read(terminalRepositoryProvider),
    ref.read(shellRepositoryProvider),
  );
});

// ============================================================================
// State Providers
// ============================================================================

final systemInfoProvider = FutureProvider<SystemInfo>((ref) async {
  return await ref.read(systemRepositoryImplProvider).getSystemInfo();
});

final agentsProvider = FutureProvider<List<Agent>>((ref) async {
  final list = await ref.read(agentRepositoryProvider).getAllAgents();
  if (list.isNotEmpty) return list;
  return [
    Agent(
      id: const AgentId('codex'),
      name: 'Codex CLI Pro',
      version: '0.147.0',
      executable: r'C:\Users\ADMIN\AppData\Roaming\npm\codex.cmd',
      path: r'C:\Users\ADMIN\AppData\Roaming\npm',
      status: AgentStatus.available,
      running: false,
      authenticated: true,
      capabilities: const [AgentCapability.prompt, AgentCapability.streaming, AgentCapability.input, AgentCapability.stop, AgentCapability.projectContext, AgentCapability.fileEditing],
      metadata: const {},
      discoveredAt: DateTime.now(),
    ),
    Agent(
      id: const AgentId('antigravity'),
      name: 'Antigravity Desktop Pro',
      version: '1.107.0',
      executable: r'C:\Users\ADMIN\.gemini\antigravity\bin\agentapi.bat',
      path: r'C:\Users\ADMIN\.gemini\antigravity\bin',
      status: AgentStatus.available,
      running: false,
      authenticated: true,
      capabilities: const [AgentCapability.prompt, AgentCapability.streaming, AgentCapability.input, AgentCapability.stop, AgentCapability.projectContext, AgentCapability.fileEditing],
      metadata: const {},
      discoveredAt: DateTime.now(),
    ),
    Agent(
      id: const AgentId('gemini'),
      name: 'Gemini CLI Pro',
      version: '0.56.0',
      executable: r'C:\Users\ADMIN\AppData\Roaming\npm\gemini.cmd',
      path: r'C:\Users\ADMIN\AppData\Roaming\npm',
      status: AgentStatus.available,
      running: false,
      authenticated: true,
      capabilities: const [AgentCapability.prompt, AgentCapability.streaming, AgentCapability.input, AgentCapability.stop, AgentCapability.projectContext, AgentCapability.fileEditing],
      metadata: const {},
      discoveredAt: DateTime.now(),
    ),
    Agent(
      id: const AgentId('chatgpt-web'),
      name: 'ChatGPT Web Automation',
      version: '1.0',
      executable: r'C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine\codex-web-gpt.cmd',
      path: r'C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine',
      status: AgentStatus.available,
      running: false,
      authenticated: true,
      capabilities: const [AgentCapability.prompt, AgentCapability.streaming, AgentCapability.input, AgentCapability.stop, AgentCapability.projectContext],
      metadata: const {},
      discoveredAt: DateTime.now(),
    ),
    Agent(
      id: const AgentId('agent_cli'),
      name: 'Terminal System CLI',
      version: '1.0',
      executable: 'cmd.exe',
      path: r'C:\Windows\System32',
      status: AgentStatus.available,
      running: false,
      authenticated: true,
      capabilities: const [AgentCapability.prompt, AgentCapability.streaming, AgentCapability.input, AgentCapability.stop, AgentCapability.projectContext, AgentCapability.fileEditing],
      metadata: const {},
      discoveredAt: DateTime.now(),
    ),
  ];
});

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  return await ref.read(projectRepositoryProvider).getAllProjects();
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
  return await ref.read(taskRepositoryProvider).getAllTasks();
});

final processesProvider = FutureProvider<List<ProcessInfo>>((ref) async {
  return await ref.read(processMonitorServiceProvider).getDevelopmentProcesses();
});

final serversProvider = FutureProvider<List<DevelopmentServer>>((ref) async {
  return <DevelopmentServer>[];
});

final notificationsProvider = FutureProvider<List<Notification>>((ref) async {
  return await ref.read(notificationRepositoryProvider).getNotifications(limit: 50);
});


