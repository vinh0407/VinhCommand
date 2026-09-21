import 'package:flutter/material.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class AgentStatusCard extends StatelessWidget {
  final Agent agent;

  const AgentStatusCard({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildInfo(),
            const SizedBox(height: 16),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(), width: 1),
          ),
          child: Icon(
            _getAgentIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agent.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'v${agent.version}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        _StatusBadge(status: agent.status),
      ],
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(label: 'Executable', value: agent.executable, fontFamily: 'JetBrainsMono'),
        const SizedBox(height: 8),
        _InfoRow(label: 'Path', value: agent.path, fontFamily: 'JetBrainsMono'),
        if (agent.errorMessage != null) ...[
          const SizedBox(height: 8),
          _InfoRow(label: 'Error', value: agent.errorMessage!, fontFamily: 'JetBrainsMono', valueColor: AppTheme.errorRed),
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
          spacing: 6,
          runSpacing: 6,
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
              icon: Icon(agent.running ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(agent.running ? 'Stop' : 'Launch'),
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: agent.running ? AppTheme.errorRed : AppTheme.successGreen,
                side: BorderSide(
                  color: agent.running ? AppTheme.errorRed : AppTheme.successGreen,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: OutlinedButton(
              onPressed: null,
              child: Text(agent.status == AgentStatus.notFound ? 'Install' : 'Unavailable'),
            ),
          ),
const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.terminal, size: 16),
          label: const Text('Terminal'),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.bug_report, size: 16),
          label: const Text('Diagnostics'),
          onPressed: () {},
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? fontFamily;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.fontFamily,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: fontFamily,
              color: valueColor ?? AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMedium,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        capability.label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}


