import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as p;
import '../../core/entities/security.dart';
import '../../core/enums/security_enums.dart';
import '../../core/enums/command_risk.dart';
import '../../core/repositories/security_repository.dart';
import '../../core/value_objects/ids.dart';
import '../../core/vinhcommand_core.dart';
import '../../core/utils/generate_id.dart';

class SecurityService {
  final SessionRepository _sessionRepository;
  final DeviceRepository _deviceRepository;
  final AccessCodeRepository _accessCodeRepository;
  final WorkspacePermissionRepository _workspaceRepository;
  final AuditRepository _auditRepository;
  final encrypt.Key _encryptionKey;

  SecurityService(
    this._sessionRepository,
    this._deviceRepository,
    this._accessCodeRepository,
    this._workspaceRepository,
    this._auditRepository,
  ) : _encryptionKey = encrypt.Key.fromUtf8(_generateKey());

  static String _generateKey() {
    // In production, this should be securely stored
    return 'vinhcommand-secret-key-32-chars!!';
  }

  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateAccessCode(AccessCodeType type) {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    switch (type) {
      case AccessCodeType.sixDigit:
        return (100000 + random.nextInt(900000)).toString();
      case AccessCodeType.eightDigit:
        return (10000000 + random.nextInt(90000000)).toString();
      case AccessCodeType.alphanumeric:
        return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
      case AccessCodeType.temporary:
        return (100000 + random.nextInt(900000)).toString();
      case AccessCodeType.oneTime:
        return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
    }
  }

  Future<AccessCode> createAccessCode({
    required AccessCodeType type,
    required Duration expiresIn,
    required int maxUses,
    required List<String> permissions,
    String? description,
  }) async {
    final code = _generateAccessCode(type);
    final codeHash = _hashCode(code);
    final now = DateTime.now();

    final accessCode = AccessCode(
      id: generateId(),
      codeHash: codeHash,
      type: type,
      createdAt: now,
      expiresAt: now.add(expiresIn),
      maxUses: maxUses,
      permissions: permissions,
      description: description,
    );

    await _accessCodeRepository.createAccessCode(accessCode);
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.authentication.toString(),
      action: 'create_access_code',
      resource: 'access_code',
      resourceId: accessCode.id,
      details: {'type': type.toString(), 'expiresIn': expiresIn.inMinutes},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: now,
      success: true,
    ));

    return accessCode;
  }

  Future<Session?> validateAccessCode(String code, String deviceId, String ipAddress, String userAgent) async {
    final codeHash = _hashCode(code);
    AccessCode? accessCode = await _accessCodeRepository.getAccessCodeByHash(codeHash);

    if (accessCode == null || !accessCode.isValid) {
      await _auditRepository.logEvent(AuditEvent(
        id: generateId(),
        eventType: AuditEventType.failedLogin.toString(),
        action: 'validate_access_code',
        resource: 'access_code',
        details: {'reason': 'invalid_or_expired'},
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: 'Invalid or expired access code',
      ));
      return null;
    }

    final device = await _deviceRepository.getDeviceById(DeviceId(deviceId));
    if (device == null || !device.canConnect) {
      await _auditRepository.logEvent(AuditEvent(
        id: generateId(),
        eventType: AuditEventType.failedLogin.toString(),
        action: 'validate_access_code',
        resource: 'device',
        resourceId: deviceId,
        details: {'reason': 'device_not_trusted'},
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: 'Device not trusted',
      ));
      return null;
    }

    accessCode = accessCode.copyWith(usedCount: accessCode.usedCount + 1);
    await _accessCodeRepository.updateAccessCode(accessCode);

    final session = Session(
      id: SessionId.generate(),
      deviceId: DeviceId(deviceId),
      accessCodeHash: codeHash,
      createdAt: DateTime.now(),
      expiresAt: accessCode.expiresAt,
      lastActivityAt: DateTime.now(),
      permissions: accessCode.permissions,
      status: SessionStatus.active,
      userAgent: userAgent,
      ipAddress: ipAddress,
    );

    await _sessionRepository.createSession(session);
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.authentication.toString(),
      action: 'create_session',
      resource: 'session',
      resourceId: session.id.value,
      details: {'deviceId': deviceId, 'accessCodeType': accessCode.type.toString()},
      ipAddress: ipAddress,
      userAgent: userAgent,
      timestamp: DateTime.now(),
      success: true,
    ));

    return session;
  }

  Future<bool> validateSession(SessionId sessionId, String ipAddress, String userAgent) async {
    Session? session = await _sessionRepository.getSessionById(sessionId);
    if (session == null || !session.isValid) {
      return false;
    }

    if (session.ipAddress != ipAddress || session.userAgent != userAgent) {
      await _auditRepository.logEvent(AuditEvent(
        id: generateId(),
        eventType: AuditEventType.sessionTheft.toString(),
        action: 'validate_session',
        resource: 'session',
        resourceId: sessionId.value,
        details: {'expectedIp': session.ipAddress, 'actualIp': ipAddress},
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
        success: false,
        errorMessage: 'Session validation failed - IP/UserAgent mismatch',
      ));
      return false;
    }

    session = session.copyWith(lastActivityAt: DateTime.now());
    await _sessionRepository.updateSession(session!);
    return true;
  }

  Future<void> revokeSession(SessionId sessionId) async {
    await _sessionRepository.revokeSession(sessionId);
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.authentication.toString(),
      action: 'revoke_session',
      resource: 'session',
      resourceId: sessionId.value,
      details: {},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: DateTime.now(),
      success: true,
    ));
  }

  Future<Device> registerDevice({
    required String name,
    required String platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? publicKey,
  }) async {
    final device = Device(
      id: DeviceId.generate(),
      name: name,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      createdAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      permissions: [],
      status: DeviceStatus.untrusted,
      publicKey: publicKey,
      metadata: {},
    );

    await _deviceRepository.saveDevice(device);
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.deviceTrust.toString(),
      action: 'register_device',
      resource: 'device',
      resourceId: device.id.value,
      details: {'name': name, 'platform': platform},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: DateTime.now(),
      success: true,
    ));

    return device;
  }

  Future<void> trustDevice(DeviceId deviceId) async {
    final device = await _deviceRepository.getDeviceById(deviceId);
    if (device != null) {
      final updated = device.copyWith(status: DeviceStatus.trusted);
      await _deviceRepository.updateDeviceStatus(deviceId, DeviceStatus.trusted);
      await _auditRepository.logEvent(AuditEvent(
        id: generateId(),
        eventType: AuditEventType.deviceTrust.toString(),
        action: 'trust_device',
        resource: 'device',
        resourceId: deviceId.value,
        details: {},
        ipAddress: 'local',
        userAgent: 'VinhCommand',
        timestamp: DateTime.now(),
        success: true,
      ));
    }
  }

  Future<void> revokeDevice(DeviceId deviceId) async {
    await _deviceRepository.updateDeviceStatus(deviceId, DeviceStatus.revoked);
    
    final sessions = await _sessionRepository.getSessionsByDevice(deviceId);
    for (final session in sessions) {
      await _sessionRepository.revokeSession(session.id);
    }

    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.deviceRevocation.toString(),
      action: 'revoke_device',
      resource: 'device',
      resourceId: deviceId.value,
      details: {},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: DateTime.now(),
      success: true,
    ));
  }

  Future<void> addWorkspacePermission(WorkspacePermission permission) async {
    await _workspaceRepository.savePermission(permission);
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.permissionChanges.toString(),
      action: 'add_workspace_permission',
      resource: 'workspace',
      resourceId: permission.id,
      details: {'path': permission.path, 'name': permission.name},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: DateTime.now(),
      success: true,
    ));
  }

  Future<bool> isPathAllowed(String path) async {
    final permissions = await _workspaceRepository.getEnabledPermissions();
    
    for (final permission in permissions) {
      if (path.startsWith(permission.path)) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> emergencyLock() async {
    await _sessionRepository.cleanupExpiredSessions();
    // Would also disconnect all WebSocket connections
    await _auditRepository.logEvent(AuditEvent(
      id: generateId(),
      eventType: AuditEventType.securityChanges.toString(),
      action: 'emergency_lock',
      resource: 'security',
      details: {},
      ipAddress: 'local',
      userAgent: 'VinhCommand',
      timestamp: DateTime.now(),
      success: true,
    ));
  }

  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    final iv = encrypt.IV.fromLength(16);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}

class CommandPolicyEngine {
  static const Map<String, CommandRiskLevel> _riskMap = {
    'git status': CommandRiskLevel.safe,
    'git diff': CommandRiskLevel.safe,
    'git log': CommandRiskLevel.safe,
    'npm test': CommandRiskLevel.safe,
    'npm run test': CommandRiskLevel.safe,
    'yarn test': CommandRiskLevel.safe,
    'pnpm test': CommandRiskLevel.safe,
    'flutter test': CommandRiskLevel.safe,
    'pytest': CommandRiskLevel.safe,
    'dotnet test': CommandRiskLevel.safe,
    'go test': CommandRiskLevel.safe,
    'cargo test': CommandRiskLevel.safe,
    'npm install': CommandRiskLevel.warning,
    'npm ci': CommandRiskLevel.warning,
    'yarn install': CommandRiskLevel.warning,
    'pnpm install': CommandRiskLevel.warning,
    'flutter pub get': CommandRiskLevel.warning,
    'pip install': CommandRiskLevel.warning,
    'pipenv install': CommandRiskLevel.warning,
    'poetry install': CommandRiskLevel.warning,
    'docker': CommandRiskLevel.warning,
    'docker-compose': CommandRiskLevel.warning,
    'kubectl': CommandRiskLevel.warning,
    'terraform': CommandRiskLevel.warning,
    'rm -rf': CommandRiskLevel.dangerous,
    'rm -rf /': CommandRiskLevel.blocked,
    'format': CommandRiskLevel.blocked,
    'mkfs': CommandRiskLevel.blocked,
    'dd': CommandRiskLevel.blocked,
    'shutdown': CommandRiskLevel.blocked,
    'reboot': CommandRiskLevel.blocked,
  };

  static CommandRiskLevel classifyCommand(String command) {
    final trimmed = command.trim().toLowerCase();
    
    for (final entry in _riskMap.entries) {
      if (trimmed.startsWith(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    if (trimmed.contains('rm -rf') || trimmed.contains('del /s') || trimmed.contains('rmdir /s')) {
      return CommandRiskLevel.dangerous;
    }

    if (trimmed.contains('sudo') || trimmed.contains('runas') || trimmed.contains('admin')) {
      return CommandRiskLevel.dangerous;
    }

    if (trimmed.startsWith('npm ') || trimmed.startsWith('yarn ') || trimmed.startsWith('pnpm ')) {
      if (trimmed.contains('install') || trimmed.contains('publish') || trimmed.contains('unpublish')) {
        return CommandRiskLevel.warning;
      }
      return CommandRiskLevel.safe;
    }

    if (trimmed.startsWith('git ') && !trimmed.contains('push') && !trimmed.contains('pull') && !trimmed.contains('merge')) {
      return CommandRiskLevel.safe;
    }

    return CommandRiskLevel.warning;
  }

  static bool requiresApproval(CommandRiskLevel risk) {
    return risk.requiresApproval;
  }
}

class PathSecurity {
  static Future<bool> validatePath(String path, List<String> allowedPaths) async {
    try {
      final file = File(path);
      final dir = Directory(path);
      
      String canonical;
      if (await file.exists()) {
        canonical = file.resolveSymbolicLinksSync();
      } else if (await dir.exists()) {
        canonical = dir.resolveSymbolicLinksSync();
      } else {
        canonical = path;
      }

      final normalized = p.normalize(canonical);
      
      if (normalized.contains('..')) {
        return false;
      }

      for (final allowed in allowedPaths) {
        final allowedCanonical = await _getCanonicalPath(allowed);
        if (normalized.startsWith(allowedCanonical)) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _getCanonicalPath(String path) async {
    final file = File(path);
    final dir = Directory(path);
    
    if (await file.exists()) {
      return file.resolveSymbolicLinksSync();
    } else if (await dir.exists()) {
      return dir.resolveSymbolicLinksSync();
    }
    
    return path;
  }

  static bool isPathTraversal(String path) {
    final normalized = p.normalize(path);
    return normalized.contains('..') || normalized.contains('~');
  }

  static bool isSymlinkEscape(String path) {
    // Check if path contains symlinks that escape allowed directory
    return false; // Would need platform-specific implementation
  }
}
