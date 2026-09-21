import '../../../application/providers/bridge_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/vinhcommand_application.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final agents = ref.watch(agentsProvider);
    final tasks = ref.watch(tasksProvider);
    final bridge = ref.watch(bridgeProvider);
    final accent = Theme.of(context).colorScheme.primary;
    Widget panel(String title, IconData icon, Widget child, String route) => Card(
      child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: accent), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))), IconButton(tooltip: 'Open $title', onPressed: () => context.go(route), icon: const Icon(Icons.north_east, size: 18))]),
        const Divider(), const SizedBox(height: 18), child,
      ])),
    );
    Widget state(AsyncValue<List<dynamic>> value, String empty, String route) => value.when(
      data: (items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(items.length.toString().padLeft(2, '0'), style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: accent)),
        const SizedBox(height: 8), Text(items.isEmpty ? empty : '${items.length} records in your workspace'),
        const SizedBox(height: 18), OutlinedButton(onPressed: () => context.go(route), child: Text(items.isEmpty ? 'Get started' : 'Open list')),
      ]), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('Unable to load: $e'),
    );
    return ListView(padding: const EdgeInsets.all(24), children: [
      Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 16, spacing: 24, crossAxisAlignment: WrapCrossAlignment.center, children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('AI Agent Command Center')]),
        Wrap(spacing: 10, runSpacing: 8, children: [OutlinedButton.icon(onPressed: () { ref.invalidate(projectsProvider); ref.invalidate(agentsProvider); ref.invalidate(tasksProvider); }, icon: const Icon(Icons.refresh, size: 16), label: const Text('Refresh All')), FilledButton.icon(onPressed: () => context.go('/tasks'), icon: const Icon(Icons.add, size: 16), label: const Text('New Task'))]),
      ]),
      const SizedBox(height: 28),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('START HERE / WORKFLOW', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        for(final step in <(String, String, String)>[
          ('1. Projects & permissions', '${(projects.valueOrNull ?? []).where((p) => ref.read(projectAccessProvider).mode(p.id.value) != "denied").length} authorized projects', '/projects'),
          ('2. Git & GitHub Sync', 'Clone repository, pull update, commit & push to GitHub', '/git'),
          ('3. Register AI agent', '${(agents.valueOrNull ?? []).where((a) => a.isAvailable).length} available agents', '/agents'),
          ('4. Add Android device', bridge.running ? 'Desktop online · open Devices to pair' : 'Desktop connection offline', '/devices'),
          ('5. Give work & follow progress', 'Select project, agent and access before confirming a task', '/tasks'),
          ('6. Review approvals', '${(tasks.valueOrNull ?? []).where((t) => t.metadata["approval"] != null).length} pending requests', '/approvals'),
          ('7. Review result', 'Files, diff, test evidence and follow-up', '/tasks'),
        ]) ListTile(contentPadding: EdgeInsets.zero, title: Text(step.$1), subtitle: Text(step.$2), trailing: const Icon(Icons.chevron_right), onTap: () => context.go(step.$3)),
      ]))),
      const SizedBox(height: 24),
      Text('WORKSPACE OVERVIEW', style: TextStyle(color: accent, letterSpacing: 2, fontSize: 12)),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth > 950 && MediaQuery.textScalerOf(context).scale(1) < 1.5 ? 3 : constraints.maxWidth > 650 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          SizedBox(width: width, child: panel('PROJECTS', Icons.folder_outlined, state(projects, 'Add a workspace to discover projects.', '/projects'), '/projects')),
          SizedBox(width: width, child: panel('AI AGENTS', Icons.terminal, state(agents, 'Scan for an installed Codex agent.', '/agents'), '/agents')),
          SizedBox(width: width, child: panel('TASKS', Icons.task_alt, state(tasks, 'Create a task to start AI agent work.', '/tasks'), '/tasks')),
        ]);
      }),
      const SizedBox(height: 24),
      panel('RECENT PROJECTS', Icons.folder_open, projects.when(data: (items) => items.isEmpty
        ? const Text('No projects found. Add a workspace to begin.')
        : Column(children: items.take(5).map((p) => ListTile(contentPadding: EdgeInsets.zero, title: Text(p.name), subtitle: Text(p.rootPath), trailing: const Icon(Icons.chevron_right), onTap: () => context.go('/projects'))).toList()), loading: () => const LinearProgressIndicator(), error: (e, _) => Text('$e')), '/projects'),
      const SizedBox(height: 14),
      panel('COMMAND LINE', Icons.code, Wrap(spacing: 24, runSpacing: 14, crossAxisAlignment: WrapCrossAlignment.center, children: [const Text('Local shell / project tools / command output'), OutlinedButton.icon(onPressed: () => context.go('/terminal'), icon: const Icon(Icons.terminal), label: const Text('Open terminal'))]), '/terminal'),
    ]);
  }
}

