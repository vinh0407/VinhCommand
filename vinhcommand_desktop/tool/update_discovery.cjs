const fs=require('fs');
const file='lib/infrastructure/agent_discovery/agent_discovery_service.dart';
let text=fs.readFileSync(file,'utf8');
const start=text.indexOf('  final AgentRepository _repository;');
const end=text.indexOf('class AgentDiscoveryConfig');
const methods=`  final AgentRepository _repository;
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
      final base = Directory('\${Platform.environment['LOCALAPPDATA']}/OpenAI/Codex/bin');
      if (await base.exists()) {
        final folders = await base.list(followLinks: false).where((e) => e is Directory).toList();
        folders.sort((a,b) => b.statSync().modified.compareTo(a.statSync().modified));
        for (final folder in folders) {
          final executable = File('\${folder.path}/codex.exe');
          if (await executable.exists()) return executable.path;
        }
      }
    }
    final paths = [...config.paths.map(_expandPath), ...(Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':')];
    for (final path in paths) {
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
    .replaceAll(r'$USERPROFILE', Platform.environment['USERPROFILE'] ?? '');
  Future<String> _version(String executable, List<String> args) async {
    try {
      final process = await Process.start(executable, args, runInShell: executable.toLowerCase().endsWith('.cmd'));
      await process.stdin.close();
      final stdout = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
      final stderr = process.stderr.drain<void>();
      final code = await process.exitCode.timeout(const Duration(seconds: 8), onTimeout: () { process.kill(); throw TimeoutException('Version check timed out'); });
      await stderr;
      final text = (await stdout).trim();
      return code == 0 && text.isNotEmpty ? text.split('\\n').first : 'Unknown';
    } catch (_) { return 'Unknown'; }
  }
  Future<void> refreshAgent(AgentId id) async { await discoverAgents(); }
}

`;
text="import 'dart:async';\nimport 'dart:convert';\n"+text.slice(0,start)+methods+text.slice(end);
fs.writeFileSync(file,text);

