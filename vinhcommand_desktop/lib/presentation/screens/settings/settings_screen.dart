import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/preferences_provider.dart';
import '../../widgets/companion_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(preferencesProvider);
    final controller = ref.read(preferencesProvider.notifier);
    Future<void> save(Future<void> operation) async {
      try { await operation; } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings could not be saved: $e'))); }
    }
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 20),
      const Text('Accessibility', style: TextStyle(fontSize: 20)),
      const SizedBox(height: 12),
      Text('Minimum text size: ${(settings.textScale * 100).round()}%'),
      Semantics(label: 'Minimum text size', child: Slider(value: settings.textScale, min: 1, max: 2, divisions: 4, label: '${(settings.textScale*100).round()}%', onChanged: (v) => save(controller.update(textScale: v)))),
      const Text('Your operating system text size is respected when it is larger.'),
      SwitchListTile(title: const Text('High contrast'), value: settings.highContrast, onChanged: (v) => save(controller.update(highContrast: v))),
      SwitchListTile(title: const Text('Reduce motion'), value: settings.reduceMotion, onChanged: (v) => save(controller.update(reduceMotion: v))),
      const Divider(),
      const CompanionSettings(),
      const Divider(),
      const Text('Keyboard shortcuts', style: TextStyle(fontSize: 20)),
      const Text('Tab / Shift+Tab: move focus\nEnter / Space: activate a control\nCtrl+K: go to a page\nCtrl+B: collapse navigation\nCtrl+`: terminal'),
    ]);
  }
}
