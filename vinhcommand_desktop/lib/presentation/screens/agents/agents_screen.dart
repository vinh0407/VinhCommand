import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/vinhcommand_application.dart';
import '../../../core/vinhcommand_core.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});
  @override ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}
class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  bool busy = false;
  String? error;
  Future<void> scan() async {
    setState(() { busy = true; error = null; });
    try { await ref.read(agentDiscoveryServiceProvider).discoverAgents(); ref.invalidate(agentsProvider); }
    catch (e) { if (mounted) setState(() => error = '$e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
    Text('AI agents', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    const Text('Discover locally installed tools. The MVP task runner supports Codex in read-only mode; sign in using its CLI before running a task.'),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: busy ? null : scan, icon: const Icon(Icons.search), label: Text(busy ? 'Scanning…' : 'Scan for agents')),
    if (error != null) Semantics(liveRegion: true, child: Text('Discovery failed: $error')),
    ref.watch(agentsProvider).when(loading: () => const LinearProgressIndicator(), error: (e,_) => Text('$e'), data: (agents) => Column(children: agents.map((agent) => Card(child: ListTile(title: Text(agent.name), subtitle: SelectableText('${agent.status.label} · ${agent.version}\n${agent.path.isEmpty ? 'Not installed' : agent.path}'), isThreeLine: true))).toList())),
  ]);
}
