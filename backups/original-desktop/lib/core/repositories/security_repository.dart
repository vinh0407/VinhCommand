import '../entities/security.dart';
import '../value_objects/ids.dart';
import '../enums/security_enums.dart';

abstract class SessionRepository {
  Future<Session?> getSessionById(SessionId id);

  Future<Session?> getSessionByAccessCodeHash(String hash);

  Future<Session> createSession(Session session);

  Future<void> updateSession(Session session);

  Future<void> deleteSession(SessionId id);

  Future<void> revokeSession(SessionId id);

  Future<List<Session>> getActiveSessions();

  Future<List<Session>> getSessionsByDevice(DeviceId deviceId);

  Future<void> cleanupExpiredSessions();
}

abstract class DeviceRepository {
  Future<Device?> getDeviceById(DeviceId id);

  Future<Device?> getDeviceByName(String name);

  Future<Device> saveDevice(Device device);

  Future<void> deleteDevice(DeviceId id);

  Future<void> updateDeviceLastSeen(DeviceId id, DateTime lastSeen);

  Future<void> updateDeviceStatus(DeviceId id, DeviceStatus status);

  Future<List<Device>> getTrustedDevices();

  Future<List<Device>> getAllDevices();
}

abstract class AccessCodeRepository {
  Future<AccessCode?> getAccessCodeByHash(String hash);

  Future<AccessCode> createAccessCode(AccessCode accessCode);

  Future<void> updateAccessCode(AccessCode accessCode);

  Future<void> revokeAccessCode(String id);

  Future<List<AccessCode>> getValidAccessCodes();

  Future<void> cleanupExpiredCodes();
}

abstract class WorkspacePermissionRepository {
  Future<WorkspacePermission?> getPermissionByPath(String path);

  Future<WorkspacePermission> savePermission(WorkspacePermission permission);

  Future<void> deletePermission(String id);

  Future<List<WorkspacePermission>> getAllPermissions();

  Future<List<WorkspacePermission>> getEnabledPermissions();
}

abstract class AuditRepository {
  Future<void> logEvent(AuditEvent event);

  Future<List<AuditEvent>> getEvents({
    DateTime? since,
    DateTime? until,
    String? eventType,
    String? sessionId,
    String? deviceId,
    int limit = 100,
  });

  Future<int> getEventCount(String eventType, DateTime since);

  Future<void> cleanupOldEvents(DateTime before);
}