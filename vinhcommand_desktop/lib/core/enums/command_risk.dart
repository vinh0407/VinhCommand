enum CommandRiskLevel {
  safe,
  warning,
  dangerous,
  blocked,
}

extension CommandRiskLevelExtension on CommandRiskLevel {
  String get label {
    switch (this) {
      case CommandRiskLevel.safe:
        return 'SAFE';
      case CommandRiskLevel.warning:
        return 'WARNING';
      case CommandRiskLevel.dangerous:
        return 'DANGEROUS';
      case CommandRiskLevel.blocked:
        return 'BLOCKED';
    }
  }

  bool get requiresApproval {
    return this == CommandRiskLevel.dangerous || this == CommandRiskLevel.blocked;
  }

  bool get isAllowed {
    return this != CommandRiskLevel.blocked;
  }
}

enum CommandApprovalDecision {
  deny,
  allowOnce,
  allowForSession,
}