import '../../../core/vinhcommand_core.dart' as model;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../application/vinhcommand_application.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});
  @override ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}
class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool busy = false;
  String query = '';
  String? error;
  Future<void> perform(Future<void> Function() action) async {
    setState(() { busy = true; error = null; });
    try { await action(); ref.invalidate(projectsProvider); ref.invalidate(tasksProvider); }
    catch(e) { if(mounted) setState(() => error = '$e'); }
    finally { if(mounted) setState(() => busy = false); }
  }
  Future<void> scan({bool add = false}) => perform(() async {
    final discovery = ref.read(projectDiscoveryServiceProvider);
    if(add) {
      final path = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Chọn thư mục dự án (Choose project folder)');
      if(path == null) return;
      await discovery.addWorkspace(path);
    }
    await discovery.scanWorkspaces();
  });
  Future<void> remove(model.Project project) async {
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text('Remove ${project.name}?'),
      content: SelectableText('Remove this project from VinhCommand and revoke its access. Queued tasks will be cancelled. Source files stay on disk.\n\n${project.rootPath}'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove project'))],
    ));
    if(approved == true && mounted) await perform(() => ref.read(projectRepositoryProvider).deleteProject(project.id));
  }
  Future<void> clearAll() async {
    final approved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa tất cả dự án?'),
      content: const Text('Hành động này sẽ xóa toàn bộ dự án khỏi danh sách của ứng dụng VinhCommand. Mã nguồn trên máy tính vẫn giữ nguyên.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Xóa tất cả'),
        )
      ],
    ));
    if(approved == true && mounted) {
      await perform(() async {
        final repo = ref.read(projectRepositoryProvider);
        final db = ref.read(databaseProvider);
        final current = await repo.getAllProjects();
        for(final p in current) {
          await repo.deleteProject(p.id);
        }
        await db.removeWhere('workspaces', (_) => true);
        await db.removeWhere('projects', (_) => true);
      });
    }
  }
  Future<void> cloneGitHub() async {
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
      await perform(() async {
        final git = ref.read(gitRepositoryProvider);
        final createdPath = await git.cloneRepo(
          urlController.text.trim(),
          destPath!,
          token: tokenController.text.trim().isEmpty ? null : tokenController.text.trim(),
        );
        await ref.read(projectDiscoveryServiceProvider).addWorkspace(createdPath);
        await ref.read(projectDiscoveryServiceProvider).scanWorkspaces();
      });
    }
  }

  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Text('1. Projects & permissions', style: Theme.of(context).textTheme.headlineSmall),
    const Text('Thêm thư mục dự án hoặc tải từ GitHub, sau đó cấp quyền Xem xét (Review) hoặc Chỉnh sửa (Edit) cho từng dự án.'),
    const SizedBox(height: 16),
    Wrap(spacing: 12, runSpacing: 12, children: [
      FilledButton.icon(
        onPressed: busy ? null : () => scan(add: true),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Add folder (Add project)'),
      ),
      FilledButton.tonalIcon(onPressed: busy ? null : cloneGitHub, icon: const Icon(Icons.cloud_download_outlined), label: const Text('Clone from GitHub')),
      OutlinedButton.icon(onPressed: busy ? null : scan, icon: const Icon(Icons.refresh), label: const Text('Rescan')),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
        onPressed: busy ? null : clearAll,
        icon: const Icon(Icons.delete_sweep_outlined),
        label: const Text('Xóa tất cả dự án'),
      ),
      if(ref.read(databaseProvider).rows('excluded_projects').isNotEmpty) TextButton(onPressed: busy ? null : () => perform(() async {
        await ref.read(databaseProvider).removeWhere('excluded_projects', (_) => true);
        await ref.read(projectDiscoveryServiceProvider).scanWorkspaces();
      }), child: const Text('Restore removed projects')),
    ]),
    const SizedBox(height: 16),
    TextField(decoration: const InputDecoration(labelText: 'Search projects', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => query = v.toLowerCase())),
    const SizedBox(height: 16),
    if(busy) const LinearProgressIndicator(),
    if(error != null) Semantics(liveRegion: true, child: Text('Project error: $error')),
    ref.watch(projectsProvider).when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e'), data: (projects) {
      final visible = projects.where((p) => '${p.name} ${p.rootPath}'.toLowerCase().contains(query)).toList();
      if(visible.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Text('Chưa có dự án nào. Nhấn "Add folder (Add project)" hoặc "Clone from GitHub" để bắt đầu.'));
      return LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final project = visible[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_open, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(project.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SelectableText(project.rootPath, maxLines: 1, style: const TextStyle(fontSize: 11)),
                        Text('Branch: ${project.branch ?? "No Git branch"}', style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final currentMode = ref.read(projectAccessProvider).mode(project.id.value);
                        final safeMode = ['denied', 'read-only', 'workspace-write'].contains(currentMode) ? currentMode : 'denied';
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButton<String>(
                              key: ValueKey('access-${project.id.value}-$safeMode'),
                              isDense: true,
                              value: safeMode,
                              items: const [
                                DropdownMenuItem(value: 'denied', child: Text('Not authorized', style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'read-only', child: Text('Review only', style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'workspace-write', child: Text('Edit + approvals', style: TextStyle(fontSize: 11))),
                              ],
                              onChanged: busy ? null : (mode) {
                                if(mode == null) return;
                                perform(() async {
                                  final access = ref.read(projectAccessProvider);
                                  if(mode == 'denied') {
                                    final tasks = await ref.read(taskRepositoryProvider).getTasksByProject(project.id);
                                    for(final task in tasks.where((t) => !t.isTerminal)) { await ref.read(taskManagerProvider).stopTask(task.id); }
                                    await access.revoke(project.id.value);
                                  } else {
                                    await access.grant(project.id.value, project.rootPath, mode);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'Remove project',
                              iconSize: 18,
                              onPressed: busy ? null : () => remove(project),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            );
          },
        );
      });
    }),
  ]);
}
