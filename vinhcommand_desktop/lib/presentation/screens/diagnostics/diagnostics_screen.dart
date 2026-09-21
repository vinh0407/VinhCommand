import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diagnostics',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'System and AI diagnostics',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.bug_report, size: 16),
                label: const Text('Run Diagnostics'),
                onPressed: () {},
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Diagnostics Screen - Implementation in progress',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}




