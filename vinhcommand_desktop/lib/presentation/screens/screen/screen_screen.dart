import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class ScreenScreen extends ConsumerWidget {
  const ScreenScreen({super.key});

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
                    'Screen',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Screen capture and monitoring',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Screen Screen - Implementation in progress',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}




