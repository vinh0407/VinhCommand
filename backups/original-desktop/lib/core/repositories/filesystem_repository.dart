import 'package:equatable/equatable.dart';

abstract class FileSystemRepository {
  Future<bool> exists(String path);

  Future<bool> isDirectory(String path);

  Future<bool> isFile(String path);

  Future<FileInfo> getFileInfo(String path);

  Future<List<FileInfo>> listDirectory(String path, {bool recursive = false});

  Future<String> readFile(String path, {int? offset, int? length});

  Future<void> writeFile(String path, String content, {bool createDirs = true});

  Future<void> appendFile(String path, String content);

  Future<void> deleteFile(String path);

  Future<void> deleteDirectory(String path, {bool recursive = false});

  Future<void> copyFile(String source, String destination);

  Future<void> moveFile(String source, String destination);

  Future<void> createDirectory(String path, {bool recursive = true});

  Future<String> getCanonicalPath(String path);

  Future<bool> isPathAllowed(String path, List<String> allowedPaths);

  Future<FileHash> computeHash(String path);

  Future<void> watchDirectory(String path, Function(FileChange) onChange);

  Future<void> unwatchDirectory(String path);
}

class FileInfo extends Equatable {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modifiedAt;
  final DateTime createdAt;
  final String? mimeType;
  final FilePermissions permissions;

  const FileInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modifiedAt,
    required this.createdAt,
    this.mimeType,
    required this.permissions,
  });

  @override
  List<Object?> get props => [
        path,
        name,
        isDirectory,
        size,
        modifiedAt,
        createdAt,
        mimeType,
        permissions,
      ];
}

class FilePermissions extends Equatable {
  final bool readable;
  final bool writable;
  final bool executable;

  const FilePermissions({
    required this.readable,
    required this.writable,
    required this.executable,
  });

  @override
  List<Object?> get props => [readable, writable, executable];
}

class FileHash extends Equatable {
  final String algorithm;
  final String hash;

  const FileHash({
    required this.algorithm,
    required this.hash,
  });

  @override
  List<Object?> get props => [algorithm, hash];
}

enum FileChangeType {
  created,
  modified,
  deleted,
  renamed,
}

class FileChange extends Equatable {
  final String path;
  final FileChangeType type;
  final String? oldPath;
  final DateTime timestamp;

  const FileChange({
    required this.path,
    required this.type,
    this.oldPath,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [path, type, oldPath, timestamp];
}

abstract class GitRepository {
  Future<GitStatus> getStatus(String repoPath);

  Future<GitDiff> getDiff(String repoPath, {bool staged = false});

  Future<List<GitCommit>> getLog(String repoPath, {int limit = 50});

  Future<List<GitBranch>> getBranches(String repoPath);

  Future<void> checkout(String repoPath, String branch);

  Future<void> stage(String repoPath, List<String> files);

  Future<void> unstage(String repoPath, List<String> files);

  Future<GitCommitResult> commit(String repoPath, String message);

  Future<void> stash(String repoPath);

  Future<void> stashPop(String repoPath);

  Future<void> pull(String repoPath);

  Future<void> push(String repoPath);

  Future<void> fetch(String repoPath);

  Future<bool> isRepo(String path);

  Future<String?> getRootPath(String path);
}

class GitStatus extends Equatable {
  final bool isClean;
  final int stagedFiles;
  final int unstagedFiles;
  final int untrackedFiles;
  final int ahead;
  final int behind;
  final String currentBranch;
  final String? remoteUrl;

  const GitStatus({
    required this.isClean,
    required this.stagedFiles,
    required this.unstagedFiles,
    required this.untrackedFiles,
    required this.ahead,
    required this.behind,
    required this.currentBranch,
    this.remoteUrl,
  });

  @override
  List<Object?> get props => [
        isClean,
        stagedFiles,
        unstagedFiles,
        untrackedFiles,
        ahead,
        behind,
        currentBranch,
        remoteUrl,
      ];

  int get totalChanges => stagedFiles + unstagedFiles + untrackedFiles;
}

class GitDiff extends Equatable {
  final List<GitFileDiff> files;
  final int totalAdditions;
  final int totalDeletions;

  const GitDiff({
    required this.files,
    required this.totalAdditions,
    required this.totalDeletions,
  });

  @override
  List<Object?> get props => [files, totalAdditions, totalDeletions];
}

class GitFileDiff extends Equatable {
  final String path;
  final GitDiffStatus status;
  final int additions;
  final int deletions;
  final List<GitHunk> hunks;

  const GitFileDiff({
    required this.path,
    required this.status,
    required this.additions,
    required this.deletions,
    required this.hunks,
  });

  @override
  List<Object?> get props => [path, status, additions, deletions, hunks];
}

enum GitDiffStatus {
  added,
  modified,
  deleted,
  renamed,
  copied,
  unmerged,
}

class GitHunk extends Equatable {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final List<GitLine> lines;

  const GitHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
  });

  @override
  List<Object?> get props => [oldStart, oldLines, newStart, newLines, lines];
}

class GitLine extends Equatable {
  final GitLineType type;
  final String content;
  final int? oldLineNumber;
  final int? newLineNumber;

  const GitLine({
    required this.type,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
  });

  @override
  List<Object?> get props => [type, content, oldLineNumber, newLineNumber];
}

enum GitLineType {
  context,
  addition,
  deletion,
}

class GitCommit extends Equatable {
  final String hash;
  final String shortHash;
  final String author;
  final String email;
  final DateTime date;
  final String message;
  final List<String> parents;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.author,
    required this.email,
    required this.date,
    required this.message,
    required this.parents,
  });

  @override
  List<Object?> get props => [hash, shortHash, author, email, date, message, parents];
}

class GitCommitResult extends Equatable {
  final String hash;
  final String shortHash;
  final int filesChanged;
  final int insertions;
  final int deletions;

  const GitCommitResult({
    required this.hash,
    required this.shortHash,
    required this.filesChanged,
    required this.insertions,
    required this.deletions,
  });

  @override
  List<Object?> get props => [hash, shortHash, filesChanged, insertions, deletions];
}

class GitBranch extends Equatable {
  final String name;
  final bool isCurrent;
  final bool isRemote;
  final String? upstream;
  final String? lastCommitHash;

  const GitBranch({
    required this.name,
    required this.isCurrent,
    required this.isRemote,
    this.upstream,
    this.lastCommitHash,
  });

  @override
  List<Object?> get props => [name, isCurrent, isRemote, upstream, lastCommitHash];
}