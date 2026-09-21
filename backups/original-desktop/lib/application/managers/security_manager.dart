import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';


class SecurityManager {
  final SecurityService _securityService;

  SecurityManager(
    SessionRepository sessionRepository,
    DeviceRepository deviceRepository,
    AccessCodeRepository accessCodeRepository,
    WorkspacePermissionRepository workspaceRepository,
    AuditRepository auditRepository,
  ) : _securityService = SecurityService(
    sessionRepository,
    deviceRepository,
    accessCodeRepository,
    workspaceRepository,
    auditRepository,
  );

  Future<AccessCode> createAccessCode({
    required AccessCodeType type,
    required Duration expiresIn,
    required int maxUses,
    required List<String> permissions,
    String? description,
  }) async {
    return await _securityService.createAccessCode(
      type: type,
      expiresIn: expiresIn,
      maxUses: maxUses,
      permissions: permissions,
      description: description,
    );
  }

  Future<Session?> validateAccessCode(String code, String deviceId, String ipAddress, String userAgent) async {
    return await _securityService.validateAccessCode(code, deviceId, ipAddress, userAgent);
  }

  Future<bool> validateSession(SessionId sessionId, String ipAddress, String userAgent) async {
    return await _securityService.validateSession(sessionId, ipAddress, userAgent);
  }

  Future<void> revokeSession(SessionId sessionId) async {
    await _securityService.revokeSession(sessionId);
  }

  Future<Device> registerDevice({
    required String name,
    required String platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? publicKey,
  }) async {
    return await _securityService.registerDevice(
      name: name,
      platform: platform,
      model: model,
      osVersion: osVersion,
      appVersion: appVersion,
      publicKey: publicKey,
    );
  }

  Future<void> trustDevice(DeviceId deviceId) async {
    await _securityService.trustDevice(deviceId);
  }

  Future<void> revokeDevice(DeviceId deviceId) async {
    await _securityService.revokeDevice(deviceId);
  }

  Future<void> addWorkspacePermission(WorkspacePermission permission) async {
    await _securityService.addWorkspacePermission(permission);
  }

  Future<bool> isPathAllowed(String path) async {
    return await _securityService.isPathAllowed(path);
  }

  Future<void> emergencyLock() async {
    await _securityService.emergencyLock();
  }

  String encryptData(String data) {
    return _securityService.encryptData(data);
  }

  String decryptData(String encryptedData) {
    return _securityService.decryptData(encryptedData);
  }

  CommandRiskLevel classifyCommand(String command) {
    return CommandPolicyEngine.classifyCommand(command);
  }

  bool requiresApproval(String command) {
    return CommandPolicyEngine.requiresApproval(classifyCommand(command));
  }
}

final securityManagerProvider = Provider<SecurityManager>((ref) {
  throw UnimplementedError('SecurityManager requires repository injection');
});
