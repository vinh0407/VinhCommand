import 'dart:convert';
import 'dart:io';
export 'repositories.dart';

/// Serialized atomic writes. A failed write never commits in-memory state.
class DatabaseService {
  final File? file;
  Map<String, dynamic> _tables;
  Future<void> _pending = Future.value();
  DatabaseService.memory() : file = null, _tables = {};
  DatabaseService._(this.file, this._tables);
  static Future<DatabaseService> open(File file) async {
    if (!await file.exists()) return DatabaseService._(file, {});
    final doc = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (doc['version'] != 1) throw const FormatException('Unsupported data version');
    return DatabaseService._(file, Map<String, dynamic>.from(doc['tables'] as Map));
  }
  List<Map<String, dynamic>> rows(String table) =>
    ((_tables[table] as Map?) ?? {}).values.map((r) => Map<String, dynamic>.from(r as Map)).toList();
  Future<void> put(String table, String id, Map<String, dynamic> row) => _change(table, (rows) => rows[id] = row);
  Future<void> removeWhere(String table, bool Function(Map<String, dynamic>) predicate) =>
    _change(table, (rows) => rows.removeWhere((_, r) => predicate(Map<String, dynamic>.from(r as Map))));
  Future<void> _change(String table, void Function(Map<String, dynamic>) mutate) {
    final operation = _pending.then((_) async {
      final next = Map<String, dynamic>.from(_tables);
      final rows = Map<String, dynamic>.from((_tables[table] as Map?) ?? {});
      mutate(rows);
      next[table] = rows;
      if (file != null) {
        await file!.parent.create(recursive: true);
        final temporary = File('${file!.path}.tmp');
        await temporary.writeAsString(jsonEncode({'version': 1, 'tables': next}), flush: true);
        await temporary.rename(file!.path);
      }
      _tables = next;
    });
    _pending = operation.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return operation;
  }
}
class EntityTable<T> {
  final DatabaseService db;
  final String name;
  final T Function(Map<String, dynamic>) decode;
  final Map<String, dynamic> Function(T) encode;
  EntityTable(this.db, this.name, this.decode, this.encode);
  List<T> all() => db.rows(name).map(decode).toList();
  T? first(bool Function(T) predicate) {
    for (final item in all()) { if (predicate(item)) return item; }
    return null;
  }
  Future<T> save(T value) async {
    final row = encode(value);
    await db.put(name, (row['id'] ?? row['name']) as String, row);
    return value;
  }
  Future<void> delete(String id) => db.removeWhere(name, (r) => (r['id'] ?? r['name']) == id);
  Future<void> patch(String id, Map<String, dynamic> values) async {
    final row = db.rows(name).where((r) => (r['id'] ?? r['name']) == id).firstOrNull;
    if (row == null) throw StateError('$name record not found');
    await db.put(name, id, {...row, ...values});
  }
}
