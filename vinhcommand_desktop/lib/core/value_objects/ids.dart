import 'package:equatable/equatable.dart';
import 'dart:math';

class AgentId extends Equatable {
  final String value;

  const AgentId(this.value);

  factory AgentId.generate() => AgentId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class ProjectId extends Equatable {
  final String value;

  const ProjectId(this.value);

  factory ProjectId.generate() => ProjectId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class TaskId extends Equatable {
  final String value;

  const TaskId(this.value);

  factory TaskId.generate() => TaskId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class TerminalId extends Equatable {
  final String value;

  const TerminalId(this.value);

  factory TerminalId.generate() => TerminalId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class SessionId extends Equatable {
  final String value;

  const SessionId(this.value);

  factory SessionId.generate() => SessionId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class DeviceId extends Equatable {
  final String value;

  const DeviceId(this.value);

  factory DeviceId.generate() => DeviceId(_generateId());

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

class WorkspacePath extends Equatable {
  final String value;

  const WorkspacePath(this.value);

  factory WorkspacePath.fromString(String path) {
    final normalized = path.replaceAll('\\\\', '/').replaceAll('\\', '/');
    return WorkspacePath(normalized);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}

String _generateId() {
  final random = Random.secure();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${timestamp}_${random.nextInt(1000000)}';
}