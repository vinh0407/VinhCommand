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
    required super.code,
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          recoverable: false,
        );
}

class AuthenticationException extends SecurityException {
  const AuthenticationException({
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'AUTH_FAILED',
        );
}

class AuthorizationException extends SecurityException {
  const AuthorizationException({
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'AUTHZ_FAILED',
        );
}

class PathTraversalException extends SecurityException {
  const PathTraversalException({
    required super.message,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'PATH_TRAVERSAL',
        );
}

class AgentException extends VinhCommandException {
  const AgentException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class AgentNotFoundException extends AgentException {
  const AgentNotFoundException({
    required String agentName,
    String? suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'AGENT_NOT_FOUND',
          message: 'Agent "$agentName" not found on system',
          suggestedAction: suggestedAction ??
              'Install the agent or check PATH configuration',
        );
}

class AgentLaunchException extends AgentException {
  const AgentLaunchException({
    required String agentName,
    required String reason,
    String? suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'AGENT_LAUNCH_FAILED',
          message: 'Failed to launch agent "$agentName": $reason',
          suggestedAction: suggestedAction ?? 'Check agent executable and permissions',
        );
}

class AgentAdapterException extends AgentException {
  const AgentAdapterException({
    required String agentName,
    required String operation,
    required String reason,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'AGENT_ADAPTER_ERROR',
          message: 'Agent adapter error for "$agentName" during $operation: $reason',
        );
}

class ProjectException extends VinhCommandException {
  const ProjectException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class ProjectNotFoundException extends ProjectException {
  const ProjectNotFoundException({
    required String projectPath,
    String? suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'PROJECT_NOT_FOUND',
          message: 'Project not found at path: $projectPath',
          suggestedAction: suggestedAction ?? 'Verify the project path exists and is accessible',
        );
}

class TerminalException extends VinhCommandException {
  const TerminalException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class TerminalLaunchException extends TerminalException {
  const TerminalLaunchException({
    required String shell,
    required String reason,
    String? suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  }) : super(
          code: 'TERMINAL_LAUNCH_FAILED',
          message: 'Failed to launch terminal ($shell): $reason',
          suggestedAction: suggestedAction ?? 'Check shell availability and permissions',
        );
}

class FileSystemException extends VinhCommandException {
  const FileSystemException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class FileConflictException extends FileSystemException {
  FileConflictException({
    required String filePath,
    required String externalHash,
    required String currentHash,
    String? suggestedAction,
    Map<String, dynamic>? technicalDetails,
    super.stackTrace,
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
        );
}

class GitException extends VinhCommandException {
  const GitException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class ProcessException extends VinhCommandException {
  const ProcessException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class ServerException extends VinhCommandException {
  const ServerException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class ScreenCaptureException extends VinhCommandException {
  const ScreenCaptureException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class RemoteControlException extends VinhCommandException {
  const RemoteControlException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class DatabaseException extends VinhCommandException {
  const DatabaseException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class NetworkException extends VinhCommandException {
  const NetworkException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}

class ConfigurationException extends VinhCommandException {
  const ConfigurationException({
    required super.code,
    required super.message,
    super.recoverable,
    super.suggestedAction,
    super.technicalDetails,
    super.stackTrace,
  });
}