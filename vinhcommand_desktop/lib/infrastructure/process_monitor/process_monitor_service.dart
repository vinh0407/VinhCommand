import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/vinhcommand_core.dart';

class ProcessMonitorService implements ProcessRepository {
  final Map<int, ProcessInfo> _processCache = {};
  Timer? _refreshTimer;

  @override
  Future<List<ProcessInfo>> getAllProcesses() async {
    try {
      final process = await Process.run('powershell', [
        '-Command',
        r'''
        Get-Process | Select-Object Id, ProcessName, CPU, WorkingSet64, Responding, 
          @{Name="ParentId";Expression={$_.Parent.Id}}, 
          @{Name="CommandLine";Expression={$_.CommandLine}}, 
          @{Name="StartTime";Expression={$_.StartTime}}, 
          @{Name="UserName";Expression={$_.UserName}} |
        ConvertTo-Json -Depth 3
        ''',
      ]);

      if (process.exitCode != 0) {
        throw ProcessException(
          code: 'PROCESS_LIST_FAILED',
          message: 'Failed to get process list',
        );
      }

      final output = process.stdout.toString();
      if (output.trim().isEmpty) return [];

      final List<dynamic> data = jsonDecode(output);
      final processes = data.map((json) => parseProcessInfo(json)).toList();
      
      _processCache.clear();
      for (final p in processes) {
        _processCache[p.pid] = p;
      }

      return processes;
    } catch (e) {
      throw ProcessException(
        code: 'PROCESS_LIST_FAILED',
        message: 'Failed to get process list: $e',
      );
    }
  }

  static ProcessInfo parseProcessInfo(Map<String, dynamic> json) {
    return ProcessInfo(
      pid: json['Id'] ?? 0,
      name: json['ProcessName'] ?? 'Unknown',
      executablePath: json['Path'],
      cpuPercent: (json['CPU'] as num?)?.toDouble() ?? 0.0,
      memoryMb: ((json['WorkingSet64'] as int?) ?? 0) ~/ (1024 * 1024),
      status: json['Responding'] == true ? 'Running' : 'Not Responding',
      parentPid: json['ParentId'],
      commandLine: json['CommandLine'] ?? '',
      projectName: null,
      startTime: json['StartTime'] != null ? DateTime.tryParse(json['StartTime']) : null,
      username: json['UserName'],
    );
  }

  @override
  Future<ProcessInfo?> getProcessByPid(int pid) async {
    if (_processCache.containsKey(pid)) {
      return _processCache[pid];
    }

    try {
      final process = await Process.run('powershell', [
        '-Command',
        r'''
        $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($p) {
          $p | Select-Object Id, ProcessName, CPU, WorkingSet64, Responding, 
            @{Name="ParentId";Expression={$_.Parent.Id}}, 
            @{Name="CommandLine";Expression={$_.CommandLine}}, 
            @{Name="StartTime";Expression={$_.StartTime}}, 
            @{Name="UserName";Expression={$_.UserName}} |
          ConvertTo-Json -Depth 3
        }
        ''',
      ]);

      if (process.exitCode == 0 && process.stdout.toString().trim().isNotEmpty) {
        final json = jsonDecode(process.stdout.toString());
        return parseProcessInfo(json);
      }
    } catch (e) {}

    return null;
  }

  Future<void> startProcessMonitoring({Duration interval = const Duration(seconds: 5)}) async {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) async {
      try {
        await getAllProcesses();
      } catch (e) {
        // Ignore refresh errors
      }
    });
  }

  Future<void> stopProcessMonitoring() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<List<ProcessInfo>> getProcessTree() async {
    // Simplified - return flat list for now
    return getAllProcesses();
  }

  @override
  Future<bool> killProcess(int pid, {bool force = false}) async {
    try {
      final process = await Process.run('powershell', [
        '-Command',
        r'''
        $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($p) {
          if ($force) { Stop-Process -Id $pid -Force } else { Stop-Process -Id $pid }
          "OK"
        } else {
          "NOT_FOUND"
        }
        ''',
      ]);

      return process.stdout.toString().trim() == 'OK';
    } catch (e) {
      return false;
    }
  }

  Future<ProcessInfo?> getProcessDetails(int pid) async {
    return getProcessByPid(pid);
  }

  @override
  Future<List<ProcessInfo>> getProcessesByName(String name) async {
    final all = await getAllProcesses();
    return all.where((p) => p.name.toLowerCase().contains(name.toLowerCase())).toList();
  }

  @override
  Future<List<ProcessInfo>> getDevelopmentProcesses() async {
    final all = await getAllProcesses();
    return all.where((p) => p.isDevelopmentProcess).toList();
  }

  @override
  Future<int> startProcess({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    return process.pid;
  }

  @override
  Future<ProcessOutput> runCommand({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    Map<String, String>? environment,
    Duration? timeout,
  }) async {
    final startTime = DateTime.now();
    final result = await Process.run(executable, arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    ).timeout(timeout ?? const Duration(seconds: 30));
    return ProcessOutput(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      duration: DateTime.now().difference(startTime),
    );
  }
}

class ProcessException extends VinhCommandException {
  const ProcessException({
    required super.code,
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}
