class VinhCommandException implements Exception {
  final String code;
  final String message;
  final bool recoverable;
  final String? suggestedAction;
  final Map<String, dynamic>? technicalDetails;
  final StackTrace? stackTrace;

  const VinhCommandException({
    required this.code,
    required this.message,
    this.recoverable = true,
    this.suggestedAction,
    this.technicalDetails,
    this.stackTrace,
  });

  @override
  String toString() => 'VinhCommandException[$code]: $message';
}

class SecurityException extends VinhCommandException {
  const SecurityException({
    required String code,
    required String message,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: false,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AuthenticationException extends SecurityException {
  const AuthenticationException({
    required String message,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'AUTH_FAILED',
          message: message,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AuthorizationException extends SecurityException {
  const AuthorizationException({
    required String message,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'AUTHZ_FAILED',
          message: message,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class PathTraversalException extends SecurityException {
  const PathTraversalException({
    required String message,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'PATH_TRAVERSAL',
          message: message,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AgentException extends VinhCommandException {
  const AgentException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AgentNotFoundException extends AgentException {
  const AgentNotFoundException({
    required String agentName,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'AGENT_NOT_FOUND',
          message: 'Agent "$agentName" not found on system',
          suggestedAction: suggestedAction ??
              'Install the agent or check PATH configuration',
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AgentLaunchException extends AgentException {
  const AgentLaunchException({
    required String agentName,
    required String reason,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'AGENT_LAUNCH_FAILED',
          message: 'Failed to launch agent "$agentName": $reason',
          suggestedAction: suggestedAction ?? 'Check agent executable and permissions',
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class AgentAdapterException extends AgentException {
  const AgentAdapterException({
    required String agentName,
    required String operation,
    required String reason,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'AGENT_ADAPTER_ERROR',
          message: 'Agent adapter error for "$agentName" during $operation: $reason',
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ProjectException extends VinhCommandException {
  const ProjectException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ProjectNotFoundException extends ProjectException {
  const ProjectNotFoundException({
    required String projectPath,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'PROJECT_NOT_FOUND',
          message: 'Project not found at path: $projectPath',
          suggestedAction: suggestedAction ?? 'Verify the project path exists and is accessible',
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class TerminalException extends VinhCommandException {
  const TerminalException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class TerminalLaunchException extends TerminalException {
  const TerminalLaunchException({
    required String shell,
    required String reason,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'TERMINAL_LAUNCH_FAILED',
          message: 'Failed to launch terminal ($shell): $reason',
          suggestedAction: suggestedAction ?? 'Check shell availability and permissions',
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class FileSystemException extends VinhCommandException {
  const FileSystemException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class FileConflictException extends FileSystemException {
  FileConflictException({
    required String filePath,
    required String externalHash,
    required String currentHash,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: 'FILE_CONFLICT',
          message: 'File "$filePath" has been modified externally',
          suggestedAction: suggestedAction ?? 'Choose to reload, compare, or merge changes',
          technicalDetails: {
            'filePath': filePath,
            'externalHash': externalHash,
            'currentHash': currentHash,
            ...?technicalDetails,
          },
          stackTrace: stackTrace,
        );
}

class GitException extends VinhCommandException {
  const GitException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ProcessException extends VinhCommandException {
  const ProcessException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ServerException extends VinhCommandException {
  const ServerException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ScreenCaptureException extends VinhCommandException {
  const ScreenCaptureException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class RemoteControlException extends VinhCommandException {
  const RemoteControlException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class DatabaseException extends VinhCommandException {
  const DatabaseException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class NetworkException extends VinhCommandException {
  const NetworkException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}

class ConfigurationException extends VinhCommandException {
  const ConfigurationException({
    required String code,
    required String message,
    bool recoverable = true,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    StackTrace? stackTrace,
  }) : super(
          code: code,
          message: message,
          recoverable: recoverable,
          suggestedAction: suggestedAction,
          technicalDetails: technicalDetails,
          stackTrace: stackTrace,
        );
}