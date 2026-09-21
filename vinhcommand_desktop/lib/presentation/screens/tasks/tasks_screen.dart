import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/vinhcommand_application.dart';
import '../../../core/vinhcommand_core.dart' as model;

class TasksScreen extends ConsumerStatefulWidget {
  final bool approvalsOnly;
  const TasksScreen({super.key, this.approvalsOnly = false});
  @override ConsumerState<TasksScreen> createState() => _TasksScreenState();
}
class _TasksScreenState extends ConsumerState<TasksScreen> {
  final prompt = TextEditingController();
  String? projectId, agentId, error, parentId;
  String permission = 'read-only';
  String opencodeProviderId = 'zenmux';
  String opencodeModelId = 'zenmux/z-ai/glm-4.6v-flash-free';
  model.Task? _minimizedTask;
  model.Project? _minimizedProject;
  bool busy = false;
  Timer? timer;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 2), (_) { ref.invalidate(tasksProvider); }); }
  @override void dispose() { timer?.cancel(); prompt.dispose(); super.dispose(); }
  Future<void> action(Future<void> Function() work) async {
    try { await work(); if(mounted) { ref.invalidate(tasksProvider); setState(() => error = null); } }
    catch(e) { if(mounted) setState(() => error = '$e'); }
  }
  Future<void> create() async {
    if(projectId == null || agentId == null || prompt.text.trim().isEmpty) { setState(() => error = 'Select project, agent and enter a task'); return; }
    setState(() => busy = true);
    model.Task? createdTask;
    await action(() async {
      final access = ref.read(projectAccessProvider);
      final currentMode = access.mode(projectId!);
      if (currentMode == 'denied') {
        final project = await ref.read(projectRepositoryProvider).getProjectById(model.ProjectId(projectId!));
        if (project != null) {
          await access.grant(projectId!, project.rootPath, 'workspace-write');
        }
      }
      final allAgents = ref.read(agentsProvider).valueOrNull ?? [];
      final currentAgent = allAgents.where((a) => a.id.value == agentId).firstOrNull;
      final isOpencode = currentAgent?.name.toLowerCase().contains('opencode') == true ||
          agentId?.toLowerCase().contains('opencode') == true;
      final task = await ref.read(taskManagerProvider).createTask(
        projectId: model.ProjectId(projectId!),
        agentId: model.AgentId(agentId!),
        prompt: prompt.text,
        permission: permission,
        executionMode: 'manual',
        metadata: {
          if(parentId != null) 'parentTaskId': parentId,
          if(isOpencode) 'opencodeModel': opencodeModelId,
          if(isOpencode) 'opencodeProvider': opencodeProviderId,
        },
      );
      createdTask = task;
      unawaited(ref.read(taskManagerProvider).startTask(task.id));
      prompt.clear();
      parentId = null;
    });
    if(mounted) {
      setState(() => busy = false);
      if (createdTask != null) {
        showFloatingAiScreen(createdTask!);
      }
    }
  }

  Future<void> output(model.Task task) => showFloatingAiScreen(task);

  Future<void> showFloatingAiScreen(model.Task task, [model.Project? project]) async {
    if(!mounted) return;
    setState(() => _minimizedTask = null);
    final projects = ref.read(projectsProvider).valueOrNull ?? [];
    final prj = project ?? projects.where((p) => p.id.value == task.projectId.value).firstOrNull;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LargeFloatingAiWorkspaceDialog(
        taskId: task.id,
        initialPrompt: task.prompt,
        projectId: task.projectId.value,
        project: prj,
        taskManager: ref.read(taskManagerProvider),
        taskRepo: ref.read(taskRepositoryProvider),
        onMinimize: () {
          if (mounted) {
            setState(() {
              _minimizedTask = task;
              _minimizedProject = prj;
            });
          }
        },
      ),
    );
  }
  @override Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider).valueOrNull ?? [];
    final allAgents = ref.watch(agentsProvider).valueOrNull ?? [];
    final availableAgents = allAgents.where((a) => a.isAvailable).toList();
    final agents = availableAgents.isNotEmpty ? availableAgents : allAgents;

    final effectiveProjectId = (projectId != null && projects.any((p) => p.id.value == projectId))
        ? projectId
        : (projects.isNotEmpty ? projects.first.id.value : null);
    final effectiveAgentId = (agentId != null && agents.any((a) => a.id.value == agentId))
        ? agentId
        : (agents.isNotEmpty ? agents.first.id.value : null);

    if (projectId != effectiveProjectId) projectId = effectiveProjectId;
    if (agentId != effectiveAgentId) agentId = effectiveAgentId;

    final selected = projects.where((p) => p.id.value == projectId).firstOrNull;
    final validProject = selected != null;
    final validAgent = agents.any((a) => a.id.value == agentId);
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(widget.approvalsOnly ? '6. Approvals' : '4. Tasks & results', style: Theme.of(context).textTheme.headlineSmall),
            if(!widget.approvalsOnly) ...[
              const Text('Choose a project and agent, confirm access, then queue the task. Review mode cannot edit files.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('project-$projectId-$validProject'),
                value: validProject ? projectId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Project'),
                items: projects.map((p) => DropdownMenuItem(value: p.id.value, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => projectId = v),
              ),
              if(selected != null) Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: SelectableText('${selected.rootPath}\nBranch: ${selected.branch ?? "No Git branch"}\nAccess: ${ref.read(projectAccessProvider).mode(selected.id.value)}')),
                    if (ref.read(projectAccessProvider).mode(selected.id.value) == 'denied')
                      FilledButton.tonal(
                        onPressed: () async {
                          await ref.read(projectAccessProvider).grant(selected.id.value, selected.rootPath, 'workspace-write');
                          setState(() {});
                        },
                        child: const Text('Authorize Access'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('agent-$agentId-${agents.length}'),
                value: validAgent ? agentId : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'AI Agent Engine'),
                items: agents.map((a) => DropdownMenuItem(value: a.id.value, child: Text('${a.name} (${a.version})', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => agentId = v),
              ),
              if (agents.where((a) => a.id.value == agentId).firstOrNull?.name.toLowerCase().contains('opencode') == true || agentId?.toLowerCase().contains('opencode') == true) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('opencode-provider-$opencodeProviderId'),
                  value: opencodeProviderId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenCode Provider',
                    helperText: 'Select provider gateway (Free models available)',
                  ),
                  items: model.kDefaultOpencodeProviders.map((prov) => DropdownMenuItem(
                    value: prov.id,
                    child: Row(
                      children: [
                        Text(prov.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('FREE AVAILABLE', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        opencodeProviderId = v;
                        final models = model.kDefaultOpencodeModels.where((m) => m.providerId == v).toList();
                        final freeFirst = models.where((m) => m.isFree).toList();
                        opencodeModelId = freeFirst.isNotEmpty ? freeFirst.first.id : (models.isNotEmpty ? models.first.id : '');
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final providerModels = model.kDefaultOpencodeModels.where((m) => m.providerId == opencodeProviderId).toList();
                    providerModels.sort((a, b) {
                      if (a.isFree && !b.isFree) return -1;
                      if (!a.isFree && b.isFree) return 1;
                      return a.displayName.compareTo(b.displayName);
                    });
                    final validModel = providerModels.any((m) => m.id == opencodeModelId);
                    final effectiveModel = validModel ? opencodeModelId : (providerModels.isNotEmpty ? providerModels.first.id : null);
                    return DropdownButtonFormField<String>(
                      key: ValueKey('opencode-model-$opencodeProviderId-$effectiveModel'),
                      value: effectiveModel,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'OpenCode Model (Free Prioritized)',
                        helperText: 'Free models are highlighted and prioritized at the top',
                      ),
                      items: providerModels.map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Row(
                          children: [
                            if (m.isFree) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text('FREE', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                m.displayName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: m.isFree ? const Color(0xFF4ADE80) : null,
                                  fontWeight: m.isFree ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => opencodeModelId = v);
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('permission-$permission'),
                initialValue: ['read-only', 'workspace-write'].contains(permission) ? permission : 'workspace-write',
                decoration: const InputDecoration(labelText: 'Task access'),
                items: const [
                  DropdownMenuItem(value: 'workspace-write', child: Text('Edit project + request approvals')),
                  DropdownMenuItem(value: 'read-only', child: Text('Review only')),
                ],
                onChanged: (v) => setState(() => permission = v ?? 'workspace-write'),
              ),
              if(parentId != null) Text('Follow-up to task $parentId (new agent session)'),
              TextField(controller: prompt, maxLines: 4, maxLength: 20000, decoration: const InputDecoration(labelText: 'Task instructions')),
              FilledButton(onPressed: busy || !validProject || !validAgent ? null : create, child: const Text('Queue task')),
              const SizedBox(height: 20),
            ],
            if(error != null) Semantics(liveRegion: true, child: Text('Task error: $error')),
            ref.watch(tasksProvider).when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (tasks) {
                final sorted = List.of(tasks)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final visible = sorted.where((task) => !widget.approvalsOnly || task.state == model.TaskState.waitingForApproval || task.state == model.TaskState.queued).toList();
                if(visible.isEmpty) return const Text('No tasks in this view.');

                // Group by project: 1 Master Task per project
                final Map<String, List<model.Task>> grouped = {};
                for (final t in visible) {
                  grouped.putIfAbsent(t.projectId.value, () => []).add(t);
                }

                return Column(
                  children: grouped.entries.map((entry) {
                    final pid = entry.key;
                    final taskList = entry.value;
                    final masterTask = taskList.first;
                    final project = projects.where((p) => p.id.value == pid).firstOrNull;
                    final approval = masterTask.metadata['approval'] as Map?;
                    final failedTests = masterTask.metadata['testStatus'] == 'failed';
                    final statusLabel = masterTask.state == model.TaskState.starting
                        ? 'VALIDATING'
                        : masterTask.state == model.TaskState.completed && failedTests
                            ? 'COMPLETED WITH TEST FAILURES'
                            : masterTask.state.label;
                    final timeStr = '${masterTask.createdAt.hour.toString().padLeft(2, '0')}:${masterTask.createdAt.minute.toString().padLeft(2, '0')}:${masterTask.createdAt.second.toString().padLeft(2, '0')}';

                    Color statusColor;
                    switch(masterTask.state) {
                      case model.TaskState.completed: statusColor = const Color(0xFF4ADE80); break;
                      case model.TaskState.failed: statusColor = const Color(0xFFEF4444); break;
                      case model.TaskState.running: statusColor = const Color(0xFF3B82F6); break;
                      case model.TaskState.waitingForApproval: statusColor = const Color(0xFFF59E0B); break;
                      default: statusColor = const Color(0xFF9CA3AF);
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: statusColor.withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A7C59).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.folder_open, color: Color(0xFF4ADE80), size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      project?.name ?? pid,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${taskList.length} session${taskList.length > 1 ? 's' : ''}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (project != null)
                              Text('Path: ${project.rootPath}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14171A),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF2B3038)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.psychology, size: 16, color: Color(0xFF4ADE80)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      masterTask.prompt,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFFE2E4E9)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (masterTask.error != null) ...[
                              const SizedBox(height: 4),
                              Text(masterTask.error!, style: const TextStyle(fontSize: 11, color: Colors.redAccent), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            if (approval != null) ...[
                              const Divider(height: 12),
                              const Text('Approval required', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
                              SelectableText('${approval['details']}', style: const TextStyle(fontSize: 11)),
                              Row(
                                children: [
                                  FilledButton.tonal(onPressed: () => action(() => ref.read(taskManagerProvider).respondApproval(masterTask.id, approval['id'] as String, true)), child: const Text('Approve')),
                                  const SizedBox(width: 8),
                                  OutlinedButton(onPressed: () => action(() => ref.read(taskManagerProvider).respondApproval(masterTask.id, approval['id'] as String, false)), child: const Text('Deny')),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Master Task #${masterTask.id.value.length > 8 ? masterTask.id.value.substring(0, 8) : masterTask.id.value}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                Row(
                                  children: [
                                    if (masterTask.state == model.TaskState.queued)
                                      FilledButton(onPressed: () => action(() => ref.read(taskManagerProvider).startTask(masterTask.id)), child: const Text('Run')),
                                    if (masterTask.isTerminal)
                                      FilledButton.tonal(onPressed: () => action(() => ref.read(taskManagerProvider).retryTask(masterTask.id)), child: const Text('Re-run')),
                                    if (!masterTask.isTerminal)
                                      TextButton(onPressed: () => action(() => ref.read(taskManagerProvider).stopTask(masterTask.id)), child: const Text('Stop')),
                                    const SizedBox(width: 6),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4A7C59)),
                                      onPressed: () => showFloatingAiScreen(masterTask, project),
                                      icon: const Icon(Icons.open_in_new, size: 16),
                                      label: const Text('Open AI Workspace'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        if (_minimizedTask != null)
          Positioned(
            bottom: 24,
            right: 24,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(30),
              color: const Color(0xFF1B1E23),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  final t = _minimizedTask!;
                  final p = _minimizedProject;
                  setState(() => _minimizedTask = null);
                  showFloatingAiScreen(t, p);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _minimizedTask!.isActive ? const Color(0xFF3B82F6) : const Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.psychology, color: Color(0xFF4ADE80), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _minimizedProject?.name ?? "AI Task",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _minimizedTask = null),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LargeFloatingAiWorkspaceDialog extends StatefulWidget {
  final model.TaskId taskId;
  final String initialPrompt;
  final String projectId;
  final model.Project? project;
  final TaskManager taskManager;
  final model.TaskRepository taskRepo;
  final VoidCallback onMinimize;

  const _LargeFloatingAiWorkspaceDialog({
    required this.taskId,
    required this.initialPrompt,
    required this.projectId,
    this.project,
    required this.taskManager,
    required this.taskRepo,
    required this.onMinimize,
  });

  @override
  State<_LargeFloatingAiWorkspaceDialog> createState() => _LargeFloatingAiWorkspaceDialogState();
}

class SubService {
  final String name;
  final String command;
  final String? workingDir;
  final int? port;
  final String? webUrl;
  final List<Map<String, String>>? additionalUrls;

  const SubService({
    required this.name,
    required this.command,
    this.workingDir,
    this.port,
    this.webUrl,
    this.additionalUrls,
  });
}

class ProjectRunner {
  final String name;
  final String command;
  final String description;
  final bool isPrimary;
  final int? port;
  final String? webUrl;
  final bool isMobile;
  final String? workingDir;
  final List<SubService>? services;
  final List<Map<String, String>>? webLinks;

  const ProjectRunner({
    required this.name,
    required this.command,
    required this.description,
    this.isPrimary = false,
    this.port,
    this.webUrl,
    this.isMobile = false,
    this.workingDir,
    this.services,
    this.webLinks,
  });
}

class _FileTreeNode {
  final String path;
  final String name;
  final bool isDirectory;
  final int depth;
  bool isExpanded;
  List<_FileTreeNode>? children;

  _FileTreeNode({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.depth,
    this.isExpanded = false,
    this.children,
  });
}

class _SyntaxHighlightingController extends TextEditingController {
  _SyntaxHighlightingController({super.text});

  static final _commentRegex = RegExp(r'(//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/)');
  static final _stringRegex = RegExp(r'("""[\s\S]*?"""|' r"'''[\s\S]*?'''|" r'"[^"\\]*(\\.[^"\\]*)*"|' r"'[^'\\]*(\\.[^'\\]*)*')");
  static final _keywordRegex = RegExp(r'\b(def|class|return|if|elif|else|while|for|in|import|from|as|try|except|finally|raise|with|lambda|pass|break|continue|async|await|const|final|var|let|function|interface|type|public|private|protected|static|void|int|double|bool|String|List|Map|Set|new|throw|catch|true|false|None|null|nil)\b');
  static final _numberRegex = RegExp(r'\b\d+(\.\d+)?\b');
  static final _functionCallRegex = RegExp(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()');
  static final _typeRegex = RegExp(r'\b[A-Z][a-zA-Z0-9_]*\b');
  static final _decoratorRegex = RegExp(r'@[a-zA-Z0-9_.]+');

  static final _combinedRegex = RegExp(
    '(${_commentRegex.pattern})|'
    '(${_stringRegex.pattern})|'
    '(${_keywordRegex.pattern})|'
    '(${_functionCallRegex.pattern})|'
    '(${_typeRegex.pattern})|'
    '(${_numberRegex.pattern})|'
    '(${_decoratorRegex.pattern})',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final text = this.text;
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final defaultStyle = style ?? const TextStyle(fontFamily: 'Consolas', fontSize: 12.5, color: Color(0xFFD4D4D4), height: 1.45);
    final spans = <InlineSpan>[];

    int lastMatchEnd = 0;
    for (final match in _combinedRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      final matchedText = match.group(0)!;
      TextStyle tokenStyle = defaultStyle;

      if (_commentRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFF6A9955), fontStyle: FontStyle.italic);
      } else if (_stringRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFFCE9178));
      } else if (_keywordRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFFC586C0), fontWeight: FontWeight.bold);
      } else if (_decoratorRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFFFFD700));
      } else if (_typeRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFF4EC9B0));
      } else if (_numberRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFFB5CEA8));
      } else if (_functionCallRegex.hasMatch(matchedText)) {
        tokenStyle = defaultStyle.copyWith(color: const Color(0xFFDCDCAA));
      }

      spans.add(TextSpan(text: matchedText, style: tokenStyle));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans, style: defaultStyle);
  }
}

class _LargeFloatingAiWorkspaceDialogState extends State<_LargeFloatingAiWorkspaceDialog> {
  final List<String> _logs = [];
  model.Task? _task;
  late model.TaskId _activeTaskId;
  StreamSubscription<model.TaskLog>? _subscription;
  Timer? _poller;
  bool _isFinished = false;

  // Resizing state
  double _chatWidth = 420.0;
  double _explorerWidth = 230.0;
  double _codeFontSize = 12.5;

  // Follow-up task input
  final TextEditingController _followUpController = TextEditingController();
  bool _isSendingFollowUp = false;

  // File tree explorer & code editor
  List<_FileTreeNode> _rootTreeNodes = [];
  File? _selectedFile;
  final _SyntaxHighlightingController _codeController = _SyntaxHighlightingController();
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();
  bool _isDirty = false;
  String? _saveMessage;

  // Runner processes
  final List<Process> _runningProcesses = [];
  bool _isRunningProject = false;
  final List<String> _runnerLogs = [];
  final TextEditingController _runnerInputController = TextEditingController();
  final ScrollController _runnerScrollController = ScrollController();
  final List<Map<String, String>> _activeWebLinks = [];
  ProjectRunner? _activeRunner;

  void _scrollToBottomRunnerLogs() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_runnerScrollController.hasClients) {
        _runnerScrollController.animateTo(
          _runnerScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _detectDynamicUrl(String line, [String? serviceTag]) {
    final urlRegex = RegExp(r'https?://(localhost|127\.0\.0\.1|0\.0\.0\.0):([0-9]{2,5})');
    final match = urlRegex.firstMatch(line);
    if (match != null) {
      final port = match.group(2);
      final url = 'http://127.0.0.1:$port';
      if (!_activeWebLinks.any((item) => item['url'] == url)) {
        final label = (serviceTag != null && serviceTag.isNotEmpty && serviceTag != 'App')
            ? '$serviceTag (Port $port)'
            : 'Web (Port $port)';
        _activeWebLinks.add({'label': label, 'url': url});
      }
    }
  }

  void _sendRunnerInput() {
    final text = _runnerInputController.text;
    if (_runningProcesses.isNotEmpty) {
      try {
        for (final proc in _runningProcesses) {
          try { proc.stdin.writeln(text); } catch (_) {}
        }
        setState(() {
          _runnerLogs.add('> $text');
        });
        _runnerInputController.clear();
        _scrollToBottomRunnerLogs();
      } catch (e) {
        setState(() {
          _runnerLogs.add('[ERR] Không thể gửi input: $e');
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _activeTaskId = widget.taskId;
    _loadInitial();
    _loadProjectFiles();
    _listenToTask(_activeTaskId);
    _poller = Timer.periodic(const Duration(milliseconds: 500), (_) => _checkStatus());

    _codeScrollController.addListener(() {
      if (_lineScrollController.hasClients && _lineScrollController.offset != _codeScrollController.offset) {
        _lineScrollController.jumpTo(_codeScrollController.offset);
      }
    });
  }

  void _listenToTask(model.TaskId id) {
    _subscription?.cancel();
    _subscription = widget.taskManager.getTaskLogStream(id).listen((log) {
      if (mounted) {
        setState(() {
          _logs.add(log.message);
        });
      }
    });
  }

  Future<void> _loadInitial() async {
    final existingLogs = await widget.taskRepo.getTaskLogs(_activeTaskId);
    final currentTask = await widget.taskManager.getTask(_activeTaskId);
    if (mounted) {
      setState(() {
        _logs.addAll(existingLogs.map((l) => l.message));
        _task = currentTask;
        if (currentTask != null && currentTask.isTerminal) {
          _isFinished = true;
          _poller?.cancel();
        }
      });
    }
  }

  Future<void> _checkStatus() async {
    final currentTask = await widget.taskManager.getTask(_activeTaskId);
    if (currentTask != null && mounted) {
      setState(() {
        _task = currentTask;
        if (currentTask.isTerminal) {
          _isFinished = true;
          _poller?.cancel();
        }
      });
    }
  }

  List<_FileTreeNode> _loadDirectoryNodes(String dirPath, int depth) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    try {
      final entries = dir.listSync().where((e) {
        final name = e.path.split(RegExp(r'[\\/]')).last;
        return !name.startsWith('.') &&
            name != 'node_modules' &&
            name != 'build' &&
            name != '.git' &&
            name != '__pycache__' &&
            name != '.dart_tool' &&
            name != 'target';
      }).toList();
      entries.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir && !bDir) return -1;
        if (!aDir && bDir) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      return entries.map((e) {
        final isDir = e is Directory;
        final name = e.path.split(RegExp(r'[\\/]')).last;
        return _FileTreeNode(
          path: e.path,
          name: name,
          isDirectory: isDir,
          depth: depth,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _loadProjectFiles() {
    final root = widget.project?.rootPath ?? '';
    if (root.isNotEmpty && Directory(root).existsSync()) {
      final nodes = _loadDirectoryNodes(root, 0);
      setState(() {
        _rootTreeNodes = nodes;
        if (_selectedFile == null) {
          final first = _findFirstFile(nodes);
          if (first != null) _selectFile(File(first.path));
        }
      });
    }
  }

  _FileTreeNode? _findFirstFile(List<_FileTreeNode> nodes) {
    for (final node in nodes) {
      if (!node.isDirectory) return node;
      if (node.children != null) {
        final f = _findFirstFile(node.children!);
        if (f != null) return f;
      }
    }
    return null;
  }

  void _toggleFolder(_FileTreeNode node) {
    setState(() {
      if (node.isExpanded) {
        node.isExpanded = false;
      } else {
        if (node.children == null) {
          node.children = _loadDirectoryNodes(node.path, node.depth + 1);
        }
        node.isExpanded = true;
      }
    });
  }

  List<_FileTreeNode> _flattenTree(List<_FileTreeNode> nodes) {
    final result = <_FileTreeNode>[];
    for (final node in nodes) {
      result.add(node);
      if (node.isDirectory && node.isExpanded && node.children != null) {
        result.addAll(_flattenTree(node.children!));
      }
    }
    return result;
  }

  String _getFileLanguage(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return 'Dart';
      case 'py':
        return 'Python';
      case 'js':
      case 'jsx':
        return 'JavaScript';
      case 'ts':
      case 'tsx':
        return 'TypeScript';
      case 'json':
        return 'JSON';
      case 'html':
        return 'HTML';
      case 'css':
        return 'CSS';
      case 'md':
        return 'Markdown';
      case 'yaml':
      case 'yml':
        return 'YAML';
      case 'cpp':
      case 'c':
      case 'h':
        return 'C/C++';
      case 'java':
        return 'Java';
      case 'kt':
        return 'Kotlin';
      case 'bat':
      case 'cmd':
        return 'Batch';
      case 'ps1':
        return 'PowerShell';
      case 'sh':
        return 'Shell';
      default:
        return 'Plain Text';
    }
  }

  Widget _getFileIcon(String name, bool isDirectory, bool isExpanded) {
    if (isDirectory) {
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        size: 16,
        color: const Color(0xFFDCDCAA),
      );
    }
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'dart':
        return const Icon(Icons.flutter_dash, size: 15, color: Color(0xFF40C4FF));
      case 'py':
        return const Icon(Icons.code, size: 15, color: Color(0xFFFFD54F));
      case 'js':
      case 'jsx':
        return const Icon(Icons.javascript, size: 16, color: Color(0xFFFFCA28));
      case 'ts':
      case 'tsx':
        return const Icon(Icons.code, size: 15, color: Color(0xFF42A5F5));
      case 'json':
        return const Icon(Icons.data_object, size: 15, color: Color(0xFFFFF176));
      case 'html':
        return const Icon(Icons.html, size: 16, color: Color(0xFFFF7043));
      case 'css':
        return const Icon(Icons.css, size: 16, color: Color(0xFF29B6F6));
      case 'md':
        return const Icon(Icons.menu_book, size: 15, color: Color(0xFF81D4FA));
      case 'yaml':
      case 'yml':
        return const Icon(Icons.settings, size: 15, color: Color(0xFFFF8A65));
      case 'bat':
      case 'sh':
      case 'ps1':
        return const Icon(Icons.terminal, size: 15, color: Color(0xFF81C784));
      default:
        return const Icon(Icons.description, size: 15, color: Color(0xFF90A4AE));
    }
  }

  void _selectFile(File file) {
    try {
      final content = file.readAsStringSync();
      setState(() {
        _selectedFile = file;
        _codeController.text = content;
        _isDirty = false;
        _saveMessage = null;
      });
    } catch (e) {
      setState(() {
        _selectedFile = file;
        _codeController.text = 'Could not load text: $e';
        _isDirty = false;
      });
    }
  }

  void _saveCurrentFile() {
    if (_selectedFile == null) return;
    try {
      _selectedFile!.writeAsStringSync(_codeController.text);
      setState(() {
        _isDirty = false;
        _saveMessage = 'Saved changes to PC!';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _saveMessage = null);
      });
    } catch (e) {
      setState(() => _saveMessage = 'Error saving: $e');
    }
  }

  Future<void> _sendFollowUp() async {
    final text = _followUpController.text.trim();
    if (text.isEmpty || _isSendingFollowUp) return;
    setState(() => _isSendingFollowUp = true);

    try {
      final currentTask = _task ?? await widget.taskRepo.getTaskById(_activeTaskId);
      final newTask = await widget.taskManager.createTask(
        projectId: currentTask?.projectId ?? model.ProjectId(widget.projectId),
        agentId: currentTask?.agentId ?? model.AgentId('opencode'),
        prompt: text,
        permission: currentTask?.permission ?? 'workspace-write',
        executionMode: 'manual',
        metadata: {
          'parentTaskId': _activeTaskId.value,
          if (currentTask?.metadata['opencodeModel'] != null) 'opencodeModel': currentTask!.metadata['opencodeModel'],
          if (currentTask?.metadata['opencodeProvider'] != null) 'opencodeProvider': currentTask!.metadata['opencodeProvider'],
        },
      );

      _followUpController.clear();
      await widget.taskManager.startTask(newTask.id);

      setState(() {
        _activeTaskId = newTask.id;
        _task = newTask;
        _isFinished = false;
        _logs.add('\n=== FOLLOW-UP TASK: "$text" ===\n');
      });

      _listenToTask(newTask.id);
      _poller?.cancel();
      _poller = Timer.periodic(const Duration(milliseconds: 500), (_) => _checkStatus());
    } finally {
      if (mounted) setState(() => _isSendingFollowUp = false);
    }
  }

  List<String> _detectInstallCommands() {
    final root = widget.project?.rootPath ?? '';
    final list = <String>[];
    if (root.isEmpty) return list;

    if (File('$root/requirements.txt').existsSync() || File('$root\\requirements.txt').existsSync()) {
      list.add('pip install -r requirements.txt');
    }
    if (File('$root/package.json').existsSync() || File('$root\\package.json').existsSync()) {
      list.add('npm install');
    }
    if (File('$root/pubspec.yaml').existsSync() || File('$root\\pubspec.yaml').existsSync()) {
      list.add('flutter pub get');
    }
    if (File('$root/Pipfile').existsSync() || File('$root\\Pipfile').existsSync()) {
      list.add('pipenv install');
    }
    if (File('$root/Cargo.toml').existsSync() || File('$root\\Cargo.toml').existsSync()) {
      list.add('cargo build');
    }

    final allText = _logs.join('\n');
    final pipRegex = RegExp(r'(pip install [a-zA-Z0-9_\-==<>\.]+)');
    for (final m in pipRegex.allMatches(allText)) {
      final cmd = m.group(1)!.trim();
      if (!list.contains(cmd)) list.add(cmd);
    }
    final npmRegex = RegExp(r'(npm install [a-zA-Z0-9_\-@/]+)');
    for (final m in npmRegex.allMatches(allText)) {
      final cmd = m.group(1)!.trim();
      if (!list.contains(cmd)) list.add(cmd);
    }

    if (list.isEmpty) {
      if (File('$root/main.py').existsSync() || File('$root\\main.py').existsSync()) {
        list.add('python -m pip install --upgrade pip');
      }
    }
    return list;
  }

  Future<void> _runInstallCommands(List<String> commands) async {
    if (commands.isEmpty) return;
    final root = widget.project?.rootPath ?? '';
    if (root.isEmpty) return;

    final compositeCmd = commands.join(' && ');

    setState(() {
      _isRunningProject = true;
      _runnerLogs.add('\n======================================================');
      _runnerLogs.add('[START] BẮT ĐẦU TỰ ĐỘNG CÀI ĐẶT TÀI NGUYÊN & MÔI TRƯỜNG DỰ ÁN:');
      for (final c in commands) {
        _runnerLogs.add('  > $c');
      }
      _runnerLogs.add('======================================================\n');
    });

    try {
      final proc = await Process.start(
        'cmd.exe',
        ['/c', 'chcp 65001 >nul && $compositeCmd'],
        workingDirectory: root,
        mode: ProcessStartMode.normal,
        environment: {
          ...Platform.environment,
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
          'LANG': 'en_US.UTF-8',
        },
      );
      _runningProcesses.add(proc);

      proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        if (mounted) {
          setState(() {
            for (final line in data.split('\n')) {
              if (line.trim().isNotEmpty) _runnerLogs.add(line.trim());
            }
            if (_runnerLogs.length > 500) _runnerLogs.removeRange(0, _runnerLogs.length - 500);
          });
          _scrollToBottomRunnerLogs();
        }
      });

      proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        if (mounted) {
          setState(() {
            for (final line in data.split('\n')) {
              if (line.trim().isNotEmpty) _runnerLogs.add('[ERR] ${line.trim()}');
            }
            if (_runnerLogs.length > 500) _runnerLogs.removeRange(0, _runnerLogs.length - 500);
          });
          _scrollToBottomRunnerLogs();
        }
      });

      proc.exitCode.then((code) {
        if (mounted) {
          _runningProcesses.remove(proc);
          setState(() {
            _isRunningProject = false;
            _runnerLogs.add('\n[OK] Hoàn thành cài đặt tài nguyên (Mã thoát: $code).');
          });
          _scrollToBottomRunnerLogs();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunningProject = false;
          _runnerLogs.add('Lỗi cài đặt tài nguyên: $e');
        });
        _scrollToBottomRunnerLogs();
      }
    }
  }

  String? _findBlueStacksPath() {
    final candidatePaths = [
      r'C:\Program Files\BlueStacks_nxt\HD-Player.exe',
      r'C:\Program Files (x86)\BlueStacks_nxt\HD-Player.exe',
      r'C:\Program Files\BlueStacks\HD-Player.exe',
      r'C:\Program Files (x86)\BlueStacks\HD-Player.exe',
    ];
    for (final p in candidatePaths) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  Future<bool> _isBlueStacksRunning() async {
    try {
      final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq HD-Player.exe']);
      return result.stdout.toString().contains('HD-Player.exe');
    } catch (_) {
      return false;
    }
  }

  String _findAdbPath() {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? '';
    final sdkAdb = '$localAppData\\Android\\Sdk\\platform-tools\\adb.exe';
    if (File(sdkAdb).existsSync()) return sdkAdb;
    const bsAdb = r'C:\Program Files\BlueStacks_nxt\HD-Adb.exe';
    if (File(bsAdb).existsSync()) return bsAdb;
    return 'adb';
  }

  bool _isMobileProject(String root) {
    if (File('$root/pubspec.yaml').existsSync()) {
      if (Directory('$root/android').existsSync() || Directory('$root/ios').existsSync()) return true;
      try {
        final content = File('$root/pubspec.yaml').readAsStringSync();
        if (content.contains('flutter:') || content.contains('sdk: flutter')) return true;
      } catch (_) {}
    }
    if (Directory('$root/app').existsSync() && File('$root/app/build.gradle').existsSync()) return true;
    if (File('$root/build.gradle').existsSync() || File('$root/build.gradle.kts').existsSync()) {
      if (Directory('$root/app').existsSync() || Directory('$root/android').existsSync()) return true;
    }
    if (File('$root/package.json').existsSync()) {
      try {
        final content = File('$root/package.json').readAsStringSync();
        if (content.contains('"react-native"') || content.contains('"expo"')) return true;
      } catch (_) {}
    }
    return false;
  }

  List<ProjectRunner> _detectProjectRunners(String root) {
    if (root.isEmpty) return [];
    final List<ProjectRunner> list = [];

    // Subdirectories scan
    List<Directory> subDirs = [];
    try {
      subDirs = Directory(root).listSync().whereType<Directory>().toList();
    } catch (_) {}

    SubService? backendService;
    final List<SubService> frontendServices = [];

    // --- 1. DETECT BACKEND SERVICES ---
    // A. Visual Studio Solution or .csproj in root or subdirectories (backend, server, api, src)
    String? vsProjPath;
    try {
      if (Directory(root).listSync().any((e) => e.path.endsWith('.sln') || e.path.endsWith('.csproj'))) {
        vsProjPath = root;
      } else {
        for (final d in subDirs) {
          final dirName = d.path.split(RegExp(r'[\\/]')).last.toLowerCase();
          if (['backend', 'server', 'api', 'src', 'service'].contains(dirName)) {
            if (d.listSync().any((e) => e.path.endsWith('.sln') || e.path.endsWith('.csproj'))) {
              vsProjPath = d.path;
              break;
            }
          }
        }
      }
    } catch (_) {}
    if (vsProjPath != null) {
      backendService = SubService(
        name: 'Backend (.NET / Visual Studio)',
        command: 'dotnet run',
        workingDir: vsProjPath,
        port: 5000,
        webUrl: 'http://127.0.0.1:5000',
      );
    }

    // B. Django Web Server (manage.py in root or subdirectories)
    if (backendService == null) {
      File? foundManagePy;
      if (File('$root/manage.py').existsSync()) {
        foundManagePy = File('$root/manage.py');
      } else {
        for (final d in subDirs) {
          final c = File('${d.path}/manage.py');
          if (c.existsSync()) { foundManagePy = c; break; }
        }
      }
      if (foundManagePy != null) {
        final relPath = foundManagePy.path.substring(root.length).replaceAll(RegExp(r'^[\\/]'), '');
        backendService = SubService(
          name: 'Backend (Django Web Server)',
          command: 'python -X utf8 $relPath runserver 0.0.0.0:8000',
          workingDir: root,
          port: 8000,
          webUrl: 'http://127.0.0.1:8000',
          additionalUrls: const [
            {'label': 'Giao diện Khách (Web)', 'url': 'http://127.0.0.1:8000'},
            {'label': 'Giao diện Quản trị (Admin)', 'url': 'http://127.0.0.1:8000/admin'},
          ],
        );
      }
    }

    // C. Node.js Backend in subdirectories (server, backend, api)
    if (backendService == null) {
      for (final d in subDirs) {
        final dirName = d.path.split(RegExp(r'[\\/]')).last.toLowerCase();
        if (['server', 'backend', 'api'].contains(dirName)) {
          final pkgFile = File('${d.path}/package.json');
          if (pkgFile.existsSync()) {
            try {
              final pkg = jsonDecode(pkgFile.readAsStringSync()) as Map<String, dynamic>;
              final scripts = pkg['scripts'] as Map<String, dynamic>? ?? {};
              final cmd = scripts.containsKey('dev') ? 'npm run dev' : (scripts.containsKey('start') ? 'npm start' : 'node index.js');
              backendService = SubService(
                name: 'Backend (Node.js)',
                command: cmd,
                workingDir: d.path,
                port: 5000,
                webUrl: 'http://127.0.0.1:5000',
              );
              break;
            } catch (_) {}
          } else if (File('${d.path}/server.js').existsSync() || File('${d.path}/index.js').existsSync() || File('${d.path}/app.js').existsSync()) {
            final entry = File('${d.path}/server.js').existsSync() ? 'server.js' : (File('${d.path}/index.js').existsSync() ? 'index.js' : 'app.js');
            backendService = SubService(
              name: 'Backend (Node.js: $entry)',
              command: 'node $entry',
              workingDir: d.path,
              port: 5000,
              webUrl: 'http://127.0.0.1:5000',
            );
            break;
          }
        }
      }
    }

    // D. Python FastAPI / Flask in backend folder or root
    if (backendService == null) {
      for (final d in subDirs) {
        final dirName = d.path.split(RegExp(r'[\\/]')).last.toLowerCase();
        if (['backend', 'server', 'api'].contains(dirName)) {
          try {
            final pyFiles = d.listSync().whereType<File>().where((f) => f.path.endsWith('.py')).toList();
            for (final f in pyFiles) {
              final content = f.readAsStringSync();
              if (content.contains('FastAPI') || content.contains('Flask') || content.contains('uvicorn')) {
                final pyName = f.path.split(RegExp(r'[\\/]')).last;
                backendService = SubService(
                  name: 'Backend (Python $pyName)',
                  command: 'python -X utf8 $pyName',
                  workingDir: d.path,
                  port: 8000,
                  webUrl: 'http://127.0.0.1:8000',
                );
                break;
              }
            }
            if (backendService != null) break;
          } catch (_) {}
        }
      }
    }

    // --- 2. DETECT FRONTEND SERVICES (Admin, Client, Web, etc.) ---
    final candidateDirs = <Directory>[];
    candidateDirs.addAll(subDirs);

    // Monorepo sub-folders (apps/, packages/, frontend/, modules/)
    for (final d in subDirs) {
      final dName = d.path.split(RegExp(r'[\\/]')).last.toLowerCase();
      if (['apps', 'packages', 'modules', 'frontends', 'clients', 'frontend'].contains(dName)) {
        try {
          candidateDirs.addAll(d.listSync().whereType<Directory>());
        } catch (_) {}
      }
    }

    final scannedPaths = <String>{};
    for (final d in candidateDirs) {
      final dirPath = d.path;
      if (scannedPaths.contains(dirPath)) continue;
      scannedPaths.add(dirPath);

      final dirName = d.path.split(RegExp(r'[\\/]')).last.toLowerCase();
      if (['backend', 'server', 'api', 'services', 'service', 'node_modules', '.git', 'build', 'dist', 'target'].contains(dirName)) {
        continue;
      }

      final pkgFile = File('${d.path}/package.json');
      if (pkgFile.existsSync()) {
        try {
          final pkg = jsonDecode(pkgFile.readAsStringSync()) as Map<String, dynamic>;
          final pkgName = (pkg['name'] as String? ?? '').toLowerCase();
          final deps = {
            ...(pkg['dependencies'] as Map<String, dynamic>? ?? {}),
            ...(pkg['devDependencies'] as Map<String, dynamic>? ?? {}),
          };

          final isWebPkg = deps.containsKey('react') ||
              deps.containsKey('react-dom') ||
              deps.containsKey('vue') ||
              deps.containsKey('@angular/core') ||
              deps.containsKey('svelte') ||
              deps.containsKey('next') ||
              deps.containsKey('nuxt') ||
              deps.containsKey('vite');

          final isExplicitDir = [
            'frontend', 'client', 'web', 'ui', 'clientapp', 'app', 'portal',
            'admin', 'dashboard', 'backoffice', 'manage', 'cms',
            'customer', 'guest', 'user', 'storefront', 'shop'
          ].any((k) => dirName.contains(k) || pkgName.contains(k));

          if (isWebPkg || isExplicitDir) {
            String roleName;
            int defaultPort;

            if (dirName.contains('admin') || pkgName.contains('admin') ||
                dirName.contains('dashboard') || dirName.contains('backoffice') ||
                dirName.contains('manage') || dirName.contains('cms')) {
              roleName = 'Giao diện Quản trị (Admin: $dirName)';
              defaultPort = 5174;
            } else if (dirName.contains('client') || pkgName.contains('client') ||
                dirName.contains('customer') || dirName.contains('guest') ||
                dirName.contains('user') || dirName.contains('storefront') ||
                dirName.contains('shop')) {
              roleName = 'Giao diện Khách (Client: $dirName)';
              defaultPort = 5173;
            } else if (dirName.contains('partner') || dirName.contains('merchant') ||
                dirName.contains('driver') || dirName.contains('staff')) {
              roleName = 'Giao diện Đối tác ($dirName)';
              defaultPort = 5175;
            } else {
              roleName = 'Giao diện Web ($dirName)';
              defaultPort = 3000 + frontendServices.length;
            }

            while (frontendServices.any((s) => s.port == defaultPort)) {
              defaultPort++;
            }

            String framework = 'Web';
            if (deps.containsKey('react') || deps.containsKey('react-dom')) {
              framework = 'React';
            } else if (deps.containsKey('next')) {
              framework = 'Next.js';
            } else if (deps.containsKey('vue')) {
              framework = 'Vue';
            } else if (deps.containsKey('@angular/core')) {
              framework = 'Angular';
            }

            final scripts = pkg['scripts'] as Map<String, dynamic>? ?? {};
            final cmd = scripts.containsKey('dev')
                ? 'npm run dev'
                : (scripts.containsKey('start') ? 'npm start' : 'npm run serve');

            frontendServices.add(SubService(
              name: '$roleName - $framework',
              command: cmd,
              workingDir: d.path,
              port: defaultPort,
              webUrl: 'http://127.0.0.1:$defaultPort',
            ));
          }
        } catch (_) {}
      }
    }

    // B. Root package.json check (if monorepo or full-stack scripts)
    if (File('$root/package.json').existsSync()) {
      try {
        final pkg = jsonDecode(File('$root/package.json').readAsStringSync()) as Map<String, dynamic>;
        final scripts = pkg['scripts'] as Map<String, dynamic>? ?? {};
        final hasAdminScript = scripts.containsKey('dev:admin') || scripts.containsKey('admin') || scripts.containsKey('start:admin');
        final hasClientScript = scripts.containsKey('dev:client') || scripts.containsKey('client') || scripts.containsKey('start:client');
        if (hasAdminScript && !frontendServices.any((s) => s.name.contains('Admin'))) {
          final aCmd = scripts.containsKey('dev:admin') ? 'npm run dev:admin' : (scripts.containsKey('admin') ? 'npm run admin' : 'npm run start:admin');
          frontendServices.add(SubService(
            name: 'Giao diện Quản trị (Admin)',
            command: aCmd,
            workingDir: root,
            port: 5174,
            webUrl: 'http://127.0.0.1:5174',
          ));
        }
        if (hasClientScript && !frontendServices.any((s) => s.name.contains('Khách') || s.name.contains('Client'))) {
          final cCmd = scripts.containsKey('dev:client') ? 'npm run dev:client' : (scripts.containsKey('client') ? 'npm run client' : 'npm run start:client');
          frontendServices.add(SubService(
            name: 'Giao diện Khách (Client)',
            command: cCmd,
            workingDir: root,
            port: 5173,
            webUrl: 'http://127.0.0.1:5173',
          ));
        }
        final hasDevServer = scripts.containsKey('dev:server') || scripts.containsKey('server') || scripts.containsKey('start:server');
        if (hasDevServer && backendService == null) {
          final sCmd = scripts.containsKey('dev:server') ? 'npm run dev:server' : (scripts.containsKey('server') ? 'npm run server' : 'npm run start:server');
          backendService = SubService(name: 'Backend (Node.js)', command: sCmd, workingDir: root, port: 5000, webUrl: 'http://127.0.0.1:5000');
        }
      } catch (_) {}
    }

    // --- 3. DETECT STATIC HTML APPS / PORTALS ---
    final List<Map<String, String>> staticHtmlPortals = [];
    try {
      void checkHtmlFolder(Directory d) {
        final dName = d.path.split(RegExp(r'[\\/]')).last;
        if (['node_modules', '.git', 'build', 'dist', '__pycache__', 'target'].contains(dName.toLowerCase())) return;
        final html = File('${d.path}/index.html');
        if (html.existsSync()) {
          final rel = d.path.substring(root.length).replaceAll(RegExp(r'^[\\/]'), '').replaceAll('\\', '/');
          String label;
          final low = rel.toLowerCase();
          if (low.contains('admin') || low.contains('dashboard') || low.contains('backoffice')) {
            label = 'Giao diện Quản trị (Admin: $rel)';
          } else if (low.contains('portal') || low.contains('client') || low.contains('khách') || low.contains('student')) {
            label = 'Cổng thông tin Portal ($rel)';
          } else if (low.contains('máy điểm danh') || low.contains('kiosk') || low.contains('diem danh')) {
            label = 'Máy điểm danh Kiosk ($rel)';
          } else {
            label = 'Trang Web ($rel)';
          }
          staticHtmlPortals.add({
            'label': label,
            'relPath': rel,
          });
        }
      }

      for (final d in subDirs) {
        checkHtmlFolder(d);
        try {
          for (final sub in d.listSync().whereType<Directory>()) {
            checkHtmlFolder(sub);
          }
        } catch (_) {}
      }
    } catch (_) {}

    // --- 4. DETECT RUNNABLE DESKTOP / AI PYTHON MODULES ---
    final List<SubService> pythonAppServices = [];
    try {
      final pyFiles = Directory(root).listSync().whereType<File>().where((f) => f.path.endsWith('.py')).toList();
      for (final py in pyFiles) {
        final name = py.path.split(RegExp(r'[\\/]')).last;
        if (['manage.py', 'setup.py', 'settings.py', 'urls.py', 'wsgi.py', 'asgi.py', 'conftest.py', 'test.py'].contains(name) ||
            name.startsWith('test_') || name.endsWith('_test.py')) {
          continue;
        }

        String roleName;
        if (name == 'project.py' || name == 'attendance.py') {
          roleName = 'Hệ thống Điểm danh / Camera AI ($name)';
        } else if (name == 'admin.py') {
          roleName = 'Giao diện Quản trị ($name)';
        } else if (name == 'register.py') {
          roleName = 'Phân hệ Đăng ký khuôn mặt ($name)';
        } else if (name == 'main.py' || name == 'app.py') {
          roleName = 'Ứng dụng chính ($name)';
        } else {
          roleName = 'Phân hệ Python: $name';
        }

        pythonAppServices.add(SubService(
          name: roleName,
          command: 'python -X utf8 $name',
          workingDir: root,
        ));
      }
    } catch (_) {}

    // If static HTML portals exist and no web server is running, offer a static web server
    SubService? staticServerService;
    if (backendService == null && frontendServices.isEmpty && staticHtmlPortals.isNotEmpty) {
      final additional = staticHtmlPortals.map((p) => {
        'label': p['label']!,
        'url': 'http://127.0.0.1:8080/${p['relPath']}/index.html',
      }).toList();
      staticServerService = SubService(
        name: 'Máy chủ Web tĩnh (Port 8080)',
        command: 'python -m http.server 8080 --bind 127.0.0.1',
        workingDir: root,
        port: 8080,
        webUrl: 'http://127.0.0.1:8080',
        additionalUrls: additional,
      );
    }

    // --- 5. ASSEMBLE ALL-PARTS COMPOSITE RUNNER ---
    final allServices = <SubService>[
      if (backendService != null) backendService,
      if (staticServerService != null) staticServerService,
      ...frontendServices,
      ...pythonAppServices,
    ];

    // Collect all web links from all services
    final allWebLinks = <Map<String, String>>[];
    for (final s in allServices) {
      if (s.webUrl != null && !allWebLinks.any((item) => item['url'] == s.webUrl)) {
        allWebLinks.add({'label': s.name, 'url': s.webUrl!});
      }
      if (s.additionalUrls != null) {
        for (final u in s.additionalUrls!) {
          if (!allWebLinks.any((item) => item['url'] == u['url'])) {
            allWebLinks.add(u);
          }
        }
      }
    }

    if (allServices.length > 1) {
      final summaryNames = allServices.map((s) => s.name.split(' (').first.split(' - ').first).join(' + ');
      list.add(ProjectRunner(
        name: 'Mở toàn bộ dự án (Đầy đủ ${allServices.length} phân hệ: $summaryNames)',
        command: 'CONCURRENT',
        description: 'Khởi chạy đồng thời tất cả các giao diện (Admin, Khách...) và các phân hệ phần mềm/AI',
        isPrimary: true,
        services: allServices,
        port: allServices.first.port,
        webUrl: allServices.first.webUrl,
        webLinks: allWebLinks,
      ));

      if (frontendServices.length > 1) {
        list.add(ProjectRunner(
          name: 'Tất cả Giao diện Web (${frontendServices.length} giao diện)',
          command: 'CONCURRENT',
          description: 'Khởi chạy song song toàn bộ các giao diện Web',
          services: frontendServices,
          port: frontendServices.first.port,
          webUrl: frontendServices.first.webUrl,
        ));
      }

      for (final s in allServices) {
        list.add(ProjectRunner(
          name: 'Chỉ chạy: ${s.name}',
          command: s.command,
          description: 'Khởi chạy riêng phân hệ tại ${s.workingDir ?? root}',
          workingDir: s.workingDir,
          port: s.port,
          webUrl: s.webUrl,
          webLinks: s.additionalUrls,
        ));
      }
    } else if (allServices.length == 1) {
      final single = allServices.first;
      list.add(ProjectRunner(
        name: 'Mở toàn bộ dự án (${single.name})',
        command: single.command,
        description: 'Khởi chạy toàn bộ dịch vụ dự án',
        isPrimary: true,
        workingDir: single.workingDir,
        port: single.port,
        webUrl: single.webUrl,
        webLinks: single.additionalUrls ?? allWebLinks,
      ));
    }

    // B. Docker Compose (if exists)
    if (File('$root/docker-compose.yml').existsSync() ||
        File('$root/docker-compose.yaml').existsSync() ||
        File('$root/compose.yaml').existsSync()) {
      list.insert(0, const ProjectRunner(
        name: 'Toàn bộ dịch vụ (Docker Compose)',
        command: 'docker compose up',
        description: 'Khởi chạy toàn bộ container và services qua Docker Compose',
        isPrimary: true,
      ));
    }

    // C. Single Root Node.js project (if not full-stack)
    if (list.isEmpty && File('$root/package.json').existsSync()) {
      try {
        final pkgJson = jsonDecode(File('$root/package.json').readAsStringSync()) as Map<String, dynamic>;
        final scripts = pkgJson['scripts'] as Map<String, dynamic>? ?? {};
        if (scripts.containsKey('dev')) {
          list.add(const ProjectRunner(
            name: 'Toàn bộ dự án (Node/Web: npm run dev)',
            command: 'npm run dev',
            description: 'Khởi chạy máy chủ phát triển Web',
            isPrimary: true,
            port: 3000,
            webUrl: 'http://127.0.0.1:3000',
          ));
        } else if (scripts.containsKey('start')) {
          list.add(const ProjectRunner(
            name: 'Toàn bộ dự án (Node/Web: npm start)',
            command: 'npm start',
            description: 'Khởi chạy ứng dụng Web',
            isPrimary: true,
            port: 3000,
            webUrl: 'http://127.0.0.1:3000',
          ));
        }
      } catch (_) {}
    }

    // D. Flutter (if exists)
    if (File('$root/pubspec.yaml').existsSync()) {
      list.add(ProjectRunner(
        name: 'Toàn bộ ứng dụng Flutter (Desktop / Mobile)',
        command: 'flutter run',
        description: 'Khởi chạy toàn bộ ứng dụng Flutter',
        isPrimary: list.isEmpty,
        isMobile: true,
      ));
      list.add(const ProjectRunner(
        name: 'Flutter Web Server (Port 8080)',
        command: 'flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080',
        description: 'Khởi chạy Flutter Web xem trên trình duyệt & điện thoại',
        port: 8080,
        webUrl: 'http://127.0.0.1:8080',
      ));
    }

    // E. Android Native
    if (File('$root/gradlew.bat').existsSync() || File('$root/android/gradlew.bat').existsSync()) {
      list.add(ProjectRunner(
        name: 'Toàn bộ dự án Android (Cài lên BlueStacks)',
        command: '.\\gradlew.bat installDebug',
        description: 'Cài đặt và chạy ứng dụng Android trên BlueStacks',
        isPrimary: list.isEmpty,
        isMobile: true,
      ));
    }

    if (list.isEmpty) {
      list.add(const ProjectRunner(
        name: 'Chạy mặc định (dir)',
        command: 'dir',
        description: 'Xem thư mục dự án',
        isPrimary: true,
      ));
    }

    return list;
  }

  Future<void> _startServiceProcess(String tag, String rawCmd, String workDir) async {
    var cmd = rawCmd;
    if (cmd.startsWith('python ') && !cmd.startsWith('python -X utf8')) {
      cmd = cmd.replaceFirst('python ', 'python -X utf8 ');
    }
    _runnerLogs.add('  > [$tag] Thực thi: $cmd');

    try {
      final proc = await Process.start(
        'cmd.exe',
        ['/c', 'chcp 65001 >nul && $cmd'],
        workingDirectory: workDir,
        mode: ProcessStartMode.normal,
        environment: {
          ...Platform.environment,
          'PYTHONIOENCODING': 'utf-8',
          'PYTHONUTF8': '1',
          'LANG': 'en_US.UTF-8',
        },
      );
      _runningProcesses.add(proc);

      proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        if (mounted) {
          setState(() {
            for (final line in data.split('\n')) {
              if (line.trim().isNotEmpty) {
                _runnerLogs.add('[$tag] ${line.trim()}');
                _detectDynamicUrl(line.trim(), tag);
              }
            }
            if (_runnerLogs.length > 800) _runnerLogs.removeRange(0, _runnerLogs.length - 800);
          });
          _scrollToBottomRunnerLogs();
        }
      });

      proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        if (mounted) {
          setState(() {
            for (final line in data.split('\n')) {
              if (line.trim().isNotEmpty) _runnerLogs.add('[$tag][ERR] ${line.trim()}');
            }
            if (_runnerLogs.length > 800) _runnerLogs.removeRange(0, _runnerLogs.length - 800);
          });
          _scrollToBottomRunnerLogs();
        }
      });

      proc.exitCode.then((code) {
        if (mounted) {
          _runningProcesses.remove(proc);
          setState(() {
            _runnerLogs.add('[OK] Dịch vụ [$tag] kết thúc với mã thoát: $code.');
            if (_runningProcesses.isEmpty) {
              _isRunningProject = false;
              _activeWebLinks.clear();
              _activeRunner = null;
              _runnerLogs.add('\n[OK] Tất cả tiến trình dự án đã hoàn thành.');
            }
          });
          _scrollToBottomRunnerLogs();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _runnerLogs.add('Lỗi khởi chạy [$tag]: $e');
        });
        _scrollToBottomRunnerLogs();
      }
    }
  }

  Future<void> _toggleRunProject([ProjectRunner? targetRunner]) async {
    if (_isRunningProject) {
      for (final p in _runningProcesses) {
        try { p.kill(); } catch (_) {}
      }
      _runningProcesses.clear();
      setState(() {
        _isRunningProject = false;
        _activeWebLinks.clear();
        _activeRunner = null;
        _runnerLogs.add('Process(es) stopped by user.');
      });
      return;
    }

    final root = widget.project?.rootPath ?? '';
    if (root.isEmpty) return;

    final runners = _detectProjectRunners(root);
    final runner = targetRunner ?? (runners.isNotEmpty ? runners.first : null);
    if (runner == null) return;

    setState(() {
      _isRunningProject = true;
      _activeRunner = runner;
      _activeWebLinks.clear();
      _runnerLogs.clear();
      _runnerLogs.add('[RUN] Khởi chạy: ${runner.name}');
      _runnerLogs.add('  > Thư mục dự án: $root');
      _runnerLogs.add('  > Mô tả: ${runner.description}');
      if (runner.webUrl != null) {
        _activeWebLinks.add({'label': runner.name, 'url': runner.webUrl!});
      }
      if (runner.webLinks != null) {
        for (final l in runner.webLinks!) {
          if (!_activeWebLinks.any((item) => item['url'] == l['url'])) {
            _activeWebLinks.add(l);
          }
        }
      }
      _runnerLogs.add('--------------------------------------------------');
    });

    final isMobile = runner.isMobile || _isMobileProject(root);
    if (isMobile) {
      final bsPath = _findBlueStacksPath();
      if (bsPath != null) {
        final isRunning = await _isBlueStacksRunning();
        if (!isRunning) {
          _runnerLogs.add('\n[BlueStacks] Phát hiện dự án Mobile! Đang tự động mở BlueStacks...');
          try {
            await Process.start(bsPath, []);
            _runnerLogs.add('[BlueStacks] Đang chờ BlueStacks khởi động...');
          } catch (e) {
            _runnerLogs.add('[BlueStacks] Lỗi mở BlueStacks: $e');
          }
        }
        final adb = _findAdbPath();
        try {
          final adbRes = await Process.run(adb, ['connect', '127.0.0.1:5555']);
          _runnerLogs.add('[ADB] Kết nối BlueStacks (127.0.0.1:5555): ${adbRes.stdout.toString().trim()}');
        } catch (_) {}
      }
    }

    if (runner.services != null && runner.services!.isNotEmpty) {
      for (final svc in runner.services!) {
        if (svc.webUrl != null && !_activeWebLinks.any((item) => item['url'] == svc.webUrl)) {
          _activeWebLinks.add({'label': svc.name, 'url': svc.webUrl!});
        }
        if (svc.additionalUrls != null) {
          for (final u in svc.additionalUrls!) {
            if (!_activeWebLinks.any((item) => item['url'] == u['url'])) {
              _activeWebLinks.add(u);
            }
          }
        }
        await _startServiceProcess(svc.name, svc.command, svc.workingDir ?? root);
      }
    } else {
      if (runner.webLinks != null) {
        for (final l in runner.webLinks!) {
          if (!_activeWebLinks.any((item) => item['url'] == l['url'])) {
            _activeWebLinks.add(l);
          }
        }
      }
      await _startServiceProcess('App', runner.command, runner.workingDir ?? root);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _poller?.cancel();
    _followUpController.dispose();
    _codeController.dispose();
    _codeScrollController.dispose();
    _lineScrollController.dispose();
    _runnerInputController.dispose();
    _runnerScrollController.dispose();
    for (final p in _runningProcesses) {
      try { p.kill(); } catch (_) {}
    }
    _runningProcesses.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final diff = task?.metadata['diff'] as String?;
    final changedFiles = (task?.metadata['changedFiles'] as List?)?.cast<String>() ?? [];
    final taskOutput = task?.output;
    final displayText = (taskOutput != null && taskOutput.isNotEmpty)
        ? taskOutput
        : _logs.join('\n');
    final installCmds = _detectInstallCommands();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: const Color(0xFF16191E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF4A7C59), width: 1.5),
      ),
      child: SizedBox(
        width: 1350,
        height: 820,
        child: Column(
          children: [
            // Top Title Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2228),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Color(0xFF2B3038))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.psychology, color: Color(0xFF4ADE80), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.project?.name ?? widget.projectId} • AI MASTER WORKSPACE',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80), letterSpacing: 0.5),
                          ),
                          Text(
                            'Task: #${_activeTaskId.value.length > 8 ? _activeTaskId.value.substring(0, 8) : _activeTaskId.value} • Prompt: "${widget.initialPrompt}"',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isFinished ? const Color(0xFF4ADE80).withValues(alpha: 0.15) : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isFinished ? const Color(0xFF4ADE80) : const Color(0xFF3B82F6)),
                        ),
                        child: Row(
                          children: [
                            if (!_isFinished) ...[
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              ),
                              const SizedBox(width: 6),
                              const Text('AI Generating...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                            ] else ...[
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF4ADE80)),
                              const SizedBox(width: 4),
                              const Text('COMPLETED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Thu nhỏ thành bóng chat (Minimize)',
                        icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                        onPressed: () {
                          widget.onMinimize();
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        tooltip: 'Đóng (Close)',
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isFinished) const LinearProgressIndicator(color: Color(0xFF4A7C59), backgroundColor: Color(0xFF22262C)),

            // Main Two-Column Layout
            Expanded(
              child: Row(
                children: [
                  // Left Column: AI logs & follow-up prompt input (Width: _chatWidth)
                  Container(
                    width: _chatWidth,
                    decoration: const BoxDecoration(
                      color: Color(0xFF14171A),
                      border: Border(right: BorderSide(color: Color(0xFF2B3038))),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: const Color(0xFF1B1E23),
                          child: const Row(
                            children: [
                              Icon(Icons.notes, size: 16, color: Color(0xFF4ADE80)),
                              SizedBox(width: 6),
                              Text('AI INSTRUCTIONS & LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: SelectionArea(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayText.isNotEmpty ? displayText : 'Connecting to AI model and analyzing project workspace...',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE2E4E9), height: 1.4),
                                  ),
                                  if (diff != null && diff.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    const Divider(color: Color(0xFF3E4552)),
                                    const Text('CODE CHANGES / UNIFIED DIFF:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4ADE80))),
                                    const SizedBox(height: 6),
                                    Text(diff, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF86EFAC))),
                                  ],
                                  if (changedFiles.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text('Modified files: ${changedFiles.join(', ')}', style: const TextStyle(fontSize: 11, color: Colors.amberAccent)),
                                  ],

                                  // Resource / Environment Installation Card
                                  if (installCmds.isNotEmpty) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.download_for_offline, size: 16, color: Color(0xFF60A5FA)),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'TÀI NGUYÊN & MÔI TRƯỜNG CẦN THIẾT',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Các lệnh cài đặt cần thiết được phát hiện cho dự án này:',
                                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                          const SizedBox(height: 6),
                                          ...installCmds.map((cmd) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.terminal, size: 12, color: Color(0xFF38BDF8)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    cmd,
                                                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Color(0xFFE2E8F0)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF2563EB),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onPressed: _isRunningProject ? null : () => _runInstallCommands(installCmds),
                                              icon: const Icon(Icons.play_circle_fill, size: 15),
                                              label: Text(
                                                'Tự động chạy ${installCmds.length} lệnh cài đặt (cmd)',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Follow-up Input Box
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B1E23),
                            border: Border(top: BorderSide(color: Color(0xFF2B3038))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tiếp tục chỉnh sửa (Follow-up Task):', style: TextStyle(fontSize: 11, color: Color(0xFF4ADE80), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _followUpController,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        hintText: 'Nhập yêu cầu tiếp theo để tiếp tục sửa...',
                                        hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (_) => _sendFollowUp(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A7C59),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      minimumSize: const Size(36, 36),
                                    ),
                                    onPressed: _isSendingFollowUp ? null : _sendFollowUp,
                                    child: _isSendingFollowUp
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.send, size: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Draggable Splitter between Chat Column and Right Column
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _chatWidth = (_chatWidth + details.delta.dx).clamp(280.0, 750.0);
                        });
                      },
                      child: Container(
                        width: 7,
                        color: const Color(0xFF242830),
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A7C59),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Column: Project info, Files list, Code editor, Runner
                  Expanded(
                    child: Column(
                      children: [
                        // Directory info & Action Buttons (Install Requirements + Run Project)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          color: const Color(0xFF1B1E23),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.folder, size: 16, color: Color(0xFF4ADE80)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: SelectableText(
                                        widget.project?.rootPath ?? 'No path',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF9EA4B0)),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (installCmds.isNotEmpty) ...[
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: _isRunningProject ? null : () => _runInstallCommands(installCmds),
                                      icon: const Icon(Icons.download_for_offline, size: 16),
                                      label: Text('Tải tài nguyên (${installCmds.length})', style: const TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (_isRunningProject && _activeWebLinks.isNotEmpty) ...[
                                    for (final link in _activeWebLinks) ...[
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: link['label']!.toLowerCase().contains('admin') || link['label']!.toLowerCase().contains('quản trị')
                                              ? const Color(0xFFD97706)
                                              : (link['label']!.toLowerCase().contains('khách') || link['label']!.toLowerCase().contains('client'))
                                                  ? const Color(0xFF0284C7)
                                                  : const Color(0xFF4F46E5),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                        onPressed: () {
                                          try {
                                            Process.run('cmd.exe', ['/c', 'start', link['url']!]);
                                          } catch (_) {}
                                        },
                                        icon: Icon(
                                          link['label']!.toLowerCase().contains('admin') || link['label']!.toLowerCase().contains('quản trị')
                                              ? Icons.admin_panel_settings
                                              : (link['label']!.toLowerCase().contains('khách') || link['label']!.toLowerCase().contains('client'))
                                                  ? Icons.storefront
                                                  : Icons.open_in_browser,
                                          size: 16,
                                        ),
                                        label: Text('Mở ${link['label']} ↗', style: const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                  if (_isRunningProject)
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () => _toggleRunProject(),
                                      icon: const Icon(Icons.stop, size: 16),
                                      label: const Text('Dừng dự án (Stop)', style: TextStyle(fontSize: 12)),
                                    )
                                  else ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        color: const Color(0xFF16A34A),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                final runners = _detectProjectRunners(widget.project?.rootPath ?? '');
                                                _toggleRunProject(runners.isNotEmpty ? runners.first : null);
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.play_arrow, size: 16, color: Colors.white),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      _detectProjectRunners(widget.project?.rootPath ?? '').isNotEmpty &&
                                                              _detectProjectRunners(widget.project?.rootPath ?? '').first.isPrimary
                                                          ? 'Chạy cả dự án'
                                                          : 'Run Project',
                                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (_detectProjectRunners(widget.project?.rootPath ?? '').length > 1)
                                              Container(
                                                decoration: const BoxDecoration(
                                                  border: Border(left: BorderSide(color: Color(0xFF15803D))),
                                                ),
                                                child: PopupMenuButton<ProjectRunner>(
                                                  tooltip: 'Chọn phân hệ hoặc toàn bộ dự án để chạy',
                                                  icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                                                  color: const Color(0xFF1E2228),
                                                  offset: const Offset(0, 36),
                                                  onSelected: (runner) => _toggleRunProject(runner),
                                                  itemBuilder: (context) {
                                                    final runners = _detectProjectRunners(widget.project?.rootPath ?? '');
                                                    return runners.map((r) {
                                                      return PopupMenuItem<ProjectRunner>(
                                                        value: r,
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              r.isPrimary ? Icons.star : Icons.play_circle_outline,
                                                              size: 16,
                                                              color: r.isPrimary ? const Color(0xFFFBBF24) : const Color(0xFF4ADE80),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  Text(
                                                                    r.name,
                                                                    style: TextStyle(
                                                                      fontSize: 12,
                                                                      fontWeight: r.isPrimary ? FontWeight.bold : FontWeight.normal,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    r.command,
                                                                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Main Body: Row with File Tree Explorer (left) + Visual Studio Code Editor (right)
                        Expanded(
                          flex: 3,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Left Pane: File Tree Explorer (Cột nhánh cây thư mục)
                              Container(
                                width: _explorerWidth,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF181818),
                                  border: Border(right: BorderSide(color: Color(0xFF2D2D30))),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Explorer Header
                                    Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      alignment: Alignment.centerLeft,
                                      color: const Color(0xFF252526),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.account_tree, size: 14, color: Color(0xFF4ADE80)),
                                              const SizedBox(width: 6),
                                              Text(
                                                'EXPLORER: ${(widget.project?.name ?? "PROJECT").toUpperCase()}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFCCCCCC),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            tooltip: 'Làm mới cây thư mục (Refresh)',
                                            icon: const Icon(Icons.refresh, size: 14, color: Colors.grey),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                            onPressed: _loadProjectFiles,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Branch Tree List (Cột nhánh)
                                    Expanded(
                                      child: _rootTreeNodes.isEmpty
                                          ? const Center(
                                              child: Text('Không có tệp', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            )
                                          : ListView.builder(
                                              itemCount: _flattenTree(_rootTreeNodes).length,
                                              itemBuilder: (context, index) {
                                                final node = _flattenTree(_rootTreeNodes)[index];
                                                final isSelected = _selectedFile?.path == node.path;
                                                return InkWell(
                                                  onTap: () {
                                                    if (node.isDirectory) {
                                                      _toggleFolder(node);
                                                    } else {
                                                      _selectFile(File(node.path));
                                                    }
                                                  },
                                                  hoverColor: const Color(0xFF2A2D2E),
                                                  child: Container(
                                                    height: 24,
                                                    color: isSelected ? const Color(0xFF094771) : Colors.transparent,
                                                    padding: EdgeInsets.only(left: 8.0 + node.depth * 14.0, right: 6.0),
                                                    child: Row(
                                                      children: [
                                                        if (node.isDirectory)
                                                          Icon(
                                                            node.isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                                                            size: 20,
                                                            color: const Color(0xFF4ADE80),
                                                          )
                                                        else
                                                          const SizedBox(width: 20),
                                                        const SizedBox(width: 2),
                                                        _getFileIcon(node.name, node.isDirectory, node.isExpanded),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            node.name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontFamily: 'Consolas',
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : (node.isDirectory ? const Color(0xFFE2E4E9) : const Color(0xFFCCCCCC)),
                                                              fontWeight: node.isDirectory ? FontWeight.w500 : FontWeight.normal,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              // Draggable Splitter between File Explorer and Code Editor
                              MouseRegion(
                                cursor: SystemMouseCursors.resizeColumn,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      _explorerWidth = (_explorerWidth + details.delta.dx).clamp(150.0, 480.0);
                                    });
                                  },
                                  child: Container(
                                    width: 6,
                                    color: const Color(0xFF252526),
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF007ACC),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Right Pane: Visual Studio Code Editor
                              Expanded(
                                child: Container(
                                  color: const Color(0xFF1E1E1E), // Visual Studio Dark canvas
                                  child: Column(
                                    children: [
                                      // VS Tab Bar (Header)
                                      Container(
                                        height: 35,
                                        color: const Color(0xFF252526),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (_selectedFile != null)
                                              Container(
                                                height: 35,
                                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF1E1E1E),
                                                  border: Border(
                                                    top: BorderSide(color: Color(0xFF007ACC), width: 2),
                                                    right: BorderSide(color: Color(0xFF2D2D30)),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    _getFileIcon(_selectedFile!.path.split(RegExp(r'[\\/]')).last, false, false),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      _selectedFile!.path.split(RegExp(r'[\\/]')).last,
                                                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                                    ),
                                                    if (_isDirty) ...[
                                                      const SizedBox(width: 6),
                                                      const Text('●', style: TextStyle(fontSize: 12, color: Color(0xFF007ACC))),
                                                    ],
                                                  ],
                                                ),
                                              )
                                            else
                                              const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 14),
                                                child: Text('Chưa chọn tệp', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                              ),

                                            Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Row(
                                                children: [
                                                  // Font size controls
                                                  Container(
                                                    height: 26,
                                                    margin: const EdgeInsets.only(right: 10),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF1E1E1E),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFF3E3E42)),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                          tooltip: 'Giảm cỡ chữ (A-)',
                                                          icon: const Icon(Icons.remove, size: 13, color: Color(0xFFCCCCCC)),
                                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                          padding: EdgeInsets.zero,
                                                          onPressed: () {
                                                            setState(() {
                                                              _codeFontSize = (_codeFontSize - 1.0).clamp(9.0, 28.0);
                                                            });
                                                          },
                                                        ),
                                                        Text(
                                                          '${_codeFontSize.toInt()}pt',
                                                          style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC), fontFamily: 'Consolas'),
                                                        ),
                                                        IconButton(
                                                          tooltip: 'Tăng cỡ chữ (A+)',
                                                          icon: const Icon(Icons.add, size: 13, color: Color(0xFFCCCCCC)),
                                                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                                          padding: EdgeInsets.zero,
                                                          onPressed: () {
                                                            setState(() {
                                                              _codeFontSize = (_codeFontSize + 1.0).clamp(9.0, 28.0);
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (_saveMessage != null)
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 8),
                                                      child: Text(_saveMessage!, style: const TextStyle(fontSize: 11, color: Color(0xFF4ADE80))),
                                                    ),
                                                  FilledButton.icon(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: _isDirty ? const Color(0xFF007ACC) : const Color(0xFF2D2D30),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      minimumSize: const Size(80, 26),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    ),
                                                    onPressed: _selectedFile != null ? _saveCurrentFile : null,
                                                    icon: const Icon(Icons.save, size: 13),
                                                    label: const Text('Save (Ctrl+S)', style: TextStyle(fontSize: 11)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // VS Breadcrumbs bar
                                      if (_selectedFile != null)
                                        Container(
                                          height: 22,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          alignment: Alignment.centerLeft,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1E1E1E),
                                            border: Border(bottom: BorderSide(color: Color(0xFF2B2B2B))),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.folder_open, size: 12, color: Color(0xFF858585)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  _selectedFile!.path.replaceAll('\\', ' > '),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF858585), fontFamily: 'Consolas'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Code Editor Canvas with Line Numbers
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Line numbers gutter
                                            Container(
                                              width: 48,
                                              color: const Color(0xFF1E1E1E),
                                              decoration: const BoxDecoration(
                                                border: Border(right: BorderSide(color: Color(0xFF2D2D30))),
                                              ),
                                              padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8),
                                              child: SingleChildScrollView(
                                                controller: _lineScrollController,
                                                physics: const NeverScrollableScrollPhysics(),
                                                child: Text(
                                                  List.generate(
                                                    _codeController.text.split('\n').length.clamp(1, 99999),
                                                    (i) => '${i + 1}',
                                                  ).join('\n'),
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontFamily: 'Consolas',
                                                    fontSize: _codeFontSize,
                                                    height: 1.45,
                                                    color: const Color(0xFF858585),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Editable Code Area
                                            Expanded(
                                              child: Container(
                                                color: const Color(0xFF1E1E1E),
                                                padding: const EdgeInsets.only(left: 10, top: 8, right: 10, bottom: 8),
                                                child: TextField(
                                                  controller: _codeController,
                                                  scrollController: _codeScrollController,
                                                  maxLines: null,
                                                  expands: true,
                                                  style: TextStyle(
                                                    fontFamily: 'Consolas',
                                                    fontSize: _codeFontSize,
                                                    height: 1.45,
                                                    color: const Color(0xFFD4D4D4),
                                                  ),
                                                  cursorColor: const Color(0xFF007ACC),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    isDense: true,
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                  onChanged: (_) {
                                                    if (!_isDirty) setState(() => _isDirty = true);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // VS Code Bottom Status Bar
                                      Container(
                                        height: 22,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        color: const Color(0xFF007ACC), // VS Classic Blue
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.alt_route, size: 12, color: Colors.white),
                                                const SizedBox(width: 4),
                                                Text(
                                                  widget.project?.branch ?? widget.project?.gitInfo?.currentBranch ?? 'main',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 14),
                                                const Text('0 ⊗  0 warnings', style: TextStyle(fontSize: 11, color: Colors.white)),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Lines: ${_codeController.text.split("\n").length}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                                ),
                                                const SizedBox(width: 14),
                                                const Text('Spaces: 4', style: TextStyle(fontSize: 11, color: Colors.white)),
                                                const SizedBox(width: 14),
                                                const Text('UTF-8', style: TextStyle(fontSize: 11, color: Colors.white)),
                                                const SizedBox(width: 14),
                                                Text(
                                                  _selectedFile != null
                                                      ? _getFileLanguage(_selectedFile!.path)
                                                      : 'Plain Text',
                                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Project Runner output console (if running or has logs)
                        if (_runnerLogs.isNotEmpty || _isRunningProject)
                          Container(
                            height: 180,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A0C0E),
                              border: Border(top: BorderSide(color: Color(0xFF2B3038))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  color: const Color(0xFF1B1E23),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isRunningProject ? Icons.play_circle_fill : Icons.terminal,
                                            size: 14,
                                            color: _isRunningProject ? const Color(0xFF4ADE80) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isRunningProject
                                                ? 'RUNNER CONSOLE: ${_activeRunner?.name ?? "ĐANG CHẠY"}'
                                                : 'RUNNER CONSOLE (ĐÃ DỪNG)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _isRunningProject ? const Color(0xFF4ADE80) : Colors.grey,
                                            ),
                                          ),
                                          if (_activeWebLinks.isNotEmpty) ...[
                                            for (final link in _activeWebLinks) ...[
                                              const SizedBox(width: 10),
                                              InkWell(
                                                onTap: () {
                                                  try {
                                                    Process.run('cmd.exe', ['/c', 'start', link['url']!]);
                                                  } catch (_) {}
                                                },
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      link['label']!.toLowerCase().contains('admin') || link['label']!.toLowerCase().contains('quản trị')
                                                          ? Icons.admin_panel_settings
                                                          : (link['label']!.toLowerCase().contains('khách') || link['label']!.toLowerCase().contains('client'))
                                                              ? Icons.storefront
                                                              : Icons.open_in_browser,
                                                      size: 12,
                                                      color: link['label']!.toLowerCase().contains('admin') || link['label']!.toLowerCase().contains('quản trị')
                                                          ? const Color(0xFFFBBF24)
                                                          : const Color(0xFF38BDF8),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      '${link['label']}: ${link['url']} ↗',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: link['label']!.toLowerCase().contains('admin') || link['label']!.toLowerCase().contains('quản trị')
                                                            ? const Color(0xFFFBBF24)
                                                            : const Color(0xFF38BDF8),
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          if (_isRunningProject)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: InkWell(
                                                onTap: () {
                                                  for (final p in _runningProcesses) {
                                                    try { p.kill(); } catch (_) {}
                                                  }
                                                  _runningProcesses.clear();
                                                  setState(() {
                                                    _isRunningProject = false;
                                                    _activeWebLinks.clear();
                                                    _activeRunner = null;
                                                    _runnerLogs.add('\n[Dừng] Đã dừng toàn bộ tiến trình.');
                                                  });
                                                  _scrollToBottomRunnerLogs();
                                                },
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.stop_circle, size: 12, color: Colors.redAccent),
                                                    SizedBox(width: 4),
                                                    Text('Dừng', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          InkWell(
                                            onTap: () => setState(() => _runnerLogs.clear()),
                                            child: const Text('Clear', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _runnerScrollController,
                                    padding: const EdgeInsets.all(8),
                                    child: SelectionArea(
                                      child: Text(
                                        _runnerLogs.join('\n'),
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF86EFAC)),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isRunningProject)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF14171C),
                                      border: Border(top: BorderSide(color: Color(0xFF2B3038))),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '> ',
                                          style: TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _runnerInputController,
                                            style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'),
                                            decoration: const InputDecoration(
                                              hintText: 'Nhập lựa chọn (VD: 1, 2, 3...) rồi nhấn Enter',
                                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) => _sendRunnerInput(),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.send, size: 14, color: Color(0xFF4ADE80)),
                                          onPressed: _sendRunnerInput,
                                          tooltip: 'Gửi input đến tiến trình',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


