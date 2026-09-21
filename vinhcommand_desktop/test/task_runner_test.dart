import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/application/managers/agent_manager.dart';
import 'package:vinhcommand_desktop/application/managers/task_manager.dart';

void main() {
  test('task runs in project directory, captures output and marks nonzero exit failed', () async {
    final dir = await Directory.systemTemp.createTemp('vinh-task-');
    addTearDown(() => dir.delete(recursive: true));
    final db = DatabaseService.memory();
    final tasks = DatabaseTaskRepository(db);
    final projects = DatabaseProjectRepository(db);
    final agents = DatabaseAgentRepository(db);
    await projects.saveProject(Project(id: const ProjectId('p'), name: 'test', rootPath: dir.path, framework: ProjectFramework.unknown, languages: [], scripts: {}, buildCommands: [], testCommands: [], devCommands: [], ports: [], processes: [], agents: [], discoveredAt: DateTime.now()));
    await agents.saveAgent(Agent(id: const AgentId('a'), name: 'Codex', version: 'test', executable: 'codex', path: 'codex', status: AgentStatus.available, running: false, authenticated: true, capabilities: [], metadata: {}, discoveredAt: DateTime.now()));
    final runner = TaskManager(tasks, AgentManager(agents, DatabaseAgentAdapterRepository(db)), projects, startProcess: (exe, args, cwd) async {
      expect(cwd, dir.path);
      expect(args, contains('read-only'));
      return Process.start('node', ['-e', "process.stdin.resume();process.stdin.on('end',()=>{console.log('RESULT: '+process.cwd());process.exitCode=7;});"], workingDirectory: cwd);
    });
    addTearDown(runner.dispose);
    final task = await runner.createTask(projectId: const ProjectId('p'), agentId: const AgentId('a'), prompt: 'Review this project', permission: 'read-only', executionMode: 'manual');
    await runner.startTask(task.id);
    expect((await tasks.getTaskById(task.id))?.state, TaskState.failed);
    expect((await tasks.getTaskLogs(task.id)).map((l) => l.message).join(), contains('RESULT:'));
  });
}
