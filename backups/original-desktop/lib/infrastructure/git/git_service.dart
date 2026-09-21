import 'dart:io';
import 'package:path/path.dart' as p;
import '../../core/vinhcommand_core.dart';

class GitService implements GitRepository {
  @override
  Future<GitStatus> getStatus(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final statusProcess = await Process.run('git', ['status', '--porcelain'], workingDirectory: repoPath);
    final statusOutput = statusProcess.stdout.toString();

    final branchProcess = await Process.run('git', ['branch', '--show-current'], workingDirectory: repoPath);
    final branch = branchProcess.stdout.toString().trim();

    final remoteProcess = await Process.run('git', ['remote', 'get-url', 'origin'], workingDirectory: repoPath);
    final remoteUrl = remoteProcess.stdout.toString().trim();

    final aheadBehindProcess = await Process.run('git', ['rev-list', '--left-right', '--count', 'HEAD...@{u}'], workingDirectory: repoPath);
    int ahead = 0;
    int behind = 0;
    if (aheadBehindProcess.exitCode == 0) {
      final parts = aheadBehindProcess.stdout.toString().trim().split('\t');
      if (parts.length == 2) {
        ahead = int.tryParse(parts[0]) ?? 0;
        behind = int.tryParse(parts[1]) ?? 0;
      }
    }

    final staged = statusOutput.split('\n').where((l) => l.isNotEmpty && (l.startsWith('M') || l.startsWith('A') || l.startsWith('D') || l.startsWith('R'))).length;
    final unstaged = statusOutput.split('\n').where((l) => l.isNotEmpty && (l.startsWith(' M') || l.startsWith(' D') || l.startsWith('??'))).length;
    final untracked = statusOutput.split('\n').where((l) => l.startsWith('??')).length;

    return GitStatus(
      isClean: statusOutput.trim().isEmpty,
      stagedFiles: staged,
      unstagedFiles: unstaged,
      untrackedFiles: untracked,
      ahead: ahead,
      behind: behind,
      currentBranch: branch,
      remoteUrl: remoteUrl.isNotEmpty ? remoteUrl : null,
    );
  }

  @override
  Future<GitDiff> getDiff(String repoPath, {bool staged = false}) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final args = ['diff'];
    if (staged) args.add('--staged');
    args.add('--unified=3');

    final process = await Process.run('git', args, workingDirectory: repoPath);
    final output = process.stdout.toString();

    return _parseDiff(output);
  }

  GitDiff _parseDiff(String output) {
    final files = <GitFileDiff>[];
    int totalAdditions = 0;
    int totalDeletions = 0;

    final fileSections = output.split(RegExp(r'^diff --git ')).where((s) => s.isNotEmpty).toList();

    for (final section in fileSections) {
      final lines = section.split('\n');
      if (lines.isEmpty) continue;

      final header = lines[0];
      final pathMatch = RegExp(r'a/(.+) b/(.+)').firstMatch(header);
      String path = pathMatch?.group(2) ?? '';
      
      GitDiffStatus status = GitDiffStatus.modified;
      if (section.contains('new file mode')) status = GitDiffStatus.added;
      else if (section.contains('deleted file mode')) status = GitDiffStatus.deleted;
      else if (section.contains('rename from')) status = GitDiffStatus.renamed;

      final hunks = <GitHunk>[];
      int additions = 0;
      int deletions = 0;
      int i = 1;

      while (i < lines.length) {
        final line = lines[i];
        if (line.startsWith('@@')) {
          final hunkMatch = RegExp(r'@@ -(\d+),?(\d+)? \+(\d+),?(\d+)? @@').firstMatch(line);
          if (hunkMatch != null) {
            final oldStart = int.tryParse(hunkMatch.group(1)!) ?? 1;
            final oldLines = int.tryParse(hunkMatch.group(2) ?? '1') ?? 1;
            final newStart = int.tryParse(hunkMatch.group(3)!) ?? 1;
            final newLines = int.tryParse(hunkMatch.group(4) ?? '1') ?? 1;

            final hunkLines = <GitLine>[];
            int oldLineNum = oldStart;
            int newLineNum = newStart;
            i++;

            while (i < lines.length && !lines[i].startsWith('@@')) {
              final hunkLine = lines[i];
              if (hunkLine.startsWith('+')) {
                hunkLines.add(GitLine(
                  type: GitLineType.addition,
                  content: hunkLine.substring(1),
                  newLineNumber: newLineNum++,
                ));
                additions++;
              } else if (hunkLine.startsWith('-')) {
                hunkLines.add(GitLine(
                  type: GitLineType.deletion,
                  content: hunkLine.substring(1),
                  oldLineNumber: oldLineNum++,
                ));
                deletions++;
              } else {
                hunkLines.add(GitLine(
                  type: GitLineType.context,
                  content: hunkLine.substring(1),
                  oldLineNumber: oldLineNum++,
                  newLineNumber: newLineNum++,
                ));
              }
              i++;
            }

            hunks.add(GitHunk(
              oldStart: oldStart,
              oldLines: oldLines,
              newStart: newStart,
              newLines: newLines,
              lines: hunkLines,
            ));
            continue;
          }
        }
        i++;
      }

      totalAdditions += additions;
      totalDeletions += deletions;

      files.add(GitFileDiff(
        path: path,
        status: status,
        additions: additions,
        deletions: deletions,
        hunks: hunks,
      ));
    }

    return GitDiff(
      files: files,
      totalAdditions: totalAdditions,
      totalDeletions: totalDeletions,
    );
  }

  @override
  Future<List<GitCommit>> getLog(String repoPath, {int limit = 50}) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', [
      'log',
      '-n', limit.toString(),
      '--format=%H|%h|%an|%ae|%ai|%s|%P',
    ], workingDirectory: repoPath);

    final output = process.stdout.toString().trim();
    final commits = <GitCommit>[];

    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final parts = line.split('|');
      if (parts.length >= 6) {
        commits.add(GitCommit(
          hash: parts[0],
          shortHash: parts[1],
          author: parts[2],
          email: parts[3],
          date: DateTime.tryParse(parts[4]) ?? DateTime.now(),
          message: parts[5],
          parents: parts.length > 6 ? parts[6].split(' ') : [],
        ));
      }
    }

    return commits;
  }

  @override
  Future<List<GitBranch>> getBranches(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['branch', '-a', '--format=%(refname:short)|%(upstream:short)|%(objectname:short)'], workingDirectory: repoPath);
    final output = process.stdout.toString().trim();
    final branches = <GitBranch>[];

    final currentBranchProcess = await Process.run('git', ['branch', '--show-current'], workingDirectory: repoPath);
    final currentBranch = currentBranchProcess.stdout.toString().trim();

    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final parts = line.split('|');
      final name = parts[0];
      final isRemote = name.startsWith('remotes/');
      final cleanName = isRemote ? name.substring('remotes/'.length) : name;
      
      branches.add(GitBranch(
        name: cleanName,
        isCurrent: cleanName == currentBranch,
        isRemote: isRemote,
        upstream: parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        lastCommitHash: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
      ));
    }

    return branches;
  }

  @override
  Future<void> checkout(String repoPath, String branch) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['checkout', branch], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'CHECKOUT_FAILED',
        message: 'Failed to checkout branch: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> stage(String repoPath, List<String> files) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['add', ...files], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'STAGE_FAILED',
        message: 'Failed to stage files: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> unstage(String repoPath, List<String> files) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['reset', 'HEAD', ...files], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'UNSTAGE_FAILED',
        message: 'Failed to unstage files: ${process.stderr}',
      );
    }
  }

  @override
  Future<GitCommitResult> commit(String repoPath, String message) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['commit', '-m', message], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'COMMIT_FAILED',
        message: 'Failed to commit: ${process.stderr}',
      );
    }

    final hashProcess = await Process.run('git', ['rev-parse', 'HEAD'], workingDirectory: repoPath);
    final hash = hashProcess.stdout.toString().trim();

    final statsProcess = await Process.run('git', ['show', '--stat', '--format=', 'HEAD'], workingDirectory: repoPath);
    final stats = statsProcess.stdout.toString();
    
    int filesChanged = 0;
    int insertions = 0;
    int deletions = 0;
    
    final statsMatch = RegExp(r'(\d+) files? changed, (\d+) insertions?\(\+\), (\d+) deletions?\(-\)').firstMatch(stats);
    if (statsMatch != null) {
      filesChanged = int.tryParse(statsMatch.group(1)!) ?? 0;
      insertions = int.tryParse(statsMatch.group(2)!) ?? 0;
      deletions = int.tryParse(statsMatch.group(3)!) ?? 0;
    }

    return GitCommitResult(
      hash: hash,
      shortHash: hash.substring(0, 7),
      filesChanged: filesChanged,
      insertions: insertions,
      deletions: deletions,
    );
  }

  @override
  Future<void> stash(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['stash'], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'STASH_FAILED',
        message: 'Failed to stash: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> stashPop(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['stash', 'pop'], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'STASH_POP_FAILED',
        message: 'Failed to pop stash: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> pull(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['pull'], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'PULL_FAILED',
        message: 'Failed to pull: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> push(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['push'], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'PUSH_FAILED',
        message: 'Failed to push: ${process.stderr}',
      );
    }
  }

  @override
  Future<void> fetch(String repoPath) async {
    if (!await isRepo(repoPath)) {
      throw GitException(
        code: 'NOT_A_GIT_REPO',
        message: 'Not a git repository: $repoPath',
      );
    }

    final process = await Process.run('git', ['fetch'], workingDirectory: repoPath);
    if (process.exitCode != 0) {
      throw GitException(
        code: 'FETCH_FAILED',
        message: 'Failed to fetch: ${process.stderr}',
      );
    }
  }

  @override
  Future<bool> isRepo(String path) async {
    final gitDir = Directory(p.join(path, '.git'));
    return await gitDir.exists();
  }

  @override
  Future<String?> getRootPath(String path) async {
    try {
      final process = await Process.run('git', ['rev-parse', '--show-toplevel'], workingDirectory: path);
      if (process.exitCode == 0) {
        return process.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }
}


