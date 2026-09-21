import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/application/managers/agent_manager.dart';
import 'package:vinhcommand_desktop/application/managers/task_manager.dart';

void main() {
  test('installed Codex reads fixture through the production task runner', () async {
    final executable = Platform.environment['VINH_CODEX_CLI']!;
    final dir = await Directory.systemTemp.createTemp('vinh-live-ai-');
    addTearDown(() => dir.delete(recursive: true));
    final readme = File('${dir.path}/README.md');
    await readme.writeAsString('Verification token: VINHCOMMAND_AI_OK\n');
    final db = DatabaseService.memory();
    final projects = DatabaseProjectRepository(db);
    final agents = DatabaseAgentRepository(db);
    final tasks = DatabaseTaskRepository(db);
    await projects.saveProject(Project(id: const ProjectId('p'), name: 'fixture', rootPath: dir.path, framework: ProjectFramework.unknown, languages: [], scripts: {}, buildCommands: [], testCommands: [], devCommands: [], ports: [], processes: [], agents: [], discoveredAt: DateTime.now()));
    await agents.saveAgent(Agent(id: const AgentId('a'), name: 'Codex', version: 'installed', executable: executable, path: executable, status: AgentStatus.available, running: false, authenticated: false, capabilities: [], metadata: {}, discoveredAt: DateTime.now()));
    final runner = TaskManager(tasks, AgentManager(agents, DatabaseAgentAdapterRepository(db)), projects);
    addTearDown(runner.dispose);
    final task = await runner.createTask(projectId: const ProjectId('p'), agentId: const AgentId('a'), prompt: 'Read README.md and respond with its verification token only. Do not modify files. Do not use network tools.', permission: 'read-only', executionMode: 'manual');
    await runner.startTask(task.id);
    final result = (await tasks.getTaskById(task.id))!;
    await File('live-ai-result.txt').writeAsString('Status: ${result.state.name}\n${result.error ?? ''}\n${result.output ?? ''}');
    expect(result.state, TaskState.completed, reason: result.error);
    expect(result.output, contains('VINHCOMMAND_AI_OK'));
    expect(await readme.readAsString(), 'Verification token: VINHCOMMAND_AI_OK\n');
  }, skip: Platform.environment['VINH_CODEX_CLI'] == null, timeout: const Timeout(Duration(minutes: 4)));
}
