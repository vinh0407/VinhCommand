import 'dart:io';
import '../../core/vinhcommand_core.dart';

class WindowsSystemRepository implements SystemRepository {
  @override
  Future<SystemInfo> getSystemInfo() async {
    try {
      final osInfo = await getOsInfo();
      final cpuInfo = await getCpuInfo();
      final memoryInfo = await getMemoryInfo();
      final disks = await getDiskInfo();
      final gpus = await getGpuInfo();
      final networks = await getNetworkInterfaces();
      final bootTime = await getBootTime();

      return SystemInfo(
        osName: osInfo['name'] ?? 'Windows',
        osVersion: osInfo['version'] ?? 'Unknown',
        osBuild: osInfo['build'] ?? 'Unknown',
        cpuName: cpuInfo.name,
        cpuCores: cpuInfo.cores,
        cpuThreads: cpuInfo.threads,
        cpuFrequencyGhz: cpuInfo.frequencyGhz,
        totalRamGb: memoryInfo.totalGb,
        availableRamGb: memoryInfo.availableGb,
        gpus: gpus,
        disks: disks,
        networks: networks,
        bootTime: bootTime,
        discoveredAt: DateTime.now(),
      );
    } catch (e) {
      throw SystemDiscoveryException(
        message: 'Failed to get system info: $e',
        suggestedAction: 'Check Windows permissions and WMI availability',
      );
    }
  }

  static Future<Map<String, String>> getOsInfo() async {
    final result = <String, String>{};

    try {
      final process = await Process.run('cmd', ['/c', 'ver']);
      final output = process.stdout.toString().trim();
      if (output.isNotEmpty) {
        result['version'] = output;
      }
    } catch (e) {}

    try {
      final process = await Process.run(
        'powershell',
        ['-Command', '(Get-CimInstance Win32_OperatingSystem).Caption'],
      );
      final output = process.stdout.toString().trim();
      if (output.isNotEmpty) {
        result['name'] = output;
      }
    } catch (e) {}

    try {
      final process = await Process.run(
        'powershell',
        ['-Command', '(Get-CimInstance Win32_OperatingSystem).BuildNumber'],
      );
      final output = process.stdout.toString().trim();
      if (output.isNotEmpty) {
        result['build'] = output;
      }
    } catch (e) {}

    return result;
  }

  @override
  Future<CpuInfo> getCpuInfo() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          $cpu = Get-CimInstance Win32_Processor
          $usage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
          $cores = $cpu.NumberOfLogicalProcessors
          $threads = $cpu.NumberOfLogicalProcessors
          $name = $cpu.Name
          $freq = $cpu.MaxClockSpeed / 1000
          "$name|$cores|$threads|$freq|$usage"
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      final parts = output.split('|');

      if (parts.length >= 5) {
        final perCoreUsage = await getPerCoreUsage();
        return CpuInfo(
          name: parts[0],
          cores: int.tryParse(parts[1]) ?? 1,
          threads: int.tryParse(parts[2]) ?? 1,
          frequencyGhz: double.tryParse(parts[3]) ?? 0.0,
          usagePercent: double.tryParse(parts[4]) ?? 0.0,
          perCoreUsage: perCoreUsage,
        );
      }
    } catch (e) {}

    return CpuInfo(
      name: 'Unknown CPU',
      cores: 1,
      threads: 1,
      frequencyGhz: 0.0,
      usagePercent: 0.0,
      perCoreUsage: [],
    );
  }

  static Future<List<double>> getPerCoreUsage() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          Get-Counter "\Processor(*)\% Processor Time" | 
          Select-Object -ExpandProperty CounterSamples | 
          Where-Object {$_.InstanceName -ne "_Total"} | 
          Select-Object -ExpandProperty CookedValue
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      return output
          .split('\n')
          .map((e) => double.tryParse(e.trim()) ?? 0.0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MemoryInfo> getMemoryInfo() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          $os = Get-CimInstance Win32_OperatingSystem
          $total = [math]::Round($os.TotalVisibleMemorySize / 1MB)
          $free = [math]::Round($os.FreePhysicalMemory / 1MB)
          $used = $total - $free
          $percent = [math]::Round(($used / $total) * 100)
          "$total|$free|$used|$percent"
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      final parts = output.split('|');

      if (parts.length >= 4) {
        return MemoryInfo(
          totalBytes: (int.tryParse(parts[0]) ?? 0) * 1024 * 1024,
          availableBytes: (int.tryParse(parts[1]) ?? 0) * 1024 * 1024,
          usedBytes: (int.tryParse(parts[2]) ?? 0) * 1024 * 1024,
          usagePercent: double.tryParse(parts[3]) ?? 0.0,
        );
      }
    } catch (e) {}

    return MemoryInfo(
      totalBytes: 0,
      availableBytes: 0,
      usedBytes: 0,
      usagePercent: 0.0,
    );
  }

  @override
  Future<List<DiskInfo>> getDiskInfo() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | 
          ForEach-Object {
            $total = [math]::Round($_.Size / 1GB, 1)
            $free = [math]::Round($_.FreeSpace / 1GB, 1)
            "$($_.DeviceID)|$($_.FileSystem)|$total|$free|Fixed"
          }
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      final lines = output.split('\n');
      final disks = <DiskInfo>[];

      for (final line in lines) {
        final parts = line.trim().split('|');
        if (parts.length >= 5) {
          disks.add(DiskInfo(
            name: parts[0],
            type: parts[4],
            totalGb: (double.tryParse(parts[2]) ?? 0).round(),
            freeGb: (double.tryParse(parts[3]) ?? 0).round(),
            filesystem: parts[1],
          ));
        }
      }

      return disks;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<GpuInfo>> getGpuInfo() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          Get-CimInstance Win32_VideoController | Where-Object {$_.AdapterRAM -gt 0} | 
          ForEach-Object {
            $vram = [math]::Round($_.AdapterRAM / 1MB)
            "$($_.Name)|$($_.DriverVersion)|$vram|0"
          }
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      final lines = output.split('\n');
      final gpus = <GpuInfo>[];

      for (final line in lines) {
        final parts = line.trim().split('|');
        if (parts.length >= 4) {
          gpus.add(GpuInfo(
            name: parts[0],
            driverVersion: parts[1],
            vramMb: int.tryParse(parts[2]) ?? 0,
            usagePercent: int.tryParse(parts[3]) ?? 0,
          ));
        }
      }

      return gpus;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<NetworkInterface>> getNetworkInterfaces() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          r'''
          Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | 
          ForEach-Object {
            $ip = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).IPAddress
            "$($_.Name)|$ip|$($_.MacAddress)|$($_.Status -eq "Up")|$($_.LinkSpeed / 1MB)"
          }
          ''',
        ],
      );

      final output = process.stdout.toString().trim();
      final lines = output.split('\n');
      final interfaces = <NetworkInterface>[];

      for (final line in lines) {
        final parts = line.trim().split('|');
        if (parts.length >= 5) {
          interfaces.add(NetworkInterface(
            name: parts[0],
            ipAddress: parts[1],
            macAddress: parts[2],
            isUp: parts[3].toLowerCase() == 'true',
            speedMbps: int.tryParse(parts[4]) ?? 0,
          ));
        }
      }

      return interfaces;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DateTime> getBootTime() async {
    try {
      final process = await Process.run(
        'powershell',
        [
          '-Command',
          '(Get-CimInstance Win32_OperatingSystem).LastBootUpTime',
        ],
      );

      final output = process.stdout.toString().trim();
      if (output.isNotEmpty) {
        return DateTime.parse(output);
      }
    } catch (e) {}

    return DateTime.now().subtract(const Duration(hours: 1));
  }
}

class SystemDiscoveryException extends VinhCommandException {
  const SystemDiscoveryException({
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'SYSTEM_DISCOVERY_FAILED',
        );
}