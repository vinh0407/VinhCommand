import '../entities/agent.dart';
import '../value_objects/ids.dart';
import '../enums/agent_status.dart';
import '../enums/agent_capability.dart';

abstract class AgentRepository {
  Future<List<Agent>> getAllAgents();

  Future<Agent?> getAgentById(AgentId id);

  Future<Agent?> getAgentByName(String name);

  Future<Agent> saveAgent(Agent agent);

  Future<void> deleteAgent(AgentId id);

  Future<void> updateAgentStatus(AgentId id, AgentStatus status);

  Future<void> updateAgentCapabilities(AgentId id, List<AgentCapability> capabilities);

  Future<List<Agent>> getAvailableAgents();

  Future<List<Agent>> getRunningAgents();
}

abstract class AgentAdapterRepository {
  Future<AgentAdapterConfig?> getAdapterConfig(String agentName);

  Future<void> saveAdapterConfig(AgentAdapterConfig config);

  Future<void> deleteAdapterConfig(String agentName);

  Future<List<AgentAdapterConfig>> getAllAdapterConfigs();
}