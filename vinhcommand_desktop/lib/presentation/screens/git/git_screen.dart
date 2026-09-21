import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../application/vinhcommand_application.dart';
import '../../../core/vinhcommand_core.dart';

class GitScreen extends ConsumerStatefulWidget {
  const GitScreen({super.key});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> {
  String? selectedProjectId;
  final commitController = TextEditingController();
  bool busy = false;
  String? statusMessage;
  String? errorMessage;
  GitStatus? currentStatus;
  List<GitCommit> commits = [];
  GitDiff? currentDiff;

  @override
  void dispose() {
    commitController.dispose();
    super.dispose();
  }

  Future<void> _refreshGitInfo(String repoPath) async {
    setState(() {
      busy = true;
      errorMessage = null;
    });
    try {
      final git = ref.read(gitRepositoryProvider);
      final isRepo = await git.isRepo(repoPath);
      if (!isRepo) {
        setState(() {
          currentStatus = null;
          commits = [];
          currentDiff = null;
          busy = false;
        });
        return;
      }
      final status = await git.getStatus(repoPath);
      final logs = await git.getLog(repoPath, limit: 15);
      final diff = await git.getDiff(repoPath);
      if (mounted) {
        setState(() {
          currentStatus = status;
          commits = logs;
          currentDiff = diff;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = '$e';
          busy = false;
        });
      }
    }
  }

  Future<void> _pull(String repoPath) async {
    setState(() {
      busy = true;
      errorMessage = null;
      statusMessage = 'Đang kéo (Pull) cập nhật từ GitHub...';
    });
    try {
      final git = ref.read(gitRepositoryProvider);
      await git.pull(repoPath);
      await _refreshGitInfo(repoPath);
      if (mounted) {
        setState(() => statusMessage = 'Đã cập nhật mã nguồn mới nhất từ GitHub thành công!');
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Pull thất bại: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _push(String repoPath) async {
    setState(() {
      busy = true;
      errorMessage = null;
      statusMessage = 'Đang đẩy (Push) lên GitHub...';
    });
    try {
      final git = ref.read(gitRepositoryProvider);
      await git.push(repoPath);
      await _refreshGitInfo(repoPath);
      if (mounted) {
        setState(() => statusMessage = 'Đã đẩy lên GitHub thành công!');
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Push thất bại: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _commitAndPush(String repoPath) async {
    final msg = commitController.text.trim();
    if (msg.isEmpty) {
      setState(() => errorMessage = 'Vui lòng nhập nội dung Commit message');
      return;
    }
    setState(() {
      busy = true;
      errorMessage = null;
      statusMessage = 'Đang Commit và Push lên GitHub...';
    });
    try {
      final git = ref.read(gitRepositoryProvider);
      await git.commitAndPush(repoPath, msg);
      commitController.clear();
      await _refreshGitInfo(repoPath);
      if (mounted) {
        setState(() => statusMessage = 'Đã Commit và Push lên GitHub thành công!');
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Commit & Push thất bại: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _showCloneDialog() async {
    final urlController = TextEditingController();
    final tokenController = TextEditingController();
    String? destPath;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download_for_offline_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Tải dự án từ GitHub (Clone)'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nhập đường dẫn GitHub Repository (URL hoặc user/repo):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      hintText: 'https://github.com/owner/repo.git hoặc owner/repo',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Thư mục lưu trên máy:'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destPath ?? 'Chưa chọn thư mục lưu',
                          style: TextStyle(
                            color: destPath == null ? Colors.grey : null,
                            fontStyle: destPath == null ? FontStyle.italic : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Chọn'),
                        onPressed: () async {
                          final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Chọn thư mục lưu repository');
                          if (path != null) {
                            setDialogState(() => destPath = path);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('GitHub Token (Tùy chọn cho Private Repo):'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: tokenController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'ghp_xxxxxxxxxxxx (để trống nếu là Public Repo)',
                      prefixIcon: Icon(Icons.key),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_download),
              label: const Text('Bắt đầu tải (Clone)'),
              onPressed: () {
                if (urlController.text.trim().isEmpty || destPath == null) return;
                Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true && destPath != null && urlController.text.trim().isNotEmpty) {
      setState(() {
        busy = true;
        errorMessage = null;
        statusMessage = 'Đang tải (Clone) repository từ GitHub về máy...';
      });
      try {
        final git = ref.read(gitRepositoryProvider);
        final createdPath = await git.cloneRepo(
          urlController.text.trim(),
          destPath!,
          token: tokenController.text.trim().isEmpty ? null : tokenController.text.trim(),
        );
        // Add workspace & scan
        await ref.read(projectDiscoveryServiceProvider).addWorkspace(createdPath);
        await ref.read(projectDiscoveryServiceProvider).scanWorkspaces();
        ref.invalidate(projectsProvider);
        if (mounted) {
          setState(() {
            statusMessage = 'Tải repository thành công tại: $createdPath';
            busy = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            errorMessage = 'Clone thất bại: $e';
            busy = false;
          });
        }
      }
    }
  }

  Future<void> _showSetRemoteDialog(String repoPath) async {
    final remoteController = TextEditingController(text: currentStatus?.remoteUrl ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liên kết Remote GitHub (origin)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập URL GitHub Repository để liên kết:'),
            const SizedBox(height: 10),
            TextField(
              controller: remoteController,
              decoration: const InputDecoration(
                hintText: 'https://github.com/owner/repo.git',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu Remote')),
        ],
      ),
    );

    if (confirmed == true && remoteController.text.trim().isNotEmpty) {
      try {
        final git = ref.read(gitRepositoryProvider);
        await git.setRemoteUrl(repoPath, remoteController.text.trim());
        await _refreshGitInfo(repoPath);
        if (mounted) {
          setState(() => statusMessage = 'Đã liên kết Remote GitHub thành công!');
        }
      } catch (e) {
        if (mounted) setState(() => errorMessage = 'Lỗi cấu hình Remote: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];
    final selectedProject = projects.where((p) => p.id.value == selectedProjectId).firstOrNull ?? projects.firstOrNull;

    if (selectedProjectId == null && selectedProject != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => selectedProjectId = selectedProject.id.value);
          _refreshGitInfo(selectedProject.rootPath);
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Git & GitHub Command Center', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text('Quản lý liên kết GitHub, tải về (Clone/Pull) và đẩy lên (Commit/Push)'),
              ],
            ),
            FilledButton.icon(
              onPressed: busy ? null : _showCloneDialog,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Tải từ GitHub (Clone)'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (projects.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_open, size: 20),
                      const SizedBox(width: 10),
                      const Text('Chọn Dự án:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedProject?.id.value,
                          items: projects.map((p) => DropdownMenuItem(
                            value: p.id.value,
                            child: Text('${p.name} (${p.rootPath})', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (id) {
                            if (id == null) return;
                            setState(() => selectedProjectId = id);
                            final proj = projects.where((p) => p.id.value == id).firstOrNull;
                            if (proj != null) _refreshGitInfo(proj.rootPath);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Làm mới Git',
                        onPressed: selectedProject == null || busy ? null : () => _refreshGitInfo(selectedProject.rootPath),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (busy) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),

        if (statusMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(statusMessage!, style: const TextStyle(color: Colors.green))),
              ],
            ),
          ),

        if (errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),

        if (selectedProject == null)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('Chưa có dự án nào. Hãy bấm "Tải từ GitHub" hoặc thêm Workspace để bắt đầu.')),
          )
        else if (currentStatus == null && !busy)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 40, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text('${selectedProject.name} chưa phải là Git repository.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Khởi tạo Git (git init)'),
                    onPressed: () async {
                      final git = ref.read(gitRepositoryProvider);
                      await git.initRepo(selectedProject.rootPath);
                      await _refreshGitInfo(selectedProject.rootPath);
                    },
                  ),
                ],
              ),
            ),
          )
        else if (currentStatus != null) ...[
          // Overview Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.commit, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text('Branch: ${currentStatus!.currentBranch}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cloud_download, size: 16),
                            label: const Text('Pull từ GitHub'),
                            onPressed: busy ? null : () => _pull(selectedProject.rootPath),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.cloud_upload, size: 16),
                            label: const Text('Push lên GitHub'),
                            onPressed: busy ? null : () => _push(selectedProject.rootPath),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.link, size: 16),
                            label: const Text('Đổi Remote GitHub'),
                            onPressed: busy ? null : () => _showSetRemoteDialog(selectedProject.rootPath),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text('Remote GitHub: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: SelectableText(
                          currentStatus!.remoteUrl ?? 'Chưa liên kết remote (origin)',
                          style: TextStyle(color: currentStatus!.remoteUrl == null ? Colors.orange : null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _statusChip('Thay đổi', currentStatus!.totalChanges.toString(), currentStatus!.totalChanges > 0 ? Colors.orange : Colors.green),
                      _statusChip('Ahead (+)', currentStatus!.ahead.toString(), currentStatus!.ahead > 0 ? Colors.blue : Colors.grey),
                      _statusChip('Behind (-)', currentStatus!.behind.toString(), currentStatus!.behind > 0 ? Colors.red : Colors.grey),
                      _statusChip('Trạng thái', currentStatus!.isClean ? 'Sạch (Clean)' : 'Có thay đổi chưa commit', currentStatus!.isClean ? Colors.green : Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Commit & Push Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ĐẨY THAY ĐỔI LÊN GITHUB (COMMIT & PUSH)', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commitController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung Commit (Commit message)',
                      hintText: 'Ví dụ: Cập nhật tính năng AI Agent và giao diện mới...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Commit & Push lên GitHub'),
                        onPressed: busy ? null : () => _commitAndPush(selectedProject.rootPath),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Commits
          if (commits.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LỊCH SỬ COMMITS GẦN ĐÂY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    for (final commit in commits)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Chip(
                          label: Text(commit.shortHash, style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono')),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        title: Text(commit.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${commit.author} · ${commit.date.toLocal().toString().split('.').first}'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Diff / Changed files
          if (currentDiff != null && currentDiff!.files.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CÁC TỆP ĐÃ SỬA ĐỔI (${currentDiff!.files.length})', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    for (final f in currentDiff!.files)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          f.status == GitDiffStatus.added ? Icons.add_circle_outline : f.status == GitDiffStatus.deleted ? Icons.remove_circle_outline : Icons.edit_note,
                          color: f.status == GitDiffStatus.added ? Colors.green : f.status == GitDiffStatus.deleted ? Colors.red : Colors.orange,
                        ),
                        title: Text(f.path),
                        trailing: Text('+${f.additions} -${f.deletions}', style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono')),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}




