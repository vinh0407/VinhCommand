import 'dart:io';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import '../../core/vinhcommand_core.dart';

class AgentDiscoveryService {
  static const Map<String, AgentDiscoveryConfig> _knownAgents = {
    'codex': AgentDiscoveryConfig(
      name: 'Codex',
      executables: ['codex.exe', 'codex.cmd'],
      paths: [
        r'$USERPROFILE\AppData\Local\Programs\Codex',
        r'$USERPROFILE\AppData\Local\Codex',
        r'$ProgramFiles\Codex',
        r'$ProgramFiles(x86)\Codex',
      ],
      versionArgs: ['--version'],
      capabilities: [
        AgentCapability.prompt,
        AgentCapability.streaming,
        AgentCapability.input,
        AgentCapability.stop,
        AgentCapability.projectContext,
        AgentCapability.fileEditing,
      ],
    ),
    'claude': AgentDiscoveryConfig(
      name: 'Claude Code',
      executables: ['claude.exe', 'claude.cmd'],
      paths: [
        r'$USERPROFILE\AppData\Local\Programs\Claude',
        r'$USERPROFILE\AppData\Local\Claude',
        r'$ProgramFiles\Claude',
      ],
      versionArgs: ['--version'],
      capabilities: [
        AgentCapability.prompt,
        AgentCapability.streaming,
        AgentCapability.input,
        AgentCapability.stop,
        AgentCapability.projectContext,
        AgentCapability.fileEditing,
        AgentCapability.terminal,
      ],
    ),
    'gemini': AgentDiscoveryConfig(
      name: 'Gemini CLI',
      executables: ['gemini.exe', 'gemini.cmd'],
      paths: [
        r'$USERPROFILE\AppData\Local\Programs\Gemini',
        r'$USERPROFILE\AppData\Local\Gemini',
      ],
      versionArgs: ['--version'],
      capabilities: [
        AgentCapability.prompt,
        AgentCapability.streaming,
        AgentCapability.input,
        AgentCapability.stop,
        AgentCapability.projectContext,
      ],
    ),
    'antigravity': AgentDiscoveryConfig(
      name: 'Antigravity',
      executables: ['antigravity.exe', 'ag.exe'],
      paths: [
        r'$USERPROFILE\AppData\Local\Programs\Antigravity',
      ],
      versionArgs: ['--version'],
      capabilities: [
        AgentCapability.prompt,
        AgentCapability.streaming,
        AgentCapability.input,
        AgentCapability.stop,
      ],
    ),
  };

  final AgentRepository _repository;
  final AgentAdapterRepository _adapterRepository;

  AgentDiscoveryService(this._repository, this._adapterRepository);

  Future<List<Agent>> discoverAgents() async {
    final agents = <Agent>[];

    for (final entry in _knownAgents.entries) {
      try {
        final agent = await _discoverAgent(entry.key, entry.value);
        if (agent != null) {
          agents.add(agent);
        }
      } catch (e) {
        agents.add(Agent(
          id: AgentId.generate(),
          name: entry.value.name,
          version: 'Unknown',
          executable: '',
          path: '',
          status: AgentStatus.failed,
          running: false,
          authenticated: false,
          capabilities: [],
          metadata: {'error': e.toString()},
          discoveredAt: DateTime.now(),
        ));
      }
    }

    await _saveDiscoveredAgents(agents);
    return agents;
  }

  Future<Agent?> _discoverAgent(String key, AgentDiscoveryConfig config) async {
    final executablePath = await _findExecutable(config);

    if (executablePath == null) {
      return Agent(
        id: AgentId.generate(),
        name: config.name,
        version: 'Not Found',
        executable: '',
        path: '',
        status: AgentStatus.notFound,
        running: false,
        authenticated: false,
        capabilities: [],
        metadata: {},
        discoveredAt: DateTime.now(),
      );
    }

    final version = await _getVersion(executablePath, config.versionArgs);
    final isRunning = await _isProcessRunning(config.executables.first);
    final authenticated = await _checkAuthentication(key, executablePath);
    final capabilities = await _detectCapabilities(key, executablePath);

    return Agent(
      id: AgentId.generate(),
      name: config.name,
      version: version,
      executable: executablePath,
      path: executablePath,
      status: isRunning ? AgentStatus.running : AgentStatus.available,
      running: isRunning,
      authenticated: authenticated,
      capabilities: capabilities,
      metadata: {},
      discoveredAt: DateTime.now(),
      lastCheckedAt: DateTime.now(),
    );
  }

  Future<String?> _findExecutable(AgentDiscoveryConfig config) async {
    for (final basePath in config.paths) {
      final expandedPath = _expandPath(basePath);
      if (await Directory(expandedPath).exists()) {
        for (final exe in config.executables) {
          final fullPath = '${expandedPath}\\$exe';
          if (await File(fullPath).exists()) {
            return fullPath;
          }
        }
      }
    }

    final pathEnv = Platform.environment['PATH'] ?? '';
    for (final pathDir in pathEnv.split(';')) {
      for (final exe in config.executables) {
        final fullPath = '${pathDir}\\$exe';
        if (await File(fullPath).exists()) {
          return fullPath;
        }
      }
    }

    return null;
  }

  String _expandPath(String path) {
    return path
        .replaceAll(r'$USERPROFILE', Platform.environment['USERPROFILE'] ?? '')
        .replaceAll(r'$ProgramFiles', Platform.environment['ProgramFiles'] ?? '')
        .replaceAll(r'$ProgramFiles(x86)', Platform.environment['ProgramFiles(x86)'] ?? '')
        .replaceAll(r'$APPDATA', Platform.environment['APPDATA'] ?? '')
        .replaceAll(r'$LOCALAPPDATA', Platform.environment['LOCALAPPDATA'] ?? '');
  }

  Future<String> _getVersion(String executable, List<String> args) async {
    try {
      final process = await Process.run(executable, args);
      if (process.exitCode == 0) {
        return process.stdout.toString().trim().split('\n').first;
      }
    } catch (_) {}
    return 'Unknown';
  }

  Future<bool> _isProcessRunning(String exeName) async {
    try {
      final process = await Process.run(
        'tasklist',
        ['/FI', 'IMAGENAME eq $exeName', '/FO', 'CSV'],
      );
      return process.stdout.toString().contains(exeName);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkAuthentication(String agentKey, String executable) async {
    switch (agentKey) {
      case 'codex':
        return await _checkCodexAuth(executable);
      case 'claude':
        return await _checkClaudeAuth(executable);
      case 'gemini':
        return await _checkGeminiAuth(executable);
      default:
        return false;
    }
  }

  Future<bool> _checkCodexAuth(String executable) async {
    try {
      final process = await Process.run(executable, ['auth', 'status']);
      return process.exitCode == 0 &&
          process.stdout.toString().toLowerCase().contains('authenticated');
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkClaudeAuth(String executable) async {
    try {
      final process = await Process.run(executable, ['auth', 'status']);
      return process.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkGeminiAuth(String executable) async {
    try {
      final process = await Process.run(executable, ['auth', 'status']);
      return process.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<List<AgentCapability>> _detectCapabilities(String agentKey, String executable) async {
    final baseCapabilities = _knownAgents[agentKey]?.capabilities ?? [];
    final detected = <AgentCapability>[...baseCapabilities];

    try {
      final process = await Process.run(executable, ['--help']);
      final help = process.stdout.toString().toLowerCase();

      if (help.contains('terminal') || help.contains('shell')) {
        detected.add(AgentCapability.terminal);
      }
      if (help.contains('gui') || help.contains('ui')) {
        detected.add(AgentCapability.gui);
      }
      if (help.contains('screen') || help.contains('capture')) {
        detected.add(AgentCapability.screen);
      }
    } catch (_) {}

    return detected.toSet().toList();
  }

  Future<void> _saveDiscoveredAgents(List<Agent> agents) async {
    for (final agent in agents) {
      await _repository.saveAgent(agent);
    }
  }

  Future<void> refreshAgent(AgentId id) async {
    final agent = await _repository.getAgentById(id);
    if (agent == null) return;

    final config = _knownAgents.entries.firstWhere(
      (e) => e.value.name == agent.name,
      orElse: () => MapEntry('', AgentDiscoveryConfig(
        name: '',
        executables: [],
        paths: [],
        versionArgs: [],
        capabilities: [],
      )),
    );

    if (config.key.isEmpty) return;

    final updated = await _discoverAgent(config.key, config.value);
    if (updated != null) {
      await _repository.saveAgent(updated);
    }
  }
}

class AgentDiscoveryConfig {
  final String name;
  final List<String> executables;
  final List<String> paths;
  final List<String> versionArgs;
  final List<AgentCapability> capabilities;

  const AgentDiscoveryConfig({
    required this.name,
    required this.executables,
    required this.paths,
    required this.versionArgs,
    required this.capabilities,
  });
}


