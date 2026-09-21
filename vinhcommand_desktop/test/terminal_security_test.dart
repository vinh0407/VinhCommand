import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/infrastructure/terminal/terminal_service.dart';
import 'package:vinhcommand_desktop/infrastructure/security/security_service.dart';

class TestShells implements ShellRepository {
  final shell = ShellInfo(name: 'test', executable: Platform.isWindows ? 'cmd.exe' : '/bin/sh', arguments: Platform.isWindows ? ['/Q'] : [], available: true);
  @override Future<List<ShellInfo>> getAvailableShells() async => [shell];
  @override Future<ShellInfo?> getDefaultShell() async => shell;
  @override Future<ShellInfo?> getShellByName(String name) async => shell;
}
void main() {
  test('terminal reads real shell output and saves exit state', () async {
    final repo = DatabaseTerminalRepository(DatabaseService.memory());
    final service = TerminalService(repo, TestShells());
    addTearDown(service.dispose);
    final terminal = await service.createTerminal();
    final output = service.getOutputStream(terminal.id).firstWhere((o) => o.data.contains('VINH_TEST_OK')).timeout(const Duration(seconds: 10));
    await service.writeInput(terminal.id, 'echo VINH_TEST_OK\n');
    expect((await output).data, contains('VINH_TEST_OK'));
    final exited = service.getOutputStream(terminal.id).firstWhere((o) => o.type == OutputType.exit).timeout(const Duration(seconds: 10));
    await service.writeInput(terminal.id, 'exit\n');
    await exited;
    expect((await repo.getTerminalById(terminal.id))?.status, TerminalStatus.exited);
  });
  test('workspace permission rejects sibling prefixes and traversal', () async {
    final db = DatabaseService.memory();
    final permissions = DatabaseWorkspacePermissionRepository(db);
    final root = await Directory.systemTemp.createTemp('vinh-permission-');
    addTearDown(() => root.delete(recursive: true));
    await permissions.savePermission(WorkspacePermission(id: 'p', path: root.path, name: 'test', enabled: true, allowedOperations: ['read'], createdAt: DateTime.now()));
    final security = SecurityService(DatabaseSessionRepository(db), DatabaseDeviceRepository(db), DatabaseAccessCodeRepository(db), permissions, DatabaseAuditRepository(db));
    expect(await security.isPathAllowed(root.path), isTrue);
    expect(await security.isPathAllowed('${root.path}-other'), isFalse);
    expect(await security.isPathAllowed('${root.path}/../outside'), isFalse);
  });
}
