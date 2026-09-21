import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/vinhcommand_core.dart';

class DatabaseService {
  static Database? _database;
  static const int _version = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'vinhcommand.db');
    
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE agents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        version TEXT NOT NULL,
        executable TEXT NOT NULL,
        path TEXT NOT NULL,
        status TEXT NOT NULL,
        running INTEGER NOT NULL,
        authenticated INTEGER NOT NULL,
        capabilities TEXT NOT NULL,
        metadata TEXT NOT NULL,
        discovered_at TEXT NOT NULL,
        last_checked_at TEXT,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        framework TEXT NOT NULL,
        git_url TEXT,
        git_branch TEXT,
        description TEXT,
        metadata TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        agent_id TEXT,
        name TEXT NOT NULL,
        description TEXT,
        state TEXT NOT NULL,
        priority INTEGER NOT NULL,
        metadata TEXT NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        error_message TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE terminals (
        id TEXT PRIMARY KEY,
        shell TEXT,
        working_directory TEXT,
        rows INTEGER NOT NULL,
        cols INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE terminal_outputs (
        id TEXT PRIMARY KEY,
        terminal_id TEXT NOT NULL,
        data TEXT NOT NULL,
        output_type TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        metadata TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        platform TEXT NOT NULL,
        status TEXT NOT NULL,
        metadata TEXT NOT NULL,
        last_seen TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE access_codes (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        expires_at TEXT,
        used_at TEXT,
        metadata TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workspace_permissions (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL UNIQUE,
        read INTEGER NOT NULL,
        write INTEGER NOT NULL,
        execute INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_events (
        id TEXT PRIMARY KEY,
        event_type TEXT NOT NULL,
        entity_type TEXT,
        entity_id TEXT,
        message TEXT NOT NULL,
        metadata TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        priority TEXT NOT NULL,
        read INTEGER NOT NULL,
        action_data TEXT,
        related_entity_id TEXT,
        related_entity_type TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE task_logs (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        metadata TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workspaces (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        enabled INTEGER NOT NULL,
        added_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations if needed
  }
}

// ============================================================================
// Stub Repository Implementations
// ============================================================================

class DatabaseAgentRepository implements AgentRepository {
  final Database _db;
  DatabaseAgentRepository(this._db);

  @override
  Future<void> saveAgent(Agent agent) async {
    await _db.insert('agents', agent.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final maps = await _db.query('agents', where: 'status = ?', whereArgs: [status.name]);
    return maps.map(Agent.fromMap).toList();
  }
}

class DatabaseProjectRepository implements ProjectRepository {
  final Database _db;
  DatabaseProjectRepository(this._db);

  @override
  Future<void> saveProject(Project project) async {
    await _db.insert('projects', project.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final maps = await _db.query('projects', where: 'framework = ?', whereArgs: [framework.name]);
    return maps.map(Project.fromMap).toList();
  }
}

class DatabaseTaskRepository implements TaskRepository {
  final Database _db;
  DatabaseTaskRepository(this._db);

  @override
  Future<void> saveTask(Task task) async {
    await _db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    final maps = await _db.query('tasks', where: 'project_id = ?', whereArgs: [projectId.value]);
    return maps.map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksByAgent(AgentId agentId) async {
    final maps = await _db.query('tasks', where: 'agent_id = ?', whereArgs: [agentId.value]);
    return maps.map(Task.fromMap).toList();
  }

  @override
  Future<List<Task>> getTasksByState(TaskState state) async {
    final maps = await _db.query('tasks', where: 'state = ?', whereArgs: [state.name]);
    return maps.map(Task.fromMap).toList();
  }
}

class DatabaseTerminalRepository implements TerminalRepository {
  final Database _db;
  DatabaseTerminalRepository(this._db);

  @override
  Future<void> saveTerminal(Terminal terminal) async {
    await _db.insert('terminals', terminal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.insert('terminal_outputs', output.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<TerminalOutput>> getTerminalOutputs(TerminalId terminalId, {int limit = 1000}) async {
    final maps = await _db.query(
      'terminal_outputs',
      where: 'terminal_id = ?',
      whereArgs: [terminalId.value],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(TerminalOutput.fromMap).toList();
  }

  @override
  Future<void> clearTerminalOutputs(TerminalId terminalId) async {
    await _db.delete('terminal_outputs', where: 'terminal_id = ?', whereArgs: [terminalId.value]);
  }
}

class DatabaseFileSystemRepository implements FileSystemRepository {
  final Database _db;
  DatabaseFileSystemRepository(this._db);

  @override
  Future<void> saveFileChange(FileChange change) async {
    // Stub implementation
  }

  @override
  Future<List<FileChange>> getFileChanges(String path, {DateTime? since}) async {
    return [];
  }

  @override
  Future<void> clearFileChanges(String path) async {
    // Stub implementation
  }
}

class DatabaseSecurityRepository implements SecurityRepository {
  final Database _db;
  DatabaseSecurityRepository(this._db);

  @override
  Future<void> saveSession(Session session) async {
    await _db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.insert('devices', device.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.insert('access_codes', code.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.insert('workspace_permissions', permission.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    await _db.insert('audit_events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<AuditEvent>> getAuditEvents({DateTime? since, int limit = 100}) async {
    var query = _db.query('audit_events', orderBy: 'timestamp DESC', limit: limit);
    if (since != null) {
      query = _db.query('audit_events', where: 'timestamp > ?', whereArgs: [since.toIso8601String()], orderBy: 'timestamp DESC', limit: limit);
    }
    final maps = await query;
    return maps.map(AuditEvent.fromMap).toList();
  }
}

class DatabaseSystemRepository implements SystemRepository {
  final Database _db;
  DatabaseSystemRepository(this._db);

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
  Future<int> startProcess({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<ProcessOutput> runCommand({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
    Duration? timeout,
  }) async {
    throw UnimplementedError('Use ProcessMonitorService');
  }

  @override
  Future<List<DevelopmentServer>> discoverServers() async {
    return [];
  }

  @override
  Future<DevelopmentServer?> getServerByPort(int port) async {
    return null;
  }

  @override
  Future<DevelopmentServer?> getServerByPid(int pid) async {
    return null;
  }

  @override
  Future<void> refreshServer(DevelopmentServer server) async {}

  @override
  Future<void> stopServer(int port) async {}

  @override
  Future<bool> isPortInUse(int port) async {
    return false;
  }

  @override
  Future<int?> getPidByPort(int port) async {
    return null;
  }
}

class DatabaseNotificationRepository implements NotificationRepository {
  final Database _db;
  DatabaseNotificationRepository(this._db);

  @override
  Future<void> saveNotification(Notification notification) async {
    await _db.insert('notifications', notification.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<Notification?> getNotification(String id) async {
    final maps = await _db.query('notifications', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Notification.fromMap(maps.first);
  }

  @override
  Future<List<Notification>> getNotifications({int limit = 50}) async {
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

class DatabaseWorkspaceRepository implements WorkspaceRepository {
  final Database _db;
  DatabaseWorkspaceRepository(this._db);

  @override
  Future<void> saveWorkspace(Workspace workspace) async {
    await _db.insert('workspaces', workspace.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

class DatabaseSessionRepository implements SessionRepository {
  final Database _db;
  DatabaseSessionRepository(this._db);

  @override
  Future<void> saveSession(Session session) async {
    await _db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

class DatabaseDeviceRepository implements DeviceRepository {
  final Database _db;
  DatabaseDeviceRepository(this._db);

  @override
  Future<void> saveDevice(Device device) async {
    await _db.insert('devices', device.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

class DatabaseAccessCodeRepository implements AccessCodeRepository {
  final Database _db;
  DatabaseAccessCodeRepository(this._db);

  @override
  Future<void> saveAccessCode(AccessCode code) async {
    await _db.insert('access_codes', code.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

class DatabaseWorkspacePermissionRepository implements WorkspacePermissionRepository {
  final Database _db;
  DatabaseWorkspacePermissionRepository(this._db);

  @override
  Future<void> saveWorkspacePermission(WorkspacePermission permission) async {
    await _db.insert('workspace_permissions', permission.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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

class DatabaseAuditRepository implements AuditRepository {
  final Database _db;
  DatabaseAuditRepository(this._db);

  @override
  Future<void> saveAuditEvent(AuditEvent event) async {
    await _db.insert('audit_events', event.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<AuditEvent>> getAuditEvents({DateTime? since, int limit = 100}) async {
    var query = _db.query('audit_events', orderBy: 'timestamp DESC', limit: limit);
    if (since != null) {
      query = _db.query('audit_events', where: 'timestamp > ?', whereArgs: [since.toIso8601String()], orderBy: 'timestamp DESC', limit: limit);
    }
    final maps = await query;
    return maps.map(AuditEvent.fromMap).toList();
  }
}

class WindowsShellRepository implements ShellRepository {
  @override
  Future<int> execute(String command, {String? workingDirectory, Map<String, String>? environment}) async {
    final result = await Process.run('cmd', ['/c', command], workingDirectory: workingDirectory, environment: environment);
    return result.exitCode;
  }

  @override
  Future<ProcessOutput> runCommand({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();
    final result = await Process.run(executable, arguments, workingDirectory: workingDirectory, environment: environment).timeout(timeout ?? const Duration(seconds: 30));
    return ProcessOutput(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      duration: DateTime.now().difference(startTime),
    );
  }
}