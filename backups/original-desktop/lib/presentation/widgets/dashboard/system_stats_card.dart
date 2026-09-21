import 'package:flutter/material.dart';
import 'package:vinhcommand_desktop/core/vinhcommand_core.dart';
import 'package:vinhcommand_desktop/presentation/vinhcommand_presentation.dart';

class SystemStatsCard {
  static Widget cpu(SystemInfo info) {
    final cpu = info.cpuName;
    final cores = info.cpuCores;
    final threads = info.cpuThreads;
    final freq = info.cpuFrequencyGhz;

    return _StatCard(
      title: 'CPU',
      icon: Icons.memory,
      iconColor: AppTheme.successGreen,
      children: [
        _StatRow(label: 'Name', value: cpu, fontFamily: 'JetBrainsMono'),
        _StatRow(label: 'Cores/Threads', value: '$cores / $threads'),
        _StatRow(label: 'Frequency', value: '${freq.toStringAsFixed(1)} GHz'),
        _StatRow(label: 'Usage', value: '${info.gpus.isNotEmpty ? 'N/A' : 'N/A'}', isProgress: true),
      ],
    );
  }

  static Widget memory(SystemInfo info) {
    return _StatCard(
      title: 'MEMORY',
      icon: Icons.storage,
      iconColor: AppTheme.warningOrange,
      children: [
        _StatRow(
          label: 'Total',
          value: info.formattedTotalRam,
        ),
        _StatRow(
          label: 'Available',
          value: info.formattedAvailableRam,
        ),
        _StatRow(
          label: 'Usage',
          value: '${info.ramUsagePercent.toStringAsFixed(1)}%',
          isProgress: true,
          progressValue: info.ramUsagePercent / 100,
        ),
      ],
    );
  }

  static Widget gpu(SystemInfo info) {
    if (info.gpus.isEmpty) {
      return _StatCard(
        title: 'GPU',
        icon: Icons.videogame_asset,
        iconColor: AppTheme.infoBlue,
        children: [
          _StatRow(label: 'Status', value: 'Not detected'),
        ],
      );
    }

    final gpu = info.gpus.first;
    return _StatCard(
      title: 'GPU',
      icon: Icons.videogame_asset,
      iconColor: AppTheme.infoBlue,
      children: [
        _StatRow(label: 'Name', value: gpu.name, fontFamily: 'JetBrainsMono'),
        _StatRow(label: 'VRAM', value: gpu.formattedVram),
        _StatRow(label: 'Driver', value: gpu.driverVersion),
        _StatRow(
          label: 'Usage',
          value: '${gpu.usagePercent}%',
          isProgress: true,
          progressValue: gpu.usagePercent / 100,
        ),
      ],
    );
  }

  static Widget disk(SystemInfo info) {
    if (info.disks.isEmpty) {
      return _StatCard(
        title: 'DISK',
icon: Icons.storage,
        iconColor: AppTheme.textMuted,
        children: [
          _StatRow(label: 'Status', value: 'Not detected'),
        ],
      );
    }

    final totalSpace = info.disks.fold<int>(0, (sum, d) => sum + d.totalGb);
    final freeSpace = info.disks.fold<int>(0, (sum, d) => sum + d.freeGb);
    final usage = totalSpace > 0 ? ((totalSpace - freeSpace) / totalSpace * 100) : 0.0;

    return _StatCard(
      title: 'DISK',
      icon: Icons.storage,
      iconColor: AppTheme.textMuted,
      children: [
        _StatRow(label: 'Total', value: '${totalSpace} GB'),
        _StatRow(label: 'Free', value: '${freeSpace} GB'),
        _StatRow(
          label: 'Usage',
          value: '${usage.toStringAsFixed(1)}%',
          isProgress: true,
          progressValue: usage / 100,
        ),
        _StatRow(label: 'Drives', value: '${info.disks.length}'),
      ],
    );
  }

  static Widget network(SystemInfo info) {
    final upInterfaces = info.networks.where((n) => n.isUp).length;

    return _StatCard(
      title: 'NETWORK',
      icon: Icons.wifi,
      iconColor: AppTheme.primaryRed,
      children: [
        _StatRow(label: 'Interfaces Up', value: '$upInterfaces / ${info.networks.length}'),
        if (info.networks.isNotEmpty) ...[
          _StatRow(label: 'Primary IP', value: info.networks.first.ipAddress),
          _StatRow(label: 'Speed', value: '${info.networks.first.speedMbps} Mbps'),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? fontFamily;
  final bool isProgress;
  final double? progressValue;

  const _StatRow({
    required this.label,
    required this.value,
    this.fontFamily,
    this.isProgress = false,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: fontFamily,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (isProgress && progressValue != null) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progressValue!.clamp(0.0, 1.0),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressValue! > 0.8 ? AppTheme.errorRed :
                progressValue! > 0.6 ? AppTheme.warningOrange : AppTheme.successGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


