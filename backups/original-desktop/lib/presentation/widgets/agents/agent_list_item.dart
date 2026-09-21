import 'package:flutter/material.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class AgentListItem extends StatelessWidget {
  final Agent agent;

  const AgentListItem({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildDetails(),
            const SizedBox(height: 12),
            _buildCapabilities(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _getStatusColor(), width: 1),
          ),
          child: Icon(
            _getAgentIcon(),
            color: _getStatusColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    agent.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: agent.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Version ${agent.version}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (agent.running)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.successGreen),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'RUNNING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        Expanded(
          child: _DetailItem(
            label: 'Executable',
            value: agent.executable,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _DetailItem(
            label: 'Path',
            value: agent.path,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        if (agent.lastCheckedAt != null) ...[
          const SizedBox(width: 24),
          Expanded(
            child: _DetailItem(
              label: 'Last Checked',
              value: _formatDateTime(agent.lastCheckedAt!),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCapabilities() {
    if (agent.capabilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CAPABILITIES',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: agent.capabilities.map((cap) => _CapabilityChip(capability: cap)).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (agent.canLaunch)
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(agent.running ? Icons.stop : Icons.play_arrow, size: 18),
              label: Text(agent.running ? 'Stop Agent' : 'Launch Agent'),
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: agent.running ? AppTheme.errorRed : AppTheme.successGreen,
                side: BorderSide(
                  color: agent.running ? AppTheme.errorRed : AppTheme.successGreen,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        else
          Expanded(
            child: OutlinedButton(
              onPressed: null,
              child: Text(
                agent.status == AgentStatus.notFound 
                    ? 'Install Agent' 
                    : agent.status == AgentStatus.failed 
                        ? 'Retry' 
                        : 'Unavailable',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.terminal, size: 18),
          label: const Text('Terminal'),
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.bug_report, size: 18),
          label: const Text('Diagnostics'),
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Configuration')),
            const PopupMenuItem(value: 'logs', child: Text('View Logs')),
            const PopupMenuItem(value: 'uninstall', child: Text('Uninstall')),
          ],
          onSelected: (value) {},
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (agent.status) {
      case AgentStatus.running:
      case AgentStatus.authenticated:
      case AgentStatus.available:
        return AppTheme.successGreen;
      case AgentStatus.installed:
      case AgentStatus.notAuthenticated:
        return AppTheme.warningOrange;
      case AgentStatus.notFound:
      case AgentStatus.failed:
      case AgentStatus.unsupported:
        return AppTheme.errorRed;
    }
  }

  IconData _getAgentIcon() {
    final name = agent.name.toLowerCase();
    if (name.contains('codex')) return Icons.code;
    if (name.contains('claude')) return Icons.psychology;
    if (name.contains('gemini')) return Icons.auto_awesome;
    if (name.contains('antigravity')) return Icons.rocket_launch;
    return Icons.smart_toy;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final AgentStatus status;

  _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case AgentStatus.running:
      case AgentStatus.authenticated:
      case AgentStatus.available:
        color = AppTheme.successGreen;
        break;
      case AgentStatus.installed:
      case AgentStatus.notAuthenticated:
        color = AppTheme.warningOrange;
        break;
      case AgentStatus.notFound:
      case AgentStatus.failed:
      case AgentStatus.unsupported:
        color = AppTheme.errorRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final String? fontFamily;

  _DetailItem({
    required this.label,
    required this.value,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            fontFamily: fontFamily,
            color: AppTheme.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final AgentCapability capability;

  _CapabilityChip({required this.capability});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCapabilityIcon(capability), size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            capability.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCapabilityIcon(AgentCapability cap) {
    switch (cap) {
      case AgentCapability.prompt:
        return Icons.chat;
      case AgentCapability.streaming:
        return Icons.stream;
      case AgentCapability.input:
        return Icons.keyboard;
      case AgentCapability.stop:
        return Icons.stop;
      case AgentCapability.pause:
        return Icons.pause;
      case AgentCapability.resume:
        return Icons.play_arrow;
      case AgentCapability.projectContext:
        return Icons.folder;
      case AgentCapability.terminal:
        return Icons.terminal;
      case AgentCapability.fileEditing:
        return Icons.edit;
      case AgentCapability.gui:
        return Icons.window;
      case AgentCapability.screen:
        return Icons.monitor;
    }
  }
}


