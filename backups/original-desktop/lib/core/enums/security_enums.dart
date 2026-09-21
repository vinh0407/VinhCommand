enum SessionStatus {
  active,
  idle,
  expired,
  revoked,
  disconnected,
}

extension SessionStatusExtension on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.active:
        return 'ACTIVE';
      case SessionStatus.idle:
        return 'IDLE';
      case SessionStatus.expired:
        return 'EXPIRED';
      case SessionStatus.revoked:
        return 'REVOKED';
      case SessionStatus.disconnected:
        return 'DISCONNECTED';
    }
  }

  bool get isValid {
    return this == SessionStatus.active || this == SessionStatus.idle;
  }
}

enum DeviceStatus {
  trusted,
  untrusted,
  revoked,
  disconnected,
}

extension DeviceStatusExtension on DeviceStatus {
  String get label {
    switch (this) {
      case DeviceStatus.trusted:
        return 'TRUSTED';
      case DeviceStatus.untrusted:
        return 'UNTRUSTED';
      case DeviceStatus.revoked:
        return 'REVOKED';
      case DeviceStatus.disconnected:
        return 'DISCONNECTED';
    }
  }

  bool get canConnect {
    return this == DeviceStatus.trusted;
  }
}

enum AccessCodeType {
  sixDigit,
  eightDigit,
  alphanumeric,
  temporary,
  oneTime,
}