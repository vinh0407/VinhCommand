import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../vinhcommand_presentation.dart';

const navigationItems = <(String, String, IconData)>[
  ('/dashboard', 'Dashboard', Icons.dashboard_outlined),
  ('/projects', 'Projects', Icons.folder_outlined),
  ('/git', 'Git & GitHub', Icons.commit),
  ('/agents', 'Agents', Icons.smart_toy_outlined),
  ('/tasks', 'Tasks', Icons.task_alt),
  ('/approvals', 'Approvals', Icons.security_outlined),
  ('/devices', 'Devices', Icons.devices),
  ('/terminal', 'Terminal', Icons.terminal),
  ('/settings', 'Settings', Icons.settings_outlined),
];
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(initialLocation: '/dashboard', routes: [
    ShellRoute(builder: (context, state, child) => MainLayout(child: child), routes: [
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/projects', builder: (_, _) => const ProjectsScreen()),
      GoRoute(path: '/git', builder: (_, _) => const GitScreen()),
      GoRoute(path: '/agents', builder: (_, _) => const AgentsScreen()),
      GoRoute(path: '/tasks', builder: (_, _) => const TasksScreen()),
      GoRoute(path: '/approvals', builder: (_, _) => const TasksScreen(approvalsOnly: true)),
      GoRoute(path: '/devices', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/terminal', builder: (_, _) => const TerminalScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ]),
  ]);
  ref.onDispose(router.dispose);
  return router;
});
class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});
  @override State<MainLayout> createState() => _MainLayoutState();
}
class _MainLayoutState extends State<MainLayout> {
  bool collapsed = false;
  Future<void> palette() => showDialog<void>(context: context, builder: (dialogContext) => SimpleDialog(
    title: const Text('Go to a page'),
    children: navigationItems.map((item) => SimpleDialogOption(onPressed: () { Navigator.pop(dialogContext); context.go(item.$1); }, child: Padding(padding: const EdgeInsets.all(8), child: Text(item.$2)))).toList(),
  ));
  @override Widget build(BuildContext context) {
    final route = GoRouterState.of(context).uri.path;
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final compact = narrow || collapsed;
    return CallbackShortcuts(bindings: {
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): palette,
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => setState(() => collapsed = !collapsed),
      const SingleActivator(LogicalKeyboardKey.backquote, control: true): () => context.go('/terminal'),
    }, child: Scaffold(
      body: Row(children: [
        Container(width: compact ? 68 : 250,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(right: BorderSide(color: Theme.of(context).colorScheme.outline))),
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16), child: compact
              ? IconButton(tooltip: 'Expand navigation', onPressed: narrow ? null : () => setState(() => collapsed = false), icon: const Icon(Icons.terminal))
              : Row(children: [Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), const Expanded(child: Text('VINHCOMMAND', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1))), IconButton(tooltip: 'Collapse navigation', onPressed: () => setState(() => collapsed = true), icon: const Icon(Icons.chevron_left))])),
            const Divider(),
            Expanded(child: ListView(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), children: navigationItems.map((item) {
              final selected = item.$1 == route;
              return Container(margin: const EdgeInsets.only(bottom: 2), decoration: BoxDecoration(
                color: selected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent)),
                child: Material(color: Colors.transparent, child: Semantics(selected: selected, button: true, label: compact ? item.$2 : null, child: compact
                  ? Tooltip(message: item.$2, child: IconButton(visualDensity: VisualDensity.compact, onPressed: () => context.go(item.$1), isSelected: selected, icon: Icon(item.$3, size: 20)))
                  : ListTile(dense: true, visualDensity: VisualDensity.compact, selected: selected, leading: Icon(item.$3, size: 18), title: Text(item.$2, style: const TextStyle(fontSize: 13)), trailing: selected ? Container(width: 3, height: 16, color: Theme.of(context).colorScheme.primary) : null, onTap: () => context.go(item.$1)))));
            }).toList())),
            if (!compact && MediaQuery.sizeOf(context).height > 650) const Padding(padding: EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Divider(), SizedBox(height: 16), Text('SHORTCUTS', style: TextStyle(fontSize: 11, letterSpacing: 2)), SizedBox(height: 12), Text('Ctrl+K  Command palette\nCtrl+B  Toggle sidebar\nCtrl+`  Terminal', style: TextStyle(fontSize: 11, height: 2))])),
          ])),
        Expanded(child: Column(children: [
          Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline))), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
            Expanded(child: Text('> ${route.substring(1)}', style: TextStyle(color: Theme.of(context).colorScheme.primary))),
            IconButton(tooltip: 'Go to a page (Ctrl+K)', onPressed: palette, icon: const Icon(Icons.search)),
          ])),
          Expanded(child: FocusTraversalGroup(child: widget.child)),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline))), child: const Text('VINHCOMMAND / LOCAL WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1))),
        ])),
      ]),
    ));
  }
}


