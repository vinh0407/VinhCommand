import 'dart:io';
import 'package:path/path.dart' as p;
import '../../infrastructure/database/database_service.dart';

class ProjectAccess {
  final DatabaseService db;
  ProjectAccess(this.db);
  
  String mode(String id) {
    try {
      final rows = db.rows('project_access');
      final val = rows.where((r) => r['id'] == id).firstOrNull?['mode'] as String?;
      if (['read-only', 'workspace-write'].contains(val)) return val!;
      return 'workspace-write';
    } catch (_) {
      return 'workspace-write';
    }
  }

  Future<void> grant(String id, String directory, String mode) async {
    if (!['read-only', 'workspace-write'].contains(mode)) throw ArgumentError('Unsupported access mode');
    String canonical = directory;
    try {
      final dir = Directory(directory);
      if (await dir.exists()) {
        canonical = await dir.resolveSymbolicLinks();
      }
    } catch (_) {
      canonical = p.normalize(directory);
    }
    await db.put('project_access', id, {
      'id': id,
      'path': canonical,
      'mode': mode,
      'grantedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> revoke(String id) => db.removeWhere('project_access', (r) => r['id'] == id);

  Future<void> validate(String id, String directory, String requested) async {
    final row = db.rows('project_access').where((r) => r['id'] == id).firstOrNull;
    if (row == null) throw StateError('Authorize this project on the desktop first');
    
    String canonical = directory;
    try {
      final dir = Directory(directory);
      if (await dir.exists()) {
        canonical = await dir.resolveSymbolicLinks();
      }
    } catch (_) {
      canonical = p.normalize(directory);
    }
    
    final savedPath = row['path'] as String? ?? '';
    if (!p.equals(canonical.toLowerCase(), savedPath.toLowerCase())) {
      throw StateError('Project location changed; authorize it again');
    }
    
    if (!['read-only', 'workspace-write'].contains(requested)) throw StateError('Unsupported task permission');
    if (requested == 'workspace-write' && row['mode'] != 'workspace-write') {
      throw StateError('Project is only authorized for review');
    }
  }
}
