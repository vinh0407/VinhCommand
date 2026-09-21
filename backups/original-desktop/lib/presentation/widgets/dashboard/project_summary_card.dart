import 'package:flutter/material.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class ProjectSummaryCard extends StatelessWidget {
  final Project project;

  const ProjectSummaryCard({super.key, required this.project});

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
            _buildCommands(),
            const SizedBox(height: 12),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _getFrameworkColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _getFrameworkColor(), width: 1),
          ),
          child: Icon(
            _getFrameworkIcon(),
            color: _getFrameworkColor(),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                project.framework.label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        if (project.gitInfo != null)
          _GitStatusBadge(gitInfo: project.gitInfo!),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          icon: Icons.folder,
          label: 'Path',
          value: project.rootPath,
          fontFamily: 'JetBrainsMono',
        ),
        if (project.packageManager != null)
          _DetailRow(
            icon: Icons.inventory,
            label: 'Package Manager',
            value: project.packageManager!,
          ),
        if (project.languages.isNotEmpty)
          _DetailRow(
            icon: Icons.code,
            label: 'Languages',
            value: project.languages.join(', '),
          ),
        if (project.ports.isNotEmpty)
          _DetailRow(
            icon: Icons.dns,
            label: 'Ports',
            value: project.ports.map((p) => ':$p').join(', '),
            fontFamily: 'JetBrainsMono',
          ),
      ],
    );
  }

  Widget _buildCommands() {
    final commands = <String>[];
    if (project.devCommands.isNotEmpty) commands.add('Dev: ${project.devCommands.first}');
    if (project.buildCommands.isNotEmpty) commands.add('Build: ${project.buildCommands.first}');
    if (project.testCommands.isNotEmpty) commands.add('Test: ${project.testCommands.first}');

    if (commands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMANDS',
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
          children: commands.map((cmd) => _CommandChip(command: cmd)).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.terminal, size: 16),
            label: const Text('Terminal'),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.insert_drive_file, size: 16),
            label: const Text('Files'),
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 8),
        if (project.gitInfo != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.source, size: 16),
              label: const Text('Git'),
              onPressed: () {},
            ),
          ),
      ],
    );
  }

  Color _getFrameworkColor() {
    switch (project.framework) {
      case ProjectFramework.flutter:
        return const Color(0xFF02569B);
      case ProjectFramework.react:
      case ProjectFramework.nextjs:
        return const Color(0xFF61DAFB);
      case ProjectFramework.vite:
        return const Color(0xFF646CFF);
      case ProjectFramework.nodejs:
        return const Color(0xFF339933);
      case ProjectFramework.python:
      case ProjectFramework.fastapi:
      case ProjectFramework.django:
        return const Color(0xFF3776AB);
      case ProjectFramework.java:
      case ProjectFramework.spring:
        return const Color(0xFFED8B00);
      case ProjectFramework.android:
        return const Color(0xFF3DDC84);
      case ProjectFramework.dotnet:
      case ProjectFramework.csharp:
        return const Color(0xFF512BD4);
      case ProjectFramework.cpp:
        return const Color(0xFF00599C);
      case ProjectFramework.go:
        return const Color(0xFF00ADD8);
      case ProjectFramework.rust:
        return const Color(0xFFDEA584);
      case ProjectFramework.electron:
        return const Color(0xFF47848F);
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _getFrameworkIcon() {
    switch (project.framework) {
      case ProjectFramework.flutter:
        return Icons.flutter_dash;
      case ProjectFramework.react:
      case ProjectFramework.nextjs:
        return Icons.web;
      case ProjectFramework.vite:
        return Icons.bolt;
      case ProjectFramework.nodejs:
        return Icons.javascript;
      case ProjectFramework.python:
      case ProjectFramework.fastapi:
      case ProjectFramework.django:
        return Icons.code;
      case ProjectFramework.java:
      case ProjectFramework.spring:
        return Icons.coffee;
      case ProjectFramework.android:
        return Icons.android;
      case ProjectFramework.dotnet:
      case ProjectFramework.csharp:
        return Icons.window;
      case ProjectFramework.cpp:
        return Icons.memory;
      case ProjectFramework.go:
        return Icons.g_mobiledata;
      case ProjectFramework.rust:
        return Icons.settings_ethernet;
      case ProjectFramework.electron:
        return Icons.desktop_windows;
      default:
        return Icons.folder;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? fontFamily;

  _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
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
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandChip extends StatelessWidget {
  final String command;

  _CommandChip({required this.command});

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
        command,
        style: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _GitStatusBadge extends StatelessWidget {
  final GitInfo gitInfo;

  _GitStatusBadge({required this.gitInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: gitInfo.isClean ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.warningOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: gitInfo.isClean ? AppTheme.successGreen : AppTheme.warningOrange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            gitInfo.isClean ? Icons.check_circle : Icons.warning,
            size: 12,
            color: gitInfo.isClean ? AppTheme.successGreen : AppTheme.warningOrange,
          ),
          const SizedBox(width: 4),
          Text(
            gitInfo.currentBranch,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: gitInfo.isClean ? AppTheme.successGreen : AppTheme.warningOrange,
              fontFamily: 'JetBrainsMono',
            ),
          ),
          if (gitInfo.totalChanges > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: gitInfo.isClean ? AppTheme.successGreen : AppTheme.warningOrange,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${gitInfo.totalChanges}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


