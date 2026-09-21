import 'package:equatable/equatable.dart';
import '../enums/security_enums.dart';
import '../value_objects/ids.dart';

class Session extends Equatable {
  final SessionId id;
  final DeviceId deviceId;
  final String accessCodeHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? lastActivityAt;
  final List<String> permissions;
  final SessionStatus status;
  final String? userAgent;
  final String? ipAddress;

  const Session({
    required this.id,
    required this.deviceId,
    required this.accessCodeHash,
    required this.createdAt,
    required this.expiresAt,
    this.lastActivityAt,
    required this.permissions,
    required this.status,
    this.userAgent,
    this.ipAddress,
  });

  @override
  List<Object?> get props => [
        id,
        deviceId,
        accessCodeHash,
        createdAt,
        expiresAt,
        lastActivityAt,
        permissions,
        status,
        userAgent,
        ipAddress,
      ];

  bool get isValid => status.isValid && DateTime.now().isBefore(expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  Session copyWith({
    SessionId? id,
    DeviceId? deviceId,
    String? accessCodeHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? lastActivityAt,
    List<String>? permissions,
    SessionStatus? status,
    String? userAgent,
    String? ipAddress,
  }) {
    return Session(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      accessCodeHash: accessCodeHash ?? this.accessCodeHash,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}

class Device extends Equatable {
  final DeviceId id;
  final String name;
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final List<String> permissions;
  final DeviceStatus status;
  final String? publicKey;
  final Map<String, dynamic> metadata;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    required this.permissions,
    required this.status,
    this.publicKey,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        platform,
        model,
        osVersion,
        appVersion,
        createdAt,
        lastSeenAt,
        permissions,
        status,
        publicKey,
        metadata,
      ];

  bool get canConnect => status.canConnect;

  Device copyWith({
    DeviceId? id,
    String? name,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    List<String>? permissions,
    DeviceStatus? status,
    String? publicKey,
    Map<String, dynamic>? metadata,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      model: model ?? this.model,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      publicKey: publicKey ?? this.publicKey,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AccessCode extends Equatable {
  final String id;
  final String codeHash;
  final AccessCodeType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxUses;
  final int usedCount;
  final bool revoked;
  final List<String> permissions;
  final String? description;

  const AccessCode({
    required this.id,
    required this.codeHash,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    this.usedCount = 0,
    this.revoked = false,
    required this.permissions,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        codeHash,
        type,
        createdAt,
        expiresAt,
        maxUses,
        usedCount,
        revoked,
        permissions,
        description,
      ];

  bool get isValid =>
      !revoked &&
      DateTime.now().isBefore(expiresAt) &&
      usedCount < maxUses;

  bool get isOneTime => type == AccessCodeType.oneTime;

  AccessCode copyWith({
    String? id,
    String? codeHash,
    AccessCodeType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    bool? revoked,
    List<String>? permissions,
    String? description,
  }) {
    return AccessCode(
      id: id ?? this.id,
      codeHash: codeHash ?? this.codeHash,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      revoked: revoked ?? this.revoked,
      permissions: permissions ?? this.permissions,
      description: description ?? this.description,
    );
  }
}

class WorkspacePermission extends Equatable {
  final String id;
  final String path;
  final String name;
  final bool enabled;
  final List<String> allowedOperations;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkspacePermission({
    required this.id,
    required this.path,
    required this.name,
    required this.enabled,
    required this.allowedOperations,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        path,
        name,
        enabled,
        allowedOperations,
        createdAt,
        updatedAt,
      ];
}

class AuditEvent extends Equatable {
  final String id;
  final String eventType;
  final String? sessionId;
  final String? deviceId;
  final String? userId;
  final String action;
  final String resource;
  final String? resourceId;
  final Map<String, dynamic> details;
  final String ipAddress;
  final String userAgent;
  final DateTime timestamp;
  final bool success;
  final String? errorMessage;

  const AuditEvent({
    required this.id,
    required this.eventType,
    this.sessionId,
    this.deviceId,
    this.userId,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.details,
    required this.ipAddress,
    required this.userAgent,
    required this.timestamp,
    required this.success,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        eventType,
        sessionId,
        deviceId,
        userId,
        action,
        resource,
        resourceId,
        details,
        ipAddress,
        userAgent,
        timestamp,
        success,
        errorMessage,
      ];
}

enum AuditEventType {
  authentication,
  failedLogin,
  deviceTrust,
  deviceRevocation,
  agentLaunch,
  agentStop,
  commandExecution,
  dangerousCommandApproval,
  fileModification,
  gitOperation,
  processControl,
  remoteControl,
  permissionChanges,
  securityChanges,
  sessionTheft,
}