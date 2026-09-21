import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/application/workflow/project_access.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
void main() {
  test('project access is denied by default, scoped to the canonical path and revocable', () async {
    final dir = await Directory.systemTemp.createTemp('vc-access-');
    addTearDown(() => dir.delete(recursive: true));
    final access = ProjectAccess(DatabaseService.memory());
    expect(() => access.validate('p', dir.path, 'read-only'), throwsStateError);
    await access.grant('p', dir.path, 'read-only');
    await access.validate('p', dir.path, 'read-only');
    expect(() => access.validate('p', dir.path, 'workspace-write'), throwsStateError);
    expect(() => access.validate('p', '${dir.path}/other', 'read-only'), throwsA(anything));
    await access.revoke('p');
    expect(() => access.validate('p', dir.path, 'read-only'), throwsStateError);
  });
}
