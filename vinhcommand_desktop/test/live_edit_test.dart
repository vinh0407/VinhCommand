import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/application/managers/agent_manager.dart';
import 'package:vinhcommand_desktop/application/managers/task_manager.dart';
import 'package:vinhcommand_desktop/application/workflow/project_access.dart';
void main() {
  test('live editing task captures files, diff and failing test evidence', () async {
    final dir = await Directory.systemTemp.createTemp('vc-live-edit-');
    addTearDown(() => dir.delete(recursive: true));
    await Process.run('git', ['init', '-q'], workingDirectory: dir.path);
    // Generate valid JSON without shell quoting.
    await File('${dir.path}/package.json').writeAsString('{"name":"vc-fixture","scripts":{"test":"node fail-test.cjs"}}');
    await File('${dir.path}/fail-test.cjs').writeAsString('console.log("FIXTURE_TEST_FAILED");process.exitCode=1;');
    final db = DatabaseService.memory();
    final projects = DatabaseProjectRepository(db), agents = DatabaseAgentRepository(db);
    final tasks = DatabaseTaskRepository(db);
    await projects.saveProject(Project(id: const ProjectId('p'), name: 'fixture', rootPath: dir.path, framework: ProjectFramework.nodejs, languages: [], scripts: {}, buildCommands: [], testCommands: [], devCommands: [], ports: [], processes: [], agents: [], discoveredAt: DateTime.now()));
    final executable = Platform.environment['VINH_CODEX_CLI']!;
    await agents.saveAgent(Agent(id: const AgentId('a'), name: 'Codex', version: 'live', executable: executable, path: executable, status: AgentStatus.available, running: false, authenticated: true, capabilities: [], metadata: {}, discoveredAt: DateTime.now()));
    final access = ProjectAccess(db);
    await access.grant('p', dir.path, 'workspace-write');
    final runner = TaskManager(tasks, AgentManager(agents, DatabaseAgentAdapterRepository(db)), projects, access: access);
    addTearDown(runner.dispose);
    final task = await runner.createTask(projectId: const ProjectId('p'), agentId: const AgentId('a'), prompt: 'This is a controlled test fixture. Use apply_patch to create RESULT.txt with exactly VINH_EDIT_OK. Run cmd /c npm test once. The test intentionally exits 1; report that failure, do not fix it. Do not modify package.json or fail-test.cjs. Do not access network or other directories.', permission: 'workspace-write', executionMode: 'manual');
    var finished = false;
    final running = runner.startTask(task.id).whenComplete(() => finished = true);
    while(!finished) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final current = (await tasks.getTaskById(task.id))!;
      final approval = current.metadata['approval'] as Map?;
      if(approval != null && current.state == TaskState.waitingForApproval) {
        final details = approval['details'] as Map;
        final command = '${details['command'] ?? ''}';
        final changes = (details['item'] as Map?)?['changes'] as List? ?? [];
        final acceptedPatch = details['kind'] == 'item/fileChange/requestApproval' && details['grantRoot'] == null && changes.isNotEmpty && changes.every((change) => p.equals(change['path'] as String, p.join(dir.path, 'RESULT.txt')));
        final accepted = acceptedPatch || (details['kind'] == 'item/commandExecution/requestApproval' && '${details['cwd']}'.toLowerCase() == dir.path.toLowerCase() && RegExp(r'npm(\.cmd)? test').hasMatch(command) && !RegExp(r'[;|>&]').hasMatch(command));
        await runner.respondApproval(task.id, approval['id'] as String, accepted);
      }
    }
    await running;
    final result = (await tasks.getTaskById(task.id))!;
    await File('live-edit-result.txt').writeAsString('State: ${result.state}\nMetadata: ${result.metadata}\nError: ${result.error}\n${(await tasks.getTaskLogs(task.id)).map((l) => l.message).join("\n")}');
    expect(result.state, TaskState.completed, reason: result.error);
    expect(await File('${dir.path}/RESULT.txt').readAsString(), contains('VINH_EDIT_OK'));
    expect(result.metadata['testStatus'], 'failed');
    expect(result.metadata['agentSessionId'], isNotEmpty);
    expect((result.metadata['changedFiles'] as List).join(), contains('RESULT.txt'));
    expect(await File('${dir.path}/fail-test.cjs').readAsString(), 'console.log("FIXTURE_TEST_FAILED");process.exitCode=1;');
  }, skip: Platform.environment['VINH_CODEX_CLI'] == null, timeout: const Timeout(Duration(minutes: 4)));
}
