enum AgentStatus {
  notFound,
  installed,
  available,
  running,
  authenticated,
  notAuthenticated,
  failed,
  unsupported,
}

extension AgentStatusExtension on AgentStatus {
  String get label {
    switch (this) {
      case AgentStatus.notFound:
        return 'NOT FOUND';
      case AgentStatus.installed:
        return 'INSTALLED';
      case AgentStatus.available:
        return 'AVAILABLE';
      case AgentStatus.running:
        return 'RUNNING';
      case AgentStatus.authenticated:
        return 'AUTHENTICATED';
      case AgentStatus.notAuthenticated:
        return 'NOT AUTHENTICATED';
      case AgentStatus.failed:
        return 'FAILED';
      case AgentStatus.unsupported:
        return 'UNSUPPORTED';
    }
  }

  bool get isPositive {
    return this == AgentStatus.available ||
        this == AgentStatus.running ||
        this == AgentStatus.authenticated;
  }

  bool get isNegative {
    return this == AgentStatus.notFound ||
        this == AgentStatus.failed ||
        this == AgentStatus.unsupported;
  }

  bool get isWarning {
    return this == AgentStatus.notAuthenticated ||
        this == AgentStatus.installed;
  }
}