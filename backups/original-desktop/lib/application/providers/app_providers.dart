import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';
import '../../application/vinhcommand_application.dart';

// ============================================================================
// Simple In-Memory Database
// ============================================================================

class InMemoryDatabase {
  final Map<String, Map<String, dynamic>> _tables = {};
  int _autoId = 0;

  String _nextId() => '${DateTime.now().millisecondsSinceEpoch}_${_autoId++}';

  Future<void> insert(String table, Map<String, dynamic> data) async {
    _tables[table] ??= {};
    final id = data['id'] ?? _nextId();
    data['id'] = id;
    _tables[table]![id] = data;
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy, int? limit}) async {
    _tables[table] ??= {};
    var results = _tables[table]!.values.toList();
    
    if (where != null && whereArgs != null) {
      // Simple where clause support for "id = ?"
      if (where == 'id = ?' && whereArgs.length == 1) {
        results = results.where((r) => r['id'] == whereArgs[0]).toList();
      }
    }
    
    if (orderBy != null && orderBy.contains('DESC')) {
      results.sort((a, b) => (b[orderBy.replaceAll(' DESC', '').replaceAll('timestamp', 'created_at')] ?? '').compareTo(a[orderBy.replaceAll(' DESC', '').replaceAll('timestamp', 'created_at')] ?? ''));
    }
    
    if (limit != null && results.length > limit) {
      results = results.take(limit).toList();
    }
    
    return results;
  }

  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    _tables[table] ??= {};
    int count = 0;
    if (where == 'id = ?' && whereArgs != null && whereArgs.length == 1) {
      final id = whereArgs[0];
      if (_tables[table]!.containsKey(id)) {
        _tables[table]![id]!.addAll(data);
        count = 1;
      }
    }
    return count;
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    _tables[table] ??= {};
    int count = 0;
    if (where == 'id = ?' && whereArgs != null && whereArgs.length == 1) {
      if (_tables[table]!.remove(whereArgs[0]) != null) {
        count = 1;
      }
    }
    return count;
  }

  Future<int> execute(String sql) async => 0;
}

// ============================================================================
// Database Provider
// ============================================================================

final databaseProvider = Provider<InMemoryDatabase>((ref) {
  return InMemoryDatabase();
});

// ============================================================================
// Simple Repository Implementations
// ============================================================================

class InMemoryAgentRepository implements AgentRepository {
  final InMemoryDatabase _db;
  InMemoryAgentRepository(this._db);

  @override
  Future<Agent> saveAgent(Agent agent) async {
    await _db.insert('agents', agent.toMap());
    return agent;
  }

  @override
  Future<Agent?> getAgent(AgentId id) async {
    final maps = await _db.query('agents', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Agent.fromMap(maps.first);
  }

  @override
  Future<List<Agent>> getAllAgents() async {
    final maps = await _db.query('agents');
    return maps.map(Agent.fromMap).toList();
  }

  @override
  Future<void> deleteAgent(AgentId id) async {
    await _db.delete('agents', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> updateAgentStatus(AgentId id, AgentStatus status) async {
    await _db.update('agents', {'status': status.name}, where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> updateAgentLastChecked(AgentId id, DateTime time) async {
    await _db.update('agents', {'last_checked_at': time.toIso8601String()}, where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<List<Agent>> getAgentsByStatus(AgentStatus status) async {
    final maps = await _db.query('agents');
    return maps.where((m) => m['status'] == status.name).map(Agent.fromMap).toList();
  }
}

class InMemoryProjectRepository implements ProjectRepository {
  final InMemoryDatabase _db;
  InMemoryProjectRepository(this._db);

  @override
  Future<Project> saveProject(Project project) async {
    await _db.insert('projects', project.toMap());
    return project;
  }

  @override
  Future<Project?> getProject(ProjectId id) async {
    final maps = await _db.query('projects', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  @override
  Future<List<Project>> getAllProjects() async {
    final maps = await _db.query('projects');
    return maps.map(Project.fromMap).toList();
  }

  @override
  Future<void> deleteProject(ProjectId id) async {
    await _db.delete('projects', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<List<Project>> getProjectsByFramework(ProjectFramework framework) async {
    final maps = await _db.query('projects');
    return maps.where((m) => m['framework'] == framework.name).map(Project.fromMap).toList();
  }
}

class InMemoryTaskRepository implements TaskRepository {
  final InMemoryDatabase _db;
  InMemoryTaskRepository(this._db);

  @override
  Future<Task> saveTask(Task task) async {
    await _db.insert('tasks', task.toMap());
    return task;
  }

  @override
  Future<Task?> getTask(TaskId id) async {
    final maps = await _db.query('tasks', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final maps = await _db.query('tasks');
    return maps.map(Task.fromMap).toList();
  }

  @override
  Future<void> deleteTask(TaskId id) async {
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<List<Task>> getTasksByProject(ProjectId projectId) async {
    final maps = await _db.query('tasks');
    return maps.where((m) => m['project_id'] == projectId.value).map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksByAgent(AgentId agentId) async {
    final maps = await _db.query('tasks');
    return maps.where((m) => m['agent_id'] == agentId.value).map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksByState(TaskState state) async {
    final maps = await _db.query('tasks');
    return maps.where((m) => m['state'] == state.name).map(Task.fromMap).toList();
  }
}

class InMemoryTerminalRepository implements TerminalRepository {
  final InMemoryDatabase _db;
  InMemoryTerminalRepository(this._db);

  @override
  Future<Terminal> saveTerminal(Terminal terminal) async {
    await _db.insert('terminals', terminal.toMap());
    return terminal;
  }

  @override
  Future<Terminal?> getTerminal(TerminalId id) async {
    final maps = await _db.query('terminals', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Terminal.fromMap(maps.first);
  }

  @override
  Future<List<Terminal>> getAllTerminals() async {
    final maps = await _db.query('terminals');
    return maps.map(Terminal.fromMap).toList();
  }

  @override
  Future<void> deleteTerminal(TerminalId id) async {
    await _db.delete('terminals', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> saveTerminalOutput(TerminalOutput output) async {
    await _db.insert('terminal_outputs', output.toMap());
  }

  @override
  Future<List<TerminalOutput>> getTerminalOutputs(TerminalId terminalId, {int limit = 1000}) async {
    final maps = await _db.query('terminal_outputs', where: 'terminal_id = ?', whereArgs: [terminalId.value], orderBy: 'timestamp DESC', limit: limit);
    return maps.map(TerminalOutput.fromMap).toList();
  }

  @override
  Future<void> clearTerminalOutputs(TerminalId terminalId) async {
    await _db.delete('terminal_outputs', where: 'terminal_id = ?', whereArgs: [terminalId.value]);
  }
}

class InMemoryFileSystemRepository implements FileSystemRepository {
  final InMemoryDatabase _db;
  InMemoryFileSystemRepository(this._db);

  @override
  Future<void> saveFileChange(FileChange change) async {
    await _db.insert('file_changes', change.toMap());
  }

  @override
  Future<List<FileChange>> getFileChanges(String path, {DateTime? since}) async {
    return [];
  }

  @override
  Future<void> clearFileChanges(String path) async {}
}

class InMemorySecurityRepository implements SecurityRepository {
  final InMemoryDatabase _db;
  InMemorySecurityRepository(this._db);

  @override
  Future<void> saveSession(Session session) async {
    await _db.insert('sessions', session.toMap());
  }

  @override
  Future<Session?> getSession(SessionId id) async {
    final maps = await _db.query('sessions', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  @override
  Future<List<Session>> getAllSessions() async {
    final maps = await _db.query('sessions');
    return maps.map(Session.fromMap).toList();
  }

  @override
  Future<void> deleteSession(SessionId id) async {
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> saveDevice(Device device) async {
    await _db.insert('devices', device.toMap());
  }

  @override
  Future<Device?> getDevice(DeviceId id) async {
    final maps = await _db.query('devices', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  @override
  Future<List<Device>> getAllDevices() async {
    final maps = await _db.query('devices');
    return maps.map(Device.fromMap).toList();
  }

  @override
  Future<void> deleteDevice(DeviceId id) async {
    await _db.delete('devices', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> saveAccessCode(AccessCode code) async {
    await _db.insert('access_codes', code.toMap());
  }

  @override
  Future<AccessCode?> getAccessCode(AccessCodeId id) async {
    final maps = await _db.query('access_codes', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return AccessCode.fromMap(maps.first);
  }

  @override
  Future<List<AccessCode>> getAllAccessCodes() async {
    final maps = await _db.query('access_codes');
    return maps.map(AccessCode.fromMap).toList();
  }

  @override
  Future<void> deleteAccessCode(AccessCodeId id) async {
    await _db.delete('access_codes', where: 'id = ?', whereArgs: [id.value]);
  }

  @override
  Future<void> saveWorkspacePermission(WorkspacePermission permission) async {
    await _db.insert('workspace_permissions', permission.toMap());
  }

  @override
  Future<WorkspacePermission?> getWorkspacePermission(String path) async {
    final maps = await _db.query('workspace_permissions', where: 'path = ?', whereArgs: [path]);
    if (maps.isEmpty) return null;
    return WorkspacePermission.fromMap(maps.first);
  }

  @override
  Future<List<WorkspacePermission>> getAllWorkspacePermissions() async {
    final maps = await _db.query('workspace_permissions');
    return maps.map(WorkspacePermission.fromMap).toList();
  }

  @override
  Future<void> deleteWorkspacePermission(String path) async {
    await _db.delete('workspace_permissions', where: 'path = ?', whereArgs: [path]);
  }

  @override
  Future<void> saveAuditEvent(AuditEvent event) async {
    await _db.insert('audit_events', event.toMap());
  }

  @override
  Future<List<AuditEvent>> getAuditEvents({DateTime? since, int limit = 100}) async {
    final maps = await _db.query('audit_events', orderBy: 'timestamp DESC', limit: limit);
    return maps.map(AuditEvent.fromMap).toList();
  }
}

class InMemorySystemRepository implements SystemRepository {
  final InMemoryDatabase _db;
  InMemorySystemRepository(this._db);

  @override
  Future<SystemInfo> getSystemInfo() async {
    throw UnimplementedError('Use WindowsSystemRepository');
  }

  @override
  Future<List<ProcessInfo>> getAllProcesses() async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<ProcessInfo?> getProcessByPid(int pid) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<List<ProcessInfo>> getProcessesByName(String name) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<List<ProcessInfo>> getDevelopmentProcesses() async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<void> killProcess(int pid, {bool force = false}) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<int> startProcess({required String executable, required List<String> arguments, required String workingDirectory, Map<String, String>? environment}) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<ProcessOutput> runCommand({required String executable, required List<String> arguments, required String workingDirectory, Map<String, String>? environment, Duration? timeout}) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<List<DevelopmentServer>> discoverServers() async => [];

  @override
  Future<DevelopmentServer?> getServerByPort(int port) async => null;

  @override
  Future<DevelopmentServer?> getServerByPid(int pid) async => null;

  @override
  Future<void> refreshServer(DevelopmentServer server) async {}

  @override
  Future<void> stopServer(int port) async {}

  @override
  Future<bool> isPortInUse(int port) async => false;

  @override
  Future<int?> getPidByPort(int port) async => null;
}

class InMemoryNotificationRepository implements NotificationRepository {
  final InMemoryDatabase _db;
  InMemoryNotificationRepository(this._db);

  @override
  Future<void> saveNotification(Notification notification) async {
    await _db.insert('notifications', notification.toMap());
  }

  @override
  Future<Notification?> getNotification(String id) async {
    final maps = await _db.query('notifications', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Notification.fromMap(maps.first);
  }

  @override
  Future<List<Notification>> getNotifications({int limit = 50, bool? unreadOnly}) async {
    final maps = await _db.query('notifications', orderBy: 'created_at DESC', limit: limit);
    return maps.map(Notification.fromMap).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _db.update('notifications', {'read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _db.delete('notifications', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAllNotifications() async {
    await _db.delete('notifications');
  }
}

class InMemoryWorkspaceRepository implements WorkspaceRepository {
  final InMemoryDatabase _db;
  InMemoryWorkspaceRepository(this._db);

  @override
  Future<Workspace> saveWorkspace(Workspace workspace) async {
    await _db.insert('workspaces', workspace.toMap());
    return workspace;
  }

  @override
  Future<Workspace?> getWorkspace(String id) async {
    final maps = await _db.query('workspaces', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Workspace.fromMap(maps.first);
  }

  @override
  Future<List<Workspace>> getAllWorkspaces() async {
    final maps = await _db.query('workspaces');
    return maps.map(Workspace.fromMap).toList();
  }

  @override
  Future<void> deleteWorkspace(String id) async {
    await _db.delete('workspaces', where: 'id = ?', whereArgs: [id]);
  }
}

class InMemorySessionRepository implements SessionRepository {
  final InMemoryDatabase _db;
  InMemorySessionRepository(this._db);

  @override
  Future<void> saveSession(Session session) async {
    await _db.insert('sessions', session.toMap());
  }

  @override
  Future<Session?> getSession(SessionId id) async {
    final maps = await _db.query('sessions', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Session.fromMap(maps.first);
  }

  @override
  Future<List<Session>> getAllSessions() async {
    final maps = await _db.query('sessions');
    return maps.map(Session.fromMap).toList();
  }

  @override
  Future<void> deleteSession(SessionId id) async {
    await _db.delete('sessions', where: 'id = ?', whereArgs: [id.value]);
  }
}

class InMemoryDeviceRepository implements DeviceRepository {
  final InMemoryDatabase _db;
  InMemoryDeviceRepository(this._db);

  @override
  Future<void> saveDevice(Device device) async {
    await _db.insert('devices', device.toMap());
  }

  @override
  Future<Device?> getDevice(DeviceId id) async {
    final maps = await _db.query('devices', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return Device.fromMap(maps.first);
  }

  @override
  Future<List<Device>> getAllDevices() async {
    final maps = await _db.query('devices');
    return maps.map(Device.fromMap).toList();
  }

  @override
  Future<void> deleteDevice(DeviceId id) async {
    await _db.delete('devices', where: 'id = ?', whereArgs: [id.value]);
  }
}

class InMemoryAccessCodeRepository implements AccessCodeRepository {
  final InMemoryDatabase _db;
  InMemoryAccessCodeRepository(this._db);

  @override
  Future<void> saveAccessCode(AccessCode code) async {
    await _db.insert('access_codes', code.toMap());
  }

  @override
  Future<AccessCode?> getAccessCode(AccessCodeId id) async {
    final maps = await _db.query('access_codes', where: 'id = ?', whereArgs: [id.value]);
    if (maps.isEmpty) return null;
    return AccessCode.fromMap(maps.first);
  }

  @override
  Future<List<AccessCode>> getAllAccessCodes() async {
    final maps = await _db.query('access_codes');
    return maps.map(AccessCode.fromMap).toList();
  }

  @override
  Future<void> deleteAccessCode(AccessCodeId id) async {
    await _db.delete('access_codes', where: 'id = ?', whereArgs: [id.value]);
  }
}

class InMemoryWorkspacePermissionRepository implements WorkspacePermissionRepository {
  final InMemoryDatabase _db;
  InMemoryWorkspacePermissionRepository(this._db);

  @override
  Future<void> saveWorkspacePermission(WorkspacePermission permission) async {
    await _db.insert('workspace_permissions', permission.toMap());
  }

  @override
  Future<WorkspacePermission?> getWorkspacePermission(String path) async {
    final maps = await _db.query('workspace_permissions', where: 'path = ?', whereArgs: [path]);
    if (maps.isEmpty) return null;
    return WorkspacePermission.fromMap(maps.first);
  }

  @override
  Future<List<WorkspacePermission>> getAllWorkspacePermissions() async {
    final maps = await _db.query('workspace_permissions');
    return maps.map(WorkspacePermission.fromMap).toList();
  }

  @override
  Future<void> deleteWorkspacePermission(String path) async {
    await _db.delete('workspace_permissions', where: 'path = ?', whereArgs: [path]);
  }
}

class InMemoryAuditRepository implements AuditRepository {
  final InMemoryDatabase _db;
  InMemoryAuditRepository(this._db);

  @override
  Future<void> saveAuditEvent(AuditEvent event) async {
    await _db.insert('audit_events', event.toMap());
  }

  @override
  Future<List<AuditEvent>> getAuditEvents({DateTime? since, int limit = 100}) async {
    final maps = await _db.query('audit_events', orderBy: 'timestamp DESC', limit: limit);
    return maps.map(AuditEvent.fromMap).toList();
  }
}

// ============================================================================
// Repository Providers
// ============================================================================

final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  return InMemoryAgentRepository(ref.read(databaseProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return InMemoryProjectRepository(ref.read(databaseProvider));
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return InMemoryTaskRepository(ref.read(databaseProvider));
});

final terminalRepositoryProvider = Provider<TerminalRepository>((ref) {
  return InMemoryTerminalRepository(ref.read(databaseProvider));
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
  return InMemorySessionRepository(ref.read(databaseProvider));
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return InMemoryDeviceRepository(ref.read(databaseProvider));
});

final accessCodeRepositoryProvider = Provider<AccessCodeRepository>((ref) {
  return InMemoryAccessCodeRepository(ref.read(databaseProvider));
});

final workspacePermissionRepositoryProvider = Provider<WorkspacePermissionRepository>((ref) {
  return InMemoryWorkspacePermissionRepository(ref.read(databaseProvider));
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return InMemoryAuditRepository(ref.read(databaseProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return InMemoryNotificationRepository(ref.read(databaseProvider));
});

final systemRepositoryProvider = Provider<SystemRepository>((ref) {
  return WindowsSystemRepository();
});

final automationRepositoryProvider = Provider<AutomationRepository>((ref) {
  throw UnimplementedError('Use concrete implementation');
});

final diagnosticsRepositoryProvider = Provider<DiagnosticsRepository>((ref) {
  throw UnimplementedError('Use concrete implementation');
});

final agentAdapterRepositoryProvider = Provider<AgentAdapterRepository>((ref) {
  throw UnimplementedError('Use concrete implementation');
});

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return InMemoryWorkspaceRepository(ref.read(databaseProvider));
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
  return TerminalService(
    ref.read(terminalRepositoryProvider),
    ref.read(shellRepositoryProvider),
  );
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

final taskManagerProvider = Provider<TaskManager>((ref) {
  return TaskManager(
    ref.read(taskRepositoryProvider),
    ref.read(agentManagerProvider),
  );
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
  return await ref.read(agentRepositoryProvider).getAllAgents();
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