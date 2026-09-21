import 'package:equatable/equatable.dart';

class SystemInfo extends Equatable {
  final String osName;
  final String osVersion;
  final String osBuild;
  final String cpuName;
  final int cpuCores;
  final int cpuThreads;
  final double cpuFrequencyGhz;
  final int totalRamGb;
  final int availableRamGb;
  final List<GpuInfo> gpus;
  final List<DiskInfo> disks;
  final List<NetworkInterface> networks;
  final DateTime bootTime;
  final DateTime discoveredAt;

  const SystemInfo({
    required this.osName,
    required this.osVersion,
    required this.osBuild,
    required this.cpuName,
    required this.cpuCores,
    required this.cpuThreads,
    required this.cpuFrequencyGhz,
    required this.totalRamGb,
    required this.availableRamGb,
    required this.gpus,
    required this.disks,
    required this.networks,
    required this.bootTime,
    required this.discoveredAt,
  });

  @override
  List<Object?> get props => [
        osName,
        osVersion,
        osBuild,
        cpuName,
        cpuCores,
        cpuThreads,
        cpuFrequencyGhz,
        totalRamGb,
        availableRamGb,
        gpus,
        disks,
        networks,
        bootTime,
        discoveredAt,
      ];

  double get ramUsagePercent => totalRamGb > 0
      ? ((totalRamGb - availableRamGb) / totalRamGb * 100).clamp(0, 100)
      : 0;

  String get formattedTotalRam => '${totalRamGb} GB';
  String get formattedAvailableRam => '${availableRamGb} GB';
}

class GpuInfo extends Equatable {
  final String name;
  final String driverVersion;
  final int vramMb;
  final int usagePercent;

  const GpuInfo({
    required this.name,
    required this.driverVersion,
    required this.vramMb,
    required this.usagePercent,
  });

  @override
  List<Object?> get props => [name, driverVersion, vramMb, usagePercent];

  String get formattedVram => vramMb >= 1024
      ? '${(vramMb / 1024).toStringAsFixed(1)} GB'
      : '$vramMb MB';
}

class DiskInfo extends Equatable {
  final String name;
  final String type;
  final int totalGb;
  final int freeGb;
  final String filesystem;

  const DiskInfo({
    required this.name,
    required this.type,
    required this.totalGb,
    required this.freeGb,
    required this.filesystem,
  });

  @override
  List<Object?> get props => [name, type, totalGb, freeGb, filesystem];

  double get usagePercent => totalGb > 0
      ? ((totalGb - freeGb) / totalGb * 100).clamp(0, 100)
      : 0;

  String get formattedTotal => '${totalGb} GB';
  String get formattedFree => '${freeGb} GB';
}

class NetworkInterface extends Equatable {
  final String name;
  final String ipAddress;
  final String macAddress;
  final bool isUp;
  final int speedMbps;

  const NetworkInterface({
    required this.name,
    required this.ipAddress,
    required this.macAddress,
    required this.isUp,
    required this.speedMbps,
  });

  @override
  List<Object?> get props => [name, ipAddress, macAddress, isUp, speedMbps];
}