import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/infrastructure/project_discovery/project_discovery_service.dart';

void main() {
  test('workspace root is discovered once and dependency folders are skipped', () async {
    final dir = await Directory.systemTemp.createTemp('vinh-discovery-');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/pubspec.yaml').writeAsString('name: demo');
    await Directory('${dir.path}/node_modules/dependency').create(recursive: true);
    await File('${dir.path}/node_modules/dependency/package.json').writeAsString('{}');
    await File('${dir.path}/node_modules/dependency/vendor.swift').writeAsString('// dependency');
    final db = DatabaseService.memory();
    final projects = DatabaseProjectRepository(db);
    final workspaces = DatabaseWorkspaceRepository(db);
    final service = ProjectDiscoveryService(projects, workspaces);
    await service.addWorkspace(dir.path);
    expect((await service.scanWorkspaces()).map((p) => p.rootPath), [dir.path]);
    await ProjectDiscoveryService(projects, workspaces).scanWorkspaces();
    expect((await projects.getAllProjects()).length, 1);
    expect((await projects.getAllProjects()).single.languages, isNot(contains('Swift')));
    final project = (await projects.getAllProjects()).single;
    await projects.deleteProject(project.id);
    await service.scanWorkspaces();
    expect(await projects.getAllProjects(), isEmpty, reason: 'Removed project must not reappear after scan');
    expect(await File('${dir.path}/pubspec.yaml').exists(), isTrue, reason: 'Source must remain on disk');
  });
}

