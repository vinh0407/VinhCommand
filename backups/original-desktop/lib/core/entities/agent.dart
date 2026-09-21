import 'package:equatable/equatable.dart';
import '../enums/agent_status.dart';
import '../enums/agent_capability.dart';
import '../value_objects/ids.dart';
import '../value_objects/system_info.dart';

class Agent extends Equatable {
  final AgentId id;
  final String name;
  final String version;
  final String executable;
  final String path;
  final AgentStatus status;
  final bool running;
  final bool authenticated;
  final List<AgentCapability> capabilities;
  final Map<String, dynamic> metadata;
  final DateTime discoveredAt;
  final DateTime? lastCheckedAt;
  final String? errorMessage;

  const Agent({
    required this.id,
    required this.name,
    required this.version,
    required this.executable,
    required this.path,
    required this.status,
    required this.running,
    required this.authenticated,
    required this.capabilities,
    required this.metadata,
    required this.discoveredAt,
    this.lastCheckedAt,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        executable,
        path,
        status,
        running,
        authenticated,
        capabilities,
        metadata,
        discoveredAt,
        lastCheckedAt,
        errorMessage,
      ];

  Agent copyWith({
    AgentId? id,
    String? name,
    String? version,
    String? executable,
    String? path,
    AgentStatus? status,
    bool? running,
    bool? authenticated,
    List<AgentCapability>? capabilities,
    Map<String, dynamic>? metadata,
    DateTime? discoveredAt,
    DateTime? lastCheckedAt,
    String? errorMessage,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      executable: executable ?? this.executable,
      path: path ?? this.path,
      status: status ?? this.status,
      running: running ?? this.running,
      authenticated: authenticated ?? this.authenticated,
      capabilities: capabilities ?? this.capabilities,
      metadata: metadata ?? this.metadata,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isAvailable =>
      status == AgentStatus.available || status == AgentStatus.running;

  bool get canLaunch => status != AgentStatus.notFound && status != AgentStatus.failed;

  bool get hasStreaming => capabilities.contains(AgentCapability.streaming);

  bool get hasProjectContext => capabilities.contains(AgentCapability.projectContext);

  bool get hasFileEditing => capabilities.contains(AgentCapability.fileEditing);
}

class AgentAdapterConfig extends Equatable {
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

  @override
  List<Object?> get props => [
        name,
        executable,
        arguments,
        workingDirectory,
        environment,
        inputMethod,
        outputMethod,
        declaredCapabilities,
      ];
}