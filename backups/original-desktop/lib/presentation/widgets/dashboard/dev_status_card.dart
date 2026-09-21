import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';
import 'package:vinhcommand_desktop/application/vinhcommand_application.dart';

class DevStatusCard {
  static Widget processes(AsyncValue<List<ProcessInfo>> processesAsync) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.memory, size: 18, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'PROCESSES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            processesAsync.when(
              data: (processes) {
                if (processes.isEmpty) {
                  return _EmptyState(text: 'No development processes');
                }
                return Column(
                  children: processes.take(5).map((p) => _ProcessRow(process: p)).toList(),
                );
              },
              loading: () => _LoadingState(),
              error: (e, _) => _ErrorState(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }

  static Widget servers(AsyncValue<List<DevelopmentServer>> serversAsync) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns, size: 18, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'SERVERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            serversAsync.when(
              data: (servers) {
                if (servers.isEmpty) {
                  return _EmptyState(text: 'No development servers');
                }
                return Column(
                  children: servers.take(5).map((s) => _ServerRow(server: s)).toList(),
                );
              },
              loading: () => _LoadingState(),
              error: (e, _) => _ErrorState(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessRow extends StatelessWidget {
  final ProcessInfo process;

  _ProcessRow({required this.process});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: process.status == 'Running' ? AppTheme.successGreen : AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      process.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PID: ${process.pid}',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                if (process.projectName != null)
                  Text(
                    process.projectName!,
                    style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          Text(
            process.formattedMemory,
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${process.cpuPercent.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  final DevelopmentServer server;

  _ServerRow({required this.server});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: server.isHealthy ? AppTheme.successGreen : AppTheme.errorRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Port ${server.port}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                    if (server.framework != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: AppTheme.primaryRed),
                        ),
                        child: Text(
                          server.framework!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (server.projectName != null)
                  Text(
                    server.projectName!,
                    style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Open'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
        ),
      ),
    );
  }
}



