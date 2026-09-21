import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../core/vinhcommand_core.dart';

class AgentDiscoveryService {
  static const Map<String, AgentDiscoveryConfig> _knownAgents = {
    'codex': AgentDiscoveryConfig(
      name: 'Codex',
      executables: ['codex.cmd', 'codex.exe'],
      paths: [
        r'$APPDATA\npm',
        r'$USERPROFILE\AppData\Roaming\npm',
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
        r'$APPDATA\npm',
        r'$USERPROFILE\AppData\Roaming\npm',
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
        r'$APPDATA\npm',
        r'$USERPROFILE\AppData\Roaming\npm',
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
      executables: ['agentapi.bat', 'antigravity-ide.cmd', 'Antigravity.exe', 'antigravity.exe', 'ag.exe'],
      paths: [
        r'$USERPROFILE\.gemini\antigravity\bin',
        r'$USERPROFILE\AppData\Local\Programs\Antigravity IDE\bin',
        r'$USERPROFILE\AppData\Local\Programs\antigravity',
        r'$LOCALAPPDATA\Programs\antigravity',
        r'$APPDATA\npm',
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
    'chatgpt-web': AgentDiscoveryConfig(
      name: 'ChatGPT Web (Online)',
      executables: ['codex-web-gpt.cmd', 'bun.exe', 'bun', 'codex-web-gpt-5.0.8-win-x64.exe', 'codex-web-gpt.exe'],
      paths: [
        r'C:\VisualStudio\VinhCommand\engines\codex_chatgpt_web_engine',
        r'C:\VisualStudio\VinhCommand\codex_chatgpt_web_engine',
        r'$USERPROFILE\.bun\bin',
        r'$USERPROFILE\Downloads\codex-chatgpt-web-main\codex-chatgpt-web-main',
        r'$USERPROFILE\AppData\Local\Programs\codex-chatgpt-web',
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
    'gemini-web': AgentDiscoveryConfig(
      name: 'Gemini Web (Online)',
      executables: ['gemini-web.cmd', 'gemini-web.bat', 'gemini-web.exe'],
      paths: [
        r'C:\VisualStudio\VinhCommand\engines\gemini_web_engine',
        r'C:\VisualStudio\VinhCommand\gemini_web_engine',
        r'C:\VisualStudio\VinhCommand\releases\Tools',
        r'$USERPROFILE\AppData\Local\Programs\GeminiWeb',
        r'$APPDATA\npm',
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
    'opencode': AgentDiscoveryConfig(
      name: 'OpenCode AI',
      executables: ['opencode.cmd', 'opencode.exe', 'opencode'],
      paths: [
        r'$APPDATA\npm',
        r'$USERPROFILE\AppData\Roaming\npm',
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
    'dsh': AgentDiscoveryConfig(
      name: 'DeepSeek CLI (dsh)',
      executables: ['dsh.cmd', 'dsh.exe', 'dsh'],
      paths: [
        r'$APPDATA\npm',
        r'$USERPROFILE\AppData\Roaming\npm',
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
  };

  final AgentRepository _repository;
  final AgentAdapterRepository _adapterRepository;
  AgentDiscoveryService(this._repository, this._adapterRepository);

  Future<List<Agent>> discoverAgents() async {
    final agents = <Agent>[];
    for (final entry in _knownAgents.entries) {
      final config = entry.value;
      final override = await _adapterRepository.getAdapterConfig(config.name);
      final executable = override?.executable ?? await _findExecutable(config);
      final existing = await _repository.getAgentByName(config.name);
      final agent = Agent(id: existing?.id ?? AgentId.generate(), name: config.name,
        version: executable == null ? 'Not found' : await _version(executable, config.versionArgs),
        executable: executable ?? '', path: executable ?? '',
        status: executable == null ? AgentStatus.notFound : AgentStatus.available,
        running: false, authenticated: false, capabilities: config.capabilities,
        metadata: const {'authentication': 'Check CLI sign-in before running'},
        discoveredAt: existing?.discoveredAt ?? DateTime.now(), lastCheckedAt: DateTime.now());
      await _repository.saveAgent(agent);
      agents.add(agent);
    }
    return agents;
  }
  Future<String?> _findExecutable(AgentDiscoveryConfig config) async {
    if (config.name == 'Codex') {
      final base = Directory('${Platform.environment['LOCALAPPDATA']}/OpenAI/Codex/bin');
      if (await base.exists()) {
        final folders = await base.list(followLinks: false).where((e) => e is Directory).toList();
        folders.sort((a,b) => b.statSync().modified.compareTo(a.statSync().modified));
        for (final folder in folders) {
          final executable = File('${folder.path}/codex.exe');
          if (await executable.exists()) return executable.path;
        }
      }
    }
    final paths = [...config.paths.map(_expandPath), ...(Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':')];
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      for (final name in config.executables) {
        final file = File('$path/$name');
        if (await file.exists()) return file.path;
      }
    }
    return null;
  }
  String _expandPath(String path) => path
    .replaceAll(r'$ProgramFiles(x86)', Platform.environment['ProgramFiles(x86)'] ?? '')
    .replaceAll(r'$ProgramFiles', Platform.environment['ProgramFiles'] ?? '')
    .replaceAll(r'$LOCALAPPDATA', Platform.environment['LOCALAPPDATA'] ?? '')
    .replaceAll(r'$APPDATA', Platform.environment['APPDATA'] ?? '')
    .replaceAll(r'$USERPROFILE', Platform.environment['USERPROFILE'] ?? '');
  Future<String> _version(String executable, List<String> args) async {
    try {
      final isWindowsCmd = executable.toLowerCase().endsWith('.cmd') || executable.toLowerCase().endsWith('.bat');
      final process = await Process.start(executable, args, runInShell: isWindowsCmd);
      await process.stdin.close();
      final stdout = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
      final stderr = process.stderr.drain<void>();
      final code = await process.exitCode.timeout(const Duration(seconds: 8), onTimeout: () { process.kill(); throw TimeoutException('Version check timed out'); });
      await stderr;
      final text = (await stdout).trim();
      return code == 0 && text.isNotEmpty ? text.split('\n').first.trim() : 'Ready (Pro/CLI)';
    } catch (_) { return 'Ready (Pro/CLI)'; }
  }
  Future<void> refreshAgent(AgentId id) async { await discoverAgents(); }
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


