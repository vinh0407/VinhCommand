import 'package:equatable/equatable.dart';
import '../value_objects/ids.dart';

class Terminal extends Equatable {
  final TerminalId id;
  final String shell;
  final int? pid;
  final String cwd;
  final TerminalStatus status;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final int rows;
  final int cols;
  final List<TerminalOutput> outputHistory;
  final int maxHistorySize;

  const Terminal({
    required this.id,
    required this.shell,
    this.pid,
    required this.cwd,
    required this.status,
    required this.createdAt,
    this.lastActivityAt,
    this.rows = 24,
    this.cols = 80,
    required this.outputHistory,
    this.maxHistorySize = 10000,
  });

  @override
  List<Object?> get props => [
        id,
        shell,
        pid,
        cwd,
        status,
        createdAt,
        lastActivityAt,
        rows,
        cols,
        outputHistory,
        maxHistorySize,
      ];

  Terminal copyWith({
    TerminalId? id,
    String? shell,
    int? pid,
    String? cwd,
    TerminalStatus? status,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    int? rows,
    int? cols,
    List<TerminalOutput>? outputHistory,
    int? maxHistorySize,
  }) {
    return Terminal(
      id: id ?? this.id,
      shell: shell ?? this.shell,
      pid: pid ?? this.pid,
      cwd: cwd ?? this.cwd,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      outputHistory: outputHistory ?? this.outputHistory,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
    );
  }

  bool get isActive => status == TerminalStatus.running;

  bool get canAcceptInput => isActive && pid != null;
}

enum TerminalStatus {
  starting,
  running,
  exited,
  error,
}

class TerminalOutput extends Equatable {
  final String id;
  final TerminalId terminalId;
  final String data;
  final OutputType type;
  final DateTime timestamp;

  const TerminalOutput({
    required this.id,
    required this.terminalId,
    required this.data,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, terminalId, data, type, timestamp];
}

enum OutputType {
  stdout,
  stderr,
  system,
  exit,
}

class ShellInfo extends Equatable {
  final String name;
  final String executable;
  final List<String> arguments;
  final bool available;
  final String? version;

  const ShellInfo({
    required this.name,
    required this.executable,
    required this.arguments,
    required this.available,
    this.version,
  });

  @override
  List<Object?> get props => [name, executable, arguments, available, version];
}