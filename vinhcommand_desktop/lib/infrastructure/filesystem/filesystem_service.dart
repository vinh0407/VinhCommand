import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, FileMode, Platform;
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import '../../core/vinhcommand_core.dart';

class FileSystemService implements FileSystemRepository {
  final List<String> _allowedPaths = [];
  final Map<String, StreamController<FileChange>> _watchers = {};

  @override
  Future<bool> exists(String path) async {
    return await File(path).exists() || await Directory(path).exists();
  }

  @override
  Future<bool> isDirectory(String path) async {
    return await Directory(path).exists();
  }

  @override
  Future<bool> isFile(String path) async {
    return await File(path).exists();
  }

  @override
  Future<FileInfo> getFileInfo(String path) async {
    _validatePath(path);
    
    final file = File(path);
    final dir = Directory(path);
    
    if (await file.exists()) {
      final stat = await file.stat();
      return FileInfo(
        path: path,
        name: p.basename(path),
        isDirectory: false,
        size: stat.size,
        modifiedAt: stat.modified,
        createdAt: stat.changed,
        mimeType: _getMimeType(path),
        permissions: FilePermissions(
          readable: true,
          writable: true,
          executable: await _isExecutable(path),
        ),
      );
    } else if (await dir.exists()) {
      final stat = await dir.stat();
      return FileInfo(
        path: path,
        name: p.basename(path),
        isDirectory: true,
        size: 0,
        modifiedAt: stat.modified,
        createdAt: stat.changed,
        mimeType: 'inode/directory',
        permissions: FilePermissions(
          readable: true,
          writable: true,
          executable: true,
        ),
      );
    } else {
      throw FileSystemException(
        code: 'FILE_NOT_FOUND',
        message: 'File or directory not found: $path',
      );
    }
  }

  @override
  Future<List<FileInfo>> listDirectory(String path, {bool recursive = false}) async {
    _validatePath(path);
    
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw FileSystemException(
        code: 'DIRECTORY_NOT_FOUND',
        message: 'Directory not found: $path',
      );
    }

    final files = <FileInfo>[];
    
    await for (final entity in dir.list(recursive: recursive, followLinks: false)) {
      if (entity is File) {
        final stat = await entity.stat();
        files.add(FileInfo(
          path: entity.path,
          name: p.basename(entity.path),
          isDirectory: false,
          size: stat.size,
          modifiedAt: stat.modified,
          createdAt: stat.changed,
          mimeType: _getMimeType(entity.path),
          permissions: FilePermissions(
            readable: true,
            writable: true,
            executable: await _isExecutable(entity.path),
          ),
        ));
      } else if (entity is Directory) {
        final stat = await entity.stat();
        files.add(FileInfo(
          path: entity.path,
          name: p.basename(entity.path),
          isDirectory: true,
          size: 0,
          modifiedAt: stat.modified,
          createdAt: stat.changed,
          mimeType: 'inode/directory',
          permissions: FilePermissions(
            readable: true,
            writable: true,
            executable: true,
          ),
        ));
      }
    }

    files.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return files;
  }

  @override
  Future<String> readFile(String path, {int? offset, int? length}) async {
    _validatePath(path);
    
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException(
        code: 'FILE_NOT_FOUND',
        message: 'File not found: $path',
      );
    }

    if (offset != null || length != null) {
      final bytes = await file.readAsBytes();
      final start = offset ?? 0;
      final end = length != null ? start + length : bytes.length;
      return utf8.decode(bytes.sublist(start, end.clamp(0, bytes.length)));
    }

    return await file.readAsString();
  }

  @override
  Future<void> writeFile(String path, String content, {bool createDirs = true}) async {
    _validatePath(path);
    
    final file = File(path);
    if (createDirs) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  @override
  Future<void> appendFile(String path, String content) async {
    _validatePath(path);
    
    final file = File(path);
    await file.writeAsString(content, mode: FileMode.append);
  }

  @override
  Future<void> deleteFile(String path) async {
    _validatePath(path);
    
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteDirectory(String path, {bool recursive = false}) async {
    _validatePath(path);
    
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: recursive);
    }
  }

  @override
  Future<void> copyFile(String source, String destination) async {
    _validatePath(source);
    _validatePath(destination);
    
    final sourceFile = File(source);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        code: 'SOURCE_NOT_FOUND',
        message: 'Source file not found: $source',
      );
    }

    await sourceFile.copy(destination);
  }

  @override
  Future<void> moveFile(String source, String destination) async {
    _validatePath(source);
    _validatePath(destination);
    
    final sourceFile = File(source);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        code: 'SOURCE_NOT_FOUND',
        message: 'Source file not found: $source',
      );
    }

    await sourceFile.rename(destination);
  }

  @override
  Future<void> createDirectory(String path, {bool recursive = true}) async {
    _validatePath(path);
    
    final dir = Directory(path);
    await dir.create(recursive: recursive);
  }

  @override
  Future<String> getCanonicalPath(String path) async {
    _validatePath(path);
    
    final file = File(path);
    final dir = Directory(path);
    
    if (await file.exists()) {
      return file.resolveSymbolicLinksSync();
    } else if (await dir.exists()) {
      return dir.resolveSymbolicLinksSync();
    }
    
    return path;
  }

  @override
  Future<bool> isPathAllowed(String path, List<String> allowedPaths) async {
    try {
      final canonical = await getCanonicalPath(path);
      
      for (final allowed in allowedPaths) {
        final allowedCanonical = await getCanonicalPath(allowed);
        if (canonical.startsWith(allowedCanonical)) {
          return true;
        }
      }
      
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<FileHash> computeHash(String path) async {
    _validatePath(path);
    
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException(
        code: 'FILE_NOT_FOUND',
        message: 'File not found: $path',
      );
    }

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    
    return FileHash(
      algorithm: 'SHA-256',
      hash: digest.toString(),
    );
  }

  @override
  Future<void> watchDirectory(String path, Function(FileChange) onChange) async {
    _validatePath(path);
    
    if (_watchers.containsKey(path)) return;

    final controller = StreamController<FileChange>.broadcast();
    _watchers[path] = controller;

final subscription = Directory(path).watch(recursive: true).listen((event) {
      final change = FileChange(
        path: event.path,
        type: _mapChangeType(event.type),
        oldPath: event.type.toString().contains('move') ? event.path : null,
        timestamp: DateTime.now(),
      );
      controller.add(change);
      onChange(change);
    });

    controller.onCancel = () {
      subscription.cancel();
      _watchers.remove(path);
    };
  }

  @override
  Future<void> unwatchDirectory(String path) async {
    final controller = _watchers.remove(path);
    await controller?.close();
  }

  void addAllowedPath(String path) {
    _allowedPaths.add(path);
  }

  void removeAllowedPath(String path) {
    _allowedPaths.remove(path);
  }

  void _validatePath(String path) {
    if (_allowedPaths.isNotEmpty) {
      bool allowed = false;
      for (final allowedPath in _allowedPaths) {
        if (path.startsWith(allowedPath)) {
          allowed = true;
          break;
        }
      }
      if (!allowed) {
        throw PathTraversalException(
          message: 'Access denied: path not in allowed workspaces',
          suggestedAction: 'Add the path to allowed workspaces in Security settings',
        );
      }
    }

    final normalized = p.normalize(path);
    if (normalized.contains('..')) {
      throw PathTraversalException(
        message: 'Path traversal detected: $path',
      );
    }
  }

FileChangeType _mapChangeType(dynamic type) {
    final typeStr = type.toString();
    if (typeStr.contains('create')) return FileChangeType.created;
    if (typeStr.contains('modify')) return FileChangeType.modified;
    if (typeStr.contains('delete')) return FileChangeType.deleted;
    if (typeStr.contains('move')) return FileChangeType.renamed;
    return FileChangeType.modified;
  }

  String _getMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.dart': return 'application/dart';
      case '.js': return 'application/javascript';
      case '.ts': return 'application/typescript';
      case '.jsx': return 'text/jsx';
      case '.tsx': return 'text/tsx';
      case '.json': return 'application/json';
      case '.html': return 'text/html';
      case '.css': return 'text/css';
      case '.py': return 'text/x-python';
      case '.java': return 'text/x-java';
      case '.cs': return 'text/x-csharp';
      case '.cpp': case '.cc': case '.cxx': return 'text/x-c++';
      case '.go': return 'text/x-go';
      case '.rs': return 'text/x-rust';
      case '.md': return 'text/markdown';
      case '.yaml': case '.yml': return 'application/yaml';
      case '.toml': return 'application/toml';
      case '.xml': return 'application/xml';
      case '.txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  Future<bool> _isExecutable(String path) async {
    if (Platform.isWindows) {
      final ext = p.extension(path).toLowerCase();
      return ['.exe', '.bat', '.cmd', '.ps1', '.sh'].contains(ext);
    }
    
try {
      final stat = await File(path).stat();
      const executableBits = 73; // 0o111 = decimal 73
      return (stat.mode & executableBits) != 0;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    for (final controller in _watchers.values) {
      controller.close();
    }
    _watchers.clear();
  }
}


