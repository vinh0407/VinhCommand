import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';


class AgentManager {
  final AgentRepository _repository;
  final AgentAdapterRepository _adapterRepository;
  final AgentDiscoveryService _discoveryService;
  final Map<AgentId, AgentAdapter> _activeAdapters = {};
  final Map<AgentId, StreamSubscription> _outputSubscriptions = {};

  AgentManager(this._repository, this._adapterRepository)
      : _discoveryService = AgentDiscoveryService(_repository, _adapterRepository);

  Future<List<Agent>> discoverAgents() async {
    return await _discoveryService.discoverAgents();
  }

  Future<void> refreshAgent(AgentId id) async {
    await _discoveryService.refreshAgent(id);
  }

  Future<Agent?> getAgent(AgentId id) async {
    return await _repository.getAgentById(id);
  }

  Future<List<Agent>> getAllAgents() async {
    return await _repository.getAllAgents();
  }

  Future<List<Agent>> getAvailableAgents() async {
    return await _repository.getAvailableAgents();
  }

  Future<AgentAdapter?> createAdapter(String agentName) async {
    return AgentAdapterFactory.createAdapter(agentName);
  }

  Future<bool> launchAgent(AgentId agentId, {
    required String workingDirectory,
    required Map<String, String> environment,
    List<String>? arguments,
  }) async {
    final agent = await _repository.getAgentById(agentId);
    if (agent == null) return false;

    final adapter = AgentAdapterFactory.createAdapter(agent.name.toLowerCase());
    if (adapter == null) return false;

    try {
      await adapter.initialize();
      await adapter.launch(
        workingDirectory: workingDirectory,
        environment: environment,
        arguments: arguments,
      );
      
      _activeAdapters[agentId] = adapter;
      await _repository.updateAgentStatus(agentId, AgentStatus.running);
      
      return true;
    } catch (e) {
      await _repository.updateAgentStatus(agentId, AgentStatus.failed);
      return false;
    }
  }

  Future<void> stopAgent(AgentId agentId) async {
    final adapter = _activeAdapters.remove(agentId);
    if (adapter != null) {
      await adapter.stop();
      await adapter.dispose();
    }
    
    final subscription = _outputSubscriptions.remove(agentId);
    await subscription?.cancel();
    
    await _repository.updateAgentStatus(agentId, AgentStatus.available);
  }

  Future<void> sendPrompt(AgentId agentId, String prompt) async {
    final adapter = _activeAdapters[agentId];
    if (adapter != null) {
      await adapter.sendPrompt(prompt);
    }
  }

  Future<Stream<String>?> getAgentOutput(AgentId agentId) async {
    final adapter = _activeAdapters[agentId];
    if (adapter != null) {
      return await adapter.readOutput();
    }
    return null;
  }

  Future<AgentStatus> getAgentStatus(AgentId agentId) async {
    final adapter = _activeAdapters[agentId];
    if (adapter != null) {
      return await adapter.getStatus();
    }
    
    final agent = await _repository.getAgentById(agentId);
    return agent?.status ?? AgentStatus.notFound;
  }

  Future<void> pauseAgent(AgentId agentId) async {
    final adapter = _activeAdapters[agentId];
    if (adapter != null) {
      await adapter.pause();
    }
  }

  Future<void> resumeAgent(AgentId agentId) async {
    final adapter = _activeAdapters[agentId];
    if (adapter != null) {
      await adapter.resume();
    }
  }

  void dispose() {
    for (final adapter in _activeAdapters.values) {
      adapter.dispose();
    }
    _activeAdapters.clear();
    
    for (final subscription in _outputSubscriptions.values) {
      subscription.cancel();
    }
    _outputSubscriptions.clear();
  }
}

final agentManagerProvider = Provider<AgentManager>((ref) {
  // This would be initialized with actual repositories
  throw UnimplementedError('AgentManager requires repository injection');
});
