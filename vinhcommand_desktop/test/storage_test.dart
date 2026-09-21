import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';

void main() {
  test('project survives reopening storage and path lookup stays isolated', () async {
    final dir = await Directory.systemTemp.createTemp('vinh-storage-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/state.json');
    final db = await DatabaseService.open(file);
    final repo = DatabaseProjectRepository(db);
    await repo.saveProject(Project(
      id: const ProjectId('one'), name: 'Demo', rootPath: dir.path,
      framework: ProjectFramework.unknown, languages: ['Dart'], scripts: {},
      buildCommands: [], testCommands: [], devCommands: [], ports: [],
      processes: [], agents: [], discoveredAt: DateTime.utc(2026),
    ));
    final restored = DatabaseProjectRepository(await DatabaseService.open(file));
    expect((await restored.getProjectById(const ProjectId('one')))?.name, 'Demo');
    expect(await restored.getProjectByPath('${dir.path}-other'), isNull);
    expect((await restored.searchProjects('demo')).length, 1);
    await restored.deleteProject(const ProjectId('one'));
    expect(await DatabaseProjectRepository(await DatabaseService.open(file)).getAllProjects(), isEmpty);
  });
}
