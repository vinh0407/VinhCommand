import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import '../../core/entities/agent.dart';
import '../../core/enums/agent_capability.dart';
import '../../core/enums/agent_status.dart';
import '../../core/value_objects/ids.dart';
import '../../core/vinhcommand_core.dart';

abstract class AgentAdapter {
  String get agentName;
  List<AgentCapability> get supportedCapabilities;

  Future<void> initialize();
  Future<void> dispose();

  Future<Agent> detect();
  Future<String> getVersion();
  Future<List<AgentCapability>> getCapabilities();
  
  Future<Process> launch({
    required String workingDirectory,
    required Map<String, String> environment,
    List<String>? arguments,
  });

  Future<void> attach(int pid);
  Future<void> sendPrompt(String prompt);
  Future<void> sendInput(String input);
  Future<Stream<String>> readOutput();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<AgentStatus> getStatus();
}

abstract class BaseAgentAdapter implements AgentAdapter {
  Process? _process;
  StreamController<String>? _outputController;
  bool _disposed = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _process?.kill();
    await _outputController?.close();
    _process = null;
    _outputController = null;
  }

  @override
  Future<Process> launch({
    required String workingDirectory,
    required Map<String, String> environment,
    List<String>? arguments,
  }) async {
    final executable = await _getExecutable();
    final args = _buildLaunchArgs(arguments ?? []);
    
    _process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: true,
    );

    _outputController = StreamController<String>.broadcast();
    
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _outputController?.add(line));
    
    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => _outputController?.add('[ERR] $line'));

    return _process!;
  }

  @override
  Future<void> attach(int pid) async {
    throw UnimplementedError('Attach not supported by default');
  }

  @override
  Future<void> sendPrompt(String prompt) async {
    if (_process == null) throw AgentAdapterException(
      agentName: agentName,
      operation: 'sendPrompt',
      reason: 'Process not started',
    );
    
    _process!.stdin.writeln(prompt);
    await _process!.stdin.flush();
  }

  @override
  Future<void> sendInput(String input) async {
    if (_process == null) throw AgentAdapterException(
      agentName: agentName,
      operation: 'sendInput',
      reason: 'Process not started',
    );
    
    _process!.stdin.write(input);
    await _process!.stdin.flush();
  }

  @override
  Future<Stream<String>> readOutput() async {
    if (_outputController == null) {
      return const Stream.empty();
    }
    return _outputController!.stream;
  }

  @override
  Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode;
      _process = null;
    }
  }

  @override
  Future<void> pause() async {
    if (_process != null) {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'pause', _process!.pid.toString()]);
      }
    }
  }

  @override
  Future<void> resume() async {
    // Resume not typically supported for CLI agents
  }

  @override
  Future<AgentStatus> getStatus() async {
    if (_process == null) return AgentStatus.available;
    try {
      final exitCode = _process!.exitCode;
      return exitCode == null ? AgentStatus.running : AgentStatus.available;
    } catch (_) {
      return AgentStatus.failed;
    }
  }

  @override
  Future<String> getVersion() async {
    try {
      final executable = _getExecutable();
      final process = await Process.run(executable, ['--version']);
      if (process.exitCode == 0) {
        return process.stdout.toString().trim().split('\n').first;
      }
    } catch (_) {}
    return 'Unknown';
  }

  @override
  Future<List<AgentCapability>> getCapabilities() async {
    return supportedCapabilities;
  }

  String _getExecutable() {
    throw UnimplementedError('Subclass must implement _getExecutable');
  }

  List<String> _buildLaunchArgs(List<String> additionalArgs) {
    return additionalArgs;
  }

  @override
  Future<Agent> detect() async {
    return Agent(
      id: AgentId.generate(),
      name: agentName,
      version: await getVersion(),
      executable: _getExecutable(),
      path: _getExecutable(),
      status: AgentStatus.available,
      running: false,
      authenticated: false,
      capabilities: supportedCapabilities,
      metadata: {},
      discoveredAt: DateTime.now(),
    );
  }
}

class CodexAdapter extends BaseAgentAdapter {
  @override
  String get agentName => 'Codex';

  @override
  List<AgentCapability> get supportedCapabilities => [
    AgentCapability.prompt,
    AgentCapability.streaming,
    AgentCapability.input,
    AgentCapability.stop,
    AgentCapability.projectContext,
    AgentCapability.fileEditing,
  ];

  @override
  String _getExecutable() => 'codex';

  @override
  List<String> _buildLaunchArgs(List<String> additionalArgs) {
    return ['exec', ...additionalArgs];
  }
}

class ClaudeAdapter extends BaseAgentAdapter {
  @override
  String get agentName => 'Claude Code';

  @override
  List<AgentCapability> get supportedCapabilities => [
    AgentCapability.prompt,
    AgentCapability.streaming,
    AgentCapability.input,
    AgentCapability.stop,
    AgentCapability.projectContext,
    AgentCapability.fileEditing,
    AgentCapability.terminal,
  ];

  @override
  String _getExecutable() => 'claude';

  @override
  List<String> _buildLaunchArgs(List<String> additionalArgs) {
    return ['--dangerously-skip-permissions', ...additionalArgs];
  }
}

class GeminiAdapter extends BaseAgentAdapter {
  @override
  String get agentName => 'Gemini CLI';

  @override
  List<AgentCapability> get supportedCapabilities => [
    AgentCapability.prompt,
    AgentCapability.streaming,
    AgentCapability.input,
    AgentCapability.stop,
    AgentCapability.projectContext,
  ];

  @override
  String _getExecutable() => 'gemini';

  @override
  List<String> _buildLaunchArgs(List<String> additionalArgs) {
    return additionalArgs;
  }
}

class GenericCLIAdapter extends BaseAgentAdapter {
  final String _name;
  final String _executable;
  final List<String> _defaultArgs;
  final List<AgentCapability> _capabilities;

  GenericCLIAdapter({
    required String name,
    required String executable,
    List<String> defaultArgs = const [],
    List<AgentCapability> capabilities = const [],
  }) : _name = name,
       _executable = executable,
       _defaultArgs = defaultArgs,
       _capabilities = capabilities;

  @override
  String get agentName => _name;

  @override
  List<AgentCapability> get supportedCapabilities => _capabilities;

  @override
  String _getExecutable() => _executable;

  @override
  List<String> _buildLaunchArgs(List<String> additionalArgs) {
    return [..._defaultArgs, ...additionalArgs];
  }
}

class AgentAdapterFactory {
  static final Map<String, AgentAdapter Function()> _adapters = {
    'codex': () => CodexAdapter(),
    'claude': () => ClaudeAdapter(),
    'gemini': () => GeminiAdapter(),
  };

  static final Map<String, AgentAdapterConfig> _customAdapters = {};

  static void registerCustomAdapter(AgentAdapterConfig config) {
    _customAdapters[config.name.toLowerCase()] = config;
  }

  static AgentAdapter? createAdapter(String agentName) {
    final lowerName = agentName.toLowerCase();
    
    if (_adapters.containsKey(lowerName)) {
      return _adapters[lowerName]!();
    }

    if (_customAdapters.containsKey(lowerName)) {
      final config = _customAdapters[lowerName]!;
      return GenericCLIAdapter(
        name: config.name,
        executable: config.executable,
        defaultArgs: config.arguments,
        capabilities: config.declaredCapabilities,
      );
    }

    return null;
  }

  static List<String> getSupportedAgents() {
    return [..._adapters.keys, ..._customAdapters.keys];
  }
}

class AgentAdapterConfig {
  final String name;
  final String executable;
  final List<String> arguments;
  final String? workingDirectory;
  final Map<String, String> environment;
  final String inputMethod;
  final String outputMethod;
  final List<AgentCapability> declaredCapabilities;

  const AgentAdapterConfig({
    required this.name,
    required this.executable,
    required this.arguments,
    this.workingDirectory,
    required this.environment,
    required this.inputMethod,
    required this.outputMethod,
    required this.declaredCapabilities,
  });
}
