import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/vinhcommand_application.dart';
import '../../../core/vinhcommand_core.dart' as model;
import '../../../infrastructure/terminal/terminal_service.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  const TerminalScreen({super.key});
  @override ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}
class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  StreamSubscription<model.TerminalOutput>? subscription;
  model.Terminal? terminal;
  String output = '';
  String? error;
  bool busy = false;
  late final TerminalService service;
  @override void initState() { super.initState(); service = ref.read(terminalServiceProvider); }
  Future<void> create() async {
    setState(() { busy = true; error = null; });
    try {
      final service = ref.read(terminalServiceProvider);
      final value = await service.createTerminal();
      if (!mounted) { await service.closeTerminal(value.id); return; }
      setState(() => terminal = value);
      subscription = service.getOutputStream(value.id).listen((event) {
        if (!mounted) return;
        setState(() { output += '${event.data}\n'; if (output.length > 100000) output = output.substring(output.length-100000); if (event.type == model.OutputType.exit) terminal = terminal?.copyWith(status: model.TerminalStatus.exited); });
      }, onError: (Object e) { if(mounted) setState(() => error = '$e'); });
    } catch(e) { if(mounted) setState(() => error = '$e'); }
    finally { if(mounted) setState(() => busy = false); }
  }
  Future<void> send() async {
    if (terminal?.isActive != true || input.text.trim().isEmpty) return;
    try { await ref.read(terminalServiceProvider).writeInput(terminal!.id, '${input.text}\n'); input.clear(); }
    catch(e) { if(mounted) setState(() => error = '$e'); }
  }
  Future<void> close() async {
    final value = terminal; if(value == null) return;
    await subscription?.cancel();
    try { await ref.read(terminalServiceProvider).closeTerminal(value.id); }
    catch(e) { if(mounted) setState(() => error = '$e'); }
    if(mounted) setState(() => terminal = null);
  }
  @override void dispose() {
    subscription?.cancel();
    final value = terminal;
    if (value != null) {
      unawaited(service.closeTerminal(value.id).catchError((Object error) { debugPrint('Terminal cleanup: $error'); }));
    }
    input.dispose(); scroll.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Terminal', style: Theme.of(context).textTheme.headlineSmall),
    const Text('Local shell session. Leaving this page closes the session. Full-screen applications are not supported yet.'),
    const SizedBox(height: 12),
    Wrap(spacing: 12, children: [FilledButton(onPressed: busy || terminal != null ? null : create, child: Text(busy ? 'Starting…' : 'New terminal')), OutlinedButton(onPressed: terminal == null ? null : close, child: const Text('Close terminal')), OutlinedButton(onPressed: () => setState(() => output = ''), child: const Text('Clear output'))]),
    if(error != null) Semantics(liveRegion: true, child: Text('Terminal error: $error')),
    Expanded(child: SingleChildScrollView(controller: scroll, padding: const EdgeInsets.symmetric(vertical: 16), child: SelectableText(output.isEmpty ? 'Shell output will appear here.' : output, style: const TextStyle(fontFamily: 'monospace')))),
    Row(children: [Expanded(child: TextField(controller: input, enabled: terminal?.isActive == true, decoration: const InputDecoration(labelText: 'Shell command'), onSubmitted: (_) => send())), IconButton(tooltip: 'Send command', onPressed: terminal?.isActive == true ? send : null, icon: const Icon(Icons.send))]),
  ]));
}
