import 'package:equatable/equatable.dart';

class ProcessInfo extends Equatable {
  final int pid;
  final String name;
  final String? executablePath;
  final double cpuPercent;
  final int memoryMb;
  final String status;
  final int? parentPid;
  final String commandLine;
  final String? projectName;
  final DateTime? startTime;
  final String? username;

  const ProcessInfo({
    required this.pid,
    required this.name,
    this.executablePath,
    required this.cpuPercent,
    required this.memoryMb,
    required this.status,
    this.parentPid,
    required this.commandLine,
    this.projectName,
    this.startTime,
    this.username,
  });

  @override
  List<Object?> get props => [
        pid,
        name,
        executablePath,
        cpuPercent,
        memoryMb,
        status,
        parentPid,
        commandLine,
        projectName,
        startTime,
        username,
      ];

  bool get isDevelopmentProcess {
    final devProcessNames = [
      'node.exe',
      'flutter.exe',
      'dart.exe',
      'python.exe',
      'python3.exe',
      'codex.exe',
      'claude.exe',
      'gemini.exe',
      'npm.cmd',
      'yarn.cmd',
      'pnpm.cmd',
      'bun.exe',
      'dotnet.exe',
      'java.exe',
      'gradle.exe',
      'mvn.exe',
      'go.exe',
      'cargo.exe',
      'webpack.exe',
      'vite.exe',
      'next-server.exe',
    ];
    return devProcessNames.any((n) => name.toLowerCase() == n.toLowerCase());
  }

  String get formattedMemory => memoryMb >= 1024
      ? '${(memoryMb / 1024).toStringAsFixed(1)} GB'
      : '$memoryMb MB';
}

class DevelopmentServer extends Equatable {
  final int port;
  final int pid;
  final String protocol;
  final String url;
  final String? projectName;
  final String? framework;
  final ServerStatus status;
  final DateTime discoveredAt;
  final DateTime? lastCheckedAt;
  final Map<String, dynamic> metadata;

  const DevelopmentServer({
    required this.port,
    required this.pid,
    required this.protocol,
    required this.url,
    this.projectName,
    this.framework,
    required this.status,
    required this.discoveredAt,
    this.lastCheckedAt,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        port,
        pid,
        protocol,
        url,
        projectName,
        framework,
        status,
        discoveredAt,
        lastCheckedAt,
        metadata,
      ];

  bool get isHealthy => status == ServerStatus.running;

  String get displayUrl => url;
}

enum ServerStatus {
  running,
  starting,
  stopped,
  error,
  unknown,
}

class ScreenCapture extends Equatable {
  final String id;
  final ScreenSource source;
  final int width;
  final int height;
  final int fps;
  final int bitrate;
  final String? windowTitle;
  final DateTime capturedAt;
  final List<int> data;

  const ScreenCapture({
    required this.id,
    required this.source,
    required this.width,
    required this.height,
    required this.fps,
    required this.bitrate,
    this.windowTitle,
    required this.capturedAt,
    required this.data,
  });

  @override
  List<Object?> get props => [
        id,
        source,
        width,
        height,
        fps,
        bitrate,
        windowTitle,
        capturedAt,
        data,
      ];
}

enum ScreenSource {
  desktop,
  application,
  window,
  region,
}

class ScreenConfig extends Equatable {
  final ScreenSource source;
  final int targetFps;
  final int targetBitrate;
  final int quality;
  final bool adaptive;
  final String? windowTitle;
  final Rect? region;

  const ScreenConfig({
    required this.source,
    this.targetFps = 30,
    this.targetBitrate = 5000,
    this.quality = 80,
    this.adaptive = true,
    this.windowTitle,
    this.region,
  });

  @override
  List<Object?> get props => [
        source,
        targetFps,
        targetBitrate,
        quality,
        adaptive,
        windowTitle,
        region,
      ];
}

class Rect extends Equatable {
  final int x;
  final int y;
  final int width;
  final int height;

  const Rect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  List<Object?> get props => [x, y, width, height];
}

class Notification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool read;
  final Map<String, dynamic>? actionData;
  final String? relatedEntityId;
  final String? relatedEntityType;

  const Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    required this.createdAt,
    this.read = false,
    this.actionData,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        priority,
        createdAt,
        read,
        actionData,
        relatedEntityId,
        relatedEntityType,
      ];
}

enum NotificationType {
  agentStarted,
  agentCompleted,
  agentFailed,
  buildFailed,
  testsFailed,
  approvalRequired,
  processCrashed,
  serverStopped,
  securityWarning,
  remoteAccessEnabled,
  taskCompleted,
  taskFailed,
  pipelineStageCompleted,
  pipelineFailed,
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}