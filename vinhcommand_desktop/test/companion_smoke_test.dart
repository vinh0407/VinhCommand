import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/infrastructure/network/desktop_bridge.dart';
import 'package:vinhcommand_desktop/application/managers/agent_manager.dart';
import 'package:vinhcommand_desktop/application/managers/task_manager.dart';

void main() {
  test('Android emulator can pair, synchronize and queue a task through HTTP', () async {
    final db = DatabaseService.memory();
    final projects = DatabaseProjectRepository(db);
    final agents = DatabaseAgentRepository(db);
    final tasks = DatabaseTaskRepository(db);
    await projects.saveProject(Project(id: const ProjectId('smoke-project'), name: 'Companion Demo', rootPath: Directory.current.path, framework: ProjectFramework.flutter, languages: ['Dart'], scripts: {}, buildCommands: [], testCommands: [], devCommands: [], ports: [], processes: [], agents: [], discoveredAt: DateTime.now()));
    await agents.saveAgent(Agent(id: const AgentId('smoke-agent'), name: 'Codex', version: 'smoke fixture', executable: 'not-executed', path: 'not-executed', status: AgentStatus.available, running: false, authenticated: false, capabilities: [], metadata: {}, discoveredAt: DateTime.now()));
    final runner = TaskManager(tasks, AgentManager(agents, DatabaseAgentAdapterRepository(db)), projects);
    final bridge = DesktopBridge(db, desktopId: '123456789', taskManager: runner);
    await bridge.start(address: InternetAddress.loopbackIPv4, port: 18444);
    addTearDown(bridge.stop);
    final ready = File('companion-smoke-ready.json');
    await ready.writeAsString(jsonEncode({'desktopId': bridge.desktopId, 'code': bridge.accessCode, 'port': bridge.port}));
    addTearDown(() async { if(await ready.exists()) await ready.delete(); });
    final deadline = DateTime.now().add(const Duration(minutes: 6));
    while((await tasks.getAllTasks()).isEmpty && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    final created = await tasks.getAllTasks();
    expect(created, hasLength(1));
    expect(created.single.prompt, 'Review from Android emulator');
    expect(created.single.state, TaskState.queued);
    // Allow the phone to synchronize the queued state for a screenshot.
    await Future<void>.delayed(const Duration(seconds: 15));
  }, skip: Platform.environment['VINH_COMPANION_SMOKE'] != '1', timeout: const Timeout(Duration(minutes: 7)));
}
