import '../../core/vinhcommand_core.dart';
import 'database_service.dart';
import 'entity_codecs.dart';

class DatabaseAgentRepository extends EntityTable<Agent> implements AgentRepository {
  DatabaseAgentRepository(DatabaseService db) : super(db, 'agents', decodeAgent, encodeAgent);
  @override Future<List<Agent>> getAllAgents() async => all();
  @override Future<Agent?> getAgentById(AgentId id) async => first((a) => a.id == id);
  @override Future<Agent?> getAgentByName(String name) async => first((a) => a.name == name);
  @override Future<Agent> saveAgent(Agent agent) => save(agent);
  @override Future<void> deleteAgent(AgentId id) => delete(id.value);
  @override Future<void> updateAgentStatus(AgentId id, AgentStatus status) => patch(id.value, {'status': status.name, 'running': status == AgentStatus.running});
  @override Future<void> updateAgentCapabilities(AgentId id, List<AgentCapability> capabilities) => patch(id.value, {'capabilities': capabilities.map((c) => c.name).toList()});
  @override Future<List<Agent>> getAvailableAgents() async => all().where((a) => a.isAvailable).toList();
  @override Future<List<Agent>> getRunningAgents() async => all().where((a) => a.running).toList();
}
class DatabaseProjectRepository extends EntityTable<Project> implements ProjectRepository {
  DatabaseProjectRepository(DatabaseService db) : super(db, 'projects', decodeProject, encodeProject);
  @override Future<List<Project>> getAllProjects() async => all();
  @override Future<Project?> getProjectById(ProjectId id) async => first((p) => p.id == id);
  @override Future<Project?> getProjectByPath(String path) async => first((p) => p.rootPath == path);
  @override Future<Project> saveProject(Project project) async {
    if (db.rows('excluded_projects').any((row) => row['path'] == project.rootPath)) return project;
    return save(project);
  }
  @override Future<void> deleteProject(ProjectId id) async {
    final project = await getProjectById(id);
    if (project == null) return;
    final tasks = await DatabaseTaskRepository(db).getTasksByProject(id);
    if (tasks.any((task) => task.isActive)) throw StateError('Stop active tasks before removing this project');
    await db.put('excluded_projects', id.value, {'id': id.value, 'path': project.rootPath});
    await db.removeWhere('project_access', (row) => row['id'] == id.value);
    for (final task in tasks.where((task) => task.state == TaskState.queued)) {
      await DatabaseTaskRepository(db).saveTask(task.copyWith(state: TaskState.cancelled, completedAt: DateTime.now(), error: 'Project removed from VinhCommand'));
    }
    await delete(id.value);
  }
  @override Future<void> updateProjectLastScanned(ProjectId id, DateTime scannedAt) => patch(id.value, {'lastScannedAt': scannedAt.toIso8601String()});
  @override Future<List<Project>> getActiveProjects() async => all().where((p) => p.isActive).toList();
  @override Future<List<Project>> searchProjects(String query) async => all().where((p) => '${p.name} ${p.rootPath}'.toLowerCase().contains(query.toLowerCase())).toList();
  @override Future<List<Project>> getProjectsByFramework(ProjectFramework framework) async => all().where((p) => p.framework == framework).toList();
}
class DatabaseWorkspaceRepository extends EntityTable<Workspace> implements WorkspaceRepository {
  DatabaseWorkspaceRepository(DatabaseService db) : super(db, 'workspaces', decodeWorkspace, encodeWorkspace);
  @override Future<List<Workspace>> getAllWorkspaces() async => all();
  @override Future<Workspace?> getWorkspaceById(String id) async => first((w) => w.id == id);
  @override Future<Workspace?> getWorkspaceByPath(String path) async => first((w) => w.path == path);
  @override Future<Workspace> saveWorkspace(Workspace workspace) => save(workspace);
  @override Future<void> deleteWorkspace(String id) => delete(id);
  @override Future<void> updateWorkspaceLastScanned(String id, DateTime time) => patch(id, {'lastScannedAt': time.toIso8601String()});
  @override Future<void> updateWorkspaceProjectCount(String id, int count) => patch(id, {'projectCount': count});
}
class DatabaseAgentAdapterRepository extends EntityTable<AgentAdapterConfig> implements AgentAdapterRepository {
  DatabaseAgentAdapterRepository(DatabaseService db) : super(db, 'adapters', decodeAgentAdapterConfig, encodeAgentAdapterConfig);
  @override Future<AgentAdapterConfig?> getAdapterConfig(String name) async => first((a) => a.name == name);
  @override Future<void> saveAdapterConfig(AgentAdapterConfig config) async { await save(config); }
  @override Future<void> deleteAdapterConfig(String name) => delete(name);
  @override Future<List<AgentAdapterConfig>> getAllAdapterConfigs() async => all();
}
class DatabaseTaskRepository extends EntityTable<Task> implements TaskRepository {
  DatabaseTaskRepository(DatabaseService db) : super(db, 'tasks', decodeTask, encodeTask);
  @override Future<List<Task>> getAllTasks() async => all();
  @override Future<Task?> getTaskById(TaskId id) async => first((t) => t.id == id);
  @override Future<List<Task>> getTasksByProject(ProjectId id) async => all().where((t) => t.projectId == id).toList();
  @override Future<List<Task>> getTasksByAgent(AgentId id) async => all().where((t) => t.agentId == id).toList();
  @override Future<List<Task>> getTasksByState(TaskState state) async => all().where((t) => t.state == state).toList();
  @override Future<Task> saveTask(Task task) => save(task);
  @override Future<void> deleteTask(TaskId id) async { await delete(id.value); await db.removeWhere('taskLogs', (r) => r['taskId'] == id.value); }
  @override Future<void> addTaskLog(TaskId id, TaskLog log) async {
    if (log.taskId != id) throw ArgumentError('Task log belongs to another task');
    await db.put('taskLogs', log.id, encodeTaskLog(log));
  }
  @override Future<List<TaskLog>> getTaskLogs(TaskId id) async => db.rows('taskLogs').where((r) => r['taskId'] == id.value).map(decodeTaskLog).toList()..sort((a,b) => a.timestamp.compareTo(b.timestamp));
  @override Future<int> getTaskCountByState(TaskState state) async => (await getTasksByState(state)).length;
  @override Future<List<Task>> getRecentTasks({int limit = 50}) async => (all()..sort((a,b) => b.createdAt.compareTo(a.createdAt))).take(limit).toList();
}
class DatabaseTerminalRepository extends EntityTable<Terminal> implements TerminalRepository {
  DatabaseTerminalRepository(DatabaseService db) : super(db, 'terminals', decodeTerminal, encodeTerminal);
  @override Future<List<Terminal>> getAllTerminals() async => all();
  @override Future<Terminal?> getTerminalById(TerminalId id) async => first((t) => t.id == id);
  @override Future<Terminal> saveTerminal(Terminal terminal) => save(terminal);
  @override Future<void> deleteTerminal(TerminalId id) async { await delete(id.value); await clearTerminalOutput(id); }
  @override Future<void> addTerminalOutput(TerminalId id, TerminalOutput output) async {
    await db.put('terminalOutputs', output.id, encodeTerminalOutput(output));
    final rows = db.rows('terminalOutputs').where((r) => r['terminalId'] == id.value).toList();
    if (rows.length > 2000) {
      final old = rows.take(rows.length - 2000).map((r) => r['id']).toSet();
      await db.removeWhere('terminalOutputs', (r) => old.contains(r['id']));
    }
  }
  @override Future<List<TerminalOutput>> getTerminalOutput(TerminalId id, {int? limit}) async {
    final rows = db.rows('terminalOutputs').where((r) => r['terminalId'] == id.value).map(decodeTerminalOutput).toList();
    return limit == null || rows.length <= limit ? rows : rows.sublist(rows.length-limit);
  }
  @override Future<void> clearTerminalOutput(TerminalId id) => db.removeWhere('terminalOutputs', (r) => r['terminalId'] == id.value);
  @override Future<void> updateTerminalSize(TerminalId id, int rows, int cols) => patch(id.value, {'rows': rows, 'cols': cols});
}
class DatabaseSessionRepository extends EntityTable<Session> implements SessionRepository {
  DatabaseSessionRepository(DatabaseService db) : super(db, 'sessions', decodeSession, encodeSession);
  @override Future<Session?> getSessionById(SessionId id) async => first((s) => s.id == id);
  @override Future<Session?> getSessionByAccessCodeHash(String hash) async => first((s) => s.accessCodeHash == hash);
  @override Future<Session> createSession(Session session) => save(session);
  @override Future<void> updateSession(Session session) async { await save(session); }
  @override Future<void> deleteSession(SessionId id) => delete(id.value);
  @override Future<void> revokeSession(SessionId id) => patch(id.value, {'status': 'revoked'});
  @override Future<List<Session>> getActiveSessions() async => all().where((s) => s.isValid).toList();
  @override Future<List<Session>> getSessionsByDevice(DeviceId id) async => all().where((s) => s.deviceId == id).toList();
  @override Future<void> cleanupExpiredSessions() => db.removeWhere(name, (r) => decodeSession(r).isExpired);
}
class DatabaseDeviceRepository extends EntityTable<Device> implements DeviceRepository {
  DatabaseDeviceRepository(DatabaseService db) : super(db, 'devices', decodeDevice, encodeDevice);
  @override Future<Device?> getDeviceById(DeviceId id) async => first((d) => d.id == id);
  @override Future<Device?> getDeviceByName(String name) async => first((d) => d.name == name);
  @override Future<Device> saveDevice(Device device) => save(device);
  @override Future<void> deleteDevice(DeviceId id) => delete(id.value);
  @override Future<void> updateDeviceLastSeen(DeviceId id, DateTime time) => patch(id.value, {'lastSeenAt': time.toIso8601String()});
  @override Future<void> updateDeviceStatus(DeviceId id, DeviceStatus status) => patch(id.value, {'status': status.name});
  @override Future<List<Device>> getTrustedDevices() async => all().where((d) => d.status == DeviceStatus.trusted).toList();
  @override Future<List<Device>> getAllDevices() async => all();
}
class DatabaseAccessCodeRepository extends EntityTable<AccessCode> implements AccessCodeRepository {
  DatabaseAccessCodeRepository(DatabaseService db) : super(db, 'accessCodes', decodeAccessCode, encodeAccessCode);
  @override Future<AccessCode?> getAccessCodeByHash(String hash) async => first((c) => c.codeHash == hash);
  @override Future<AccessCode> createAccessCode(AccessCode code) => save(code);
  @override Future<void> updateAccessCode(AccessCode code) async { await save(code); }
  @override Future<void> revokeAccessCode(String id) => patch(id, {'revoked': true});
  @override Future<List<AccessCode>> getValidAccessCodes() async => all().where((c) => c.isValid).toList();
  @override Future<void> cleanupExpiredCodes() => db.removeWhere(name, (r) => !decodeAccessCode(r).isValid);
}
class DatabaseWorkspacePermissionRepository extends EntityTable<WorkspacePermission> implements WorkspacePermissionRepository {
  DatabaseWorkspacePermissionRepository(DatabaseService db) : super(db, 'permissions', decodeWorkspacePermission, encodeWorkspacePermission);
  @override Future<WorkspacePermission?> getPermissionByPath(String path) async => first((p) => p.path == path);
  @override Future<WorkspacePermission> savePermission(WorkspacePermission permission) => save(permission);
  @override Future<void> deletePermission(String id) => delete(id);
  @override Future<List<WorkspacePermission>> getAllPermissions() async => all();
  @override Future<List<WorkspacePermission>> getEnabledPermissions() async => all().where((p) => p.enabled).toList();
}
class DatabaseAuditRepository extends EntityTable<AuditEvent> implements AuditRepository {
  DatabaseAuditRepository(DatabaseService db) : super(db, 'audit', decodeAuditEvent, encodeAuditEvent);
  @override Future<void> logEvent(AuditEvent event) async { await save(event); }
  @override Future<List<AuditEvent>> getEvents({DateTime? since, DateTime? until, String? eventType, String? sessionId, String? deviceId, int limit = 100}) async =>
    (all().where((e) => (since == null || !e.timestamp.isBefore(since)) && (until == null || !e.timestamp.isAfter(until)) && (eventType == null || e.eventType == eventType) && (sessionId == null || e.sessionId == sessionId) && (deviceId == null || e.deviceId == deviceId)).toList()..sort((a,b) => b.timestamp.compareTo(a.timestamp))).take(limit).toList();
  @override Future<int> getEventCount(String type, DateTime since) async => all().where((e) => e.eventType == type && !e.timestamp.isBefore(since)).length;
  @override Future<void> cleanupOldEvents(DateTime before) => db.removeWhere(name, (r) => decodeAuditEvent(r).timestamp.isBefore(before));
}
class DatabaseNotificationRepository extends EntityTable<Notification> implements NotificationRepository {
  DatabaseNotificationRepository(DatabaseService db) : super(db, 'notifications', decodeNotification, encodeNotification);
  @override Future<List<Notification>> getNotifications({bool unreadOnly = false, int limit = 50}) async => (all().where((n) => !unreadOnly || !n.read).toList()..sort((a,b) => b.createdAt.compareTo(a.createdAt))).take(limit).toList();
  @override Future<int> getUnreadCount() async => all().where((n) => !n.read).length;
  @override Future<Notification> createNotification(Notification notification) => save(notification);
  @override Future<void> markAsRead(String id) => patch(id, {'read': true});
  @override Future<void> markAllAsRead() async { for(final n in all()) { await markAsRead(n.id); } }
  @override Future<void> deleteNotification(String id) => delete(id);
  @override Future<void> clearAll() => db.removeWhere(name, (_) => true);
}

