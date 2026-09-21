import 'package:flutter/material.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class TaskSummaryCard extends StatelessWidget {
  final List<Task> tasks;

  const TaskSummaryCard({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final counts = _getStateCounts();
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(counts),
            const SizedBox(height: 16),
            _buildStateBreakdown(counts),
            const SizedBox(height: 16),
            _buildRecentTasks(),
          ],
        ),
      ),
    );
  }

  Map<TaskState, int> _getStateCounts() {
    final counts = <TaskState, int>{};
    for (final state in TaskState.values) {
      counts[state] = 0;
    }
    for (final task in tasks) {
      counts[task.state] = (counts[task.state] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildHeader(Map<TaskState, int> counts) {
    return Row(
      children: [
        const Icon(Icons.task_alt, size: 20, color: AppTheme.primaryRed),
        const SizedBox(width: 8),
        const Text(
          'TASKS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Text(
          '${tasks.length} total',
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStateBreakdown(Map<TaskState, int> counts) {
    final activeStates = [
      TaskState.queued,
      TaskState.starting,
      TaskState.running,
      TaskState.waitingForInput,
      TaskState.waitingForApproval,
    ];


    return Column(
      children: [
        _StateBreakdownRow(
          label: 'Active',
          count: activeStates.fold(0, (sum, s) => sum + (counts[s] ?? 0)),
          color: AppTheme.infoBlue,
        ),
        const SizedBox(height: 8),
        _StateBreakdownRow(
          label: 'Completed',
          count: counts[TaskState.completed] ?? 0,
          color: AppTheme.successGreen,
        ),
        const SizedBox(height: 8),
        _StateBreakdownRow(
          label: 'Failed',
          count: counts[TaskState.failed] ?? 0,
          color: AppTheme.errorRed,
        ),
        const SizedBox(height: 8),
        _StateBreakdownRow(
          label: 'Stopped/Cancelled',
          count: (counts[TaskState.stopped] ?? 0) + (counts[TaskState.cancelled] ?? 0),
          color: AppTheme.textMuted,
        ),
      ],
    );
  }

  Widget _buildRecentTasks() {
    final recentTasks = tasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...recentTasks.map((task) => _RecentTaskRow(task: task)),
      ],
    );
  }
}

class _StateBreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StateBreakdownRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RecentTaskRow extends StatelessWidget {
  final Task task;

  const _RecentTaskRow({required this.task});

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
              color: _getStateColor(task.state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.prompt.length > 50 ? '${task.prompt.substring(0, 50)}...' : task.prompt,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${task.state.label} • ${_formatDuration(task.duration)}',
                  style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            task.state.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: _getStateColor(task.state),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(TaskState state) {
    switch (state) {
      case TaskState.queued:
      case TaskState.starting:
      case TaskState.running:
      case TaskState.waitingForInput:
      case TaskState.waitingForApproval:
        return AppTheme.infoBlue;
      case TaskState.completed:
        return AppTheme.successGreen;
      case TaskState.failed:
        return AppTheme.errorRed;
      case TaskState.stopped:
      case TaskState.cancelled:
        return AppTheme.textMuted;
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}



