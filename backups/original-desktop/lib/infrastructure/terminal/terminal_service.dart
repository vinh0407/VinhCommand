import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import '../../core/vinhcommand_core.dart';
import '../../core/utils/generate_id.dart';

class TerminalService {
  final TerminalRepository _repository;
  final ShellRepository _shellRepository;
  final Map<TerminalId, Process> _processes = {};
  final Map<TerminalId, StreamController<TerminalOutput>> _outputControllers = {};

  TerminalService(this._repository, this._shellRepository);

  Future<Terminal> createTerminal({
    String? shell,
    String? workingDirectory,
    int rows = 24,
    int cols = 80,
    Map<String, String>? environment,
  }) async {
    final shellInfo = shell != null 
        ? await _shellRepository.getShellByName(shell)
        : await _shellRepository.getDefaultShell();

    if (shellInfo == null || !shellInfo.available) {
      throw TerminalLaunchException(
        shell: shell ?? 'default',
        reason: 'Shell not available',
      );
    }

    final terminalId = TerminalId.generate();
    final cwd = workingDirectory ?? Directory.current.path;

    final terminal = Terminal(
      id: terminalId,
      shell: shellInfo.name,
      pid: null,
      cwd: cwd,
      status: TerminalStatus.starting,
      createdAt: DateTime.now(),
      rows: rows,
      cols: cols,
      outputHistory: [],
    );

    final process = await Process.start(
      shellInfo.executable,
      shellInfo.arguments,
      workingDirectory: cwd,
      environment: environment,
      runInShell: true,
      mode: ProcessStartMode.detached,
    );

    _processes[terminalId] = process;

    final outputController = StreamController<TerminalOutput>.broadcast();
    _outputControllers[terminalId] = outputController;

    final updatedTerminal = terminal.copyWith(
      pid: process.pid,
      status: TerminalStatus.running,
    );

    await _repository.saveTerminal(updatedTerminal);

    _setupOutputStreams(terminalId, process, outputController);

    return updatedTerminal;
  }

  void _setupOutputStreams(TerminalId terminalId, Process process, StreamController<TerminalOutput> controller) {
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final output = TerminalOutput(
            id: generateId(),
            terminalId: terminalId,
            data: line,
            type: OutputType.stdout,
            timestamp: DateTime.now(),
          );
          controller.add(output);
          _repository.addTerminalOutput(terminalId, output);
        });

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final output = TerminalOutput(
            id: generateId(),
            terminalId: terminalId,
            data: line,
            type: OutputType.stderr,
            timestamp: DateTime.now(),
          );
          controller.add(output);
          _repository.addTerminalOutput(terminalId, output);
        });

    process.exitCode.then((exitCode) {
      final output = TerminalOutput(
        id: generateId(),
        terminalId: terminalId,
        data: 'Process exited with code $exitCode',
        type: OutputType.exit,
        timestamp: DateTime.now(),
      );
      controller.add(output);
      _repository.addTerminalOutput(terminalId, output);

      final terminal = _repository.getTerminalById(terminalId);
      if (terminal != null) {
        terminal.then((t) => t?.copyWith(status: TerminalStatus.exited));
      }
    });
  }

  Future<void> writeInput(TerminalId terminalId, String input) async {
    final process = _processes[terminalId];
    if (process == null) {
      throw TerminalException(
        code: 'TERMINAL_NOT_FOUND',
        message: 'Terminal not found or not running',
      );
    }

    process.stdin.write(input);
    await process.stdin.flush();
  }

  Future<void> resizeTerminal(TerminalId terminalId, int rows, int cols) async {
    await _repository.updateTerminalSize(terminalId, rows, cols);
    
    if (Platform.isWindows) {
      try {
        await Process.run('mode', ['con: cols=$cols lines=$rows']);
      } catch (_) {}
    }
  }

  Future<void> closeTerminal(TerminalId terminalId) async {
    final process = _processes.remove(terminalId);
    final controller = _outputControllers.remove(terminalId);
    
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode;
    }
    
    await controller?.close();
    await _repository.deleteTerminal(terminalId);
  }

  Future<void> restartTerminal(TerminalId terminalId) async {
    final terminal = await _repository.getTerminalById(terminalId);
    if (terminal == null) return;

    await closeTerminal(terminalId);
    
    await createTerminal(
      shell: terminal.shell,
      workingDirectory: terminal.cwd,
      rows: terminal.rows,
      cols: terminal.cols,
    );
  }

  Stream<TerminalOutput> getOutputStream(TerminalId terminalId) {
    final controller = _outputControllers[terminalId];
    if (controller == null) {
      return const Stream.empty();
    }
    return controller.stream;
  }

  Future<List<ShellInfo>> getAvailableShells() async {
    return _shellRepository.getAvailableShells();
  }

  void dispose() {
    for (final process in _processes.values) {
      process.kill();
    }
    for (final controller in _outputControllers.values) {
      controller.close();
    }
    _processes.clear();
    _outputControllers.clear();
  }
}

class WindowsShellRepository implements ShellRepository {
  @override
  Future<List<ShellInfo>> getAvailableShells() async {
    final shells = <ShellInfo>[];

    final pwsh = await _checkShell('pwsh', ['pwsh.exe', '--version'], ['-NoProfile']);
    if (pwsh != null) shells.add(pwsh);

    final powershell = await _checkShell('powershell', ['powershell.exe', '-Command', '\$PSVersionTable.PSVersion'], ['-NoProfile']);
    if (powershell != null) shells.add(powershell);

    final cmd = await _checkShell('cmd', ['cmd.exe', '/c', 'ver'], ['/c']);
    if (cmd != null) shells.add(cmd);

    final gitBash = await _checkShell('git-bash', ['bash.exe', '--version'], ['-i']);
    if (gitBash != null) shells.add(gitBash);

    final wsl = await _checkShell('wsl', ['wsl.exe', '--version'], []);
    if (wsl != null) shells.add(wsl);

    return shells;
  }

  Future<ShellInfo?> _checkShell(String name, List<String> versionCmd, List<String> defaultArgs) async {
    try {
      final process = await Process.run(versionCmd[0], versionCmd.sublist(1));
      if (process.exitCode == 0) {
        return ShellInfo(
          name: name,
          executable: versionCmd[0],
          arguments: defaultArgs,
          available: true,
          version: process.stdout.toString().trim().split('\n').first,
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<ShellInfo?> getDefaultShell() async {
    final shells = await getAvailableShells();
    if (shells.isEmpty) return null;
    
    return shells.firstWhere(
      (s) => s.name == 'pwsh' || s.name == 'powershell',
      orElse: () => shells.first,
    );
  }

  @override
  Future<ShellInfo?> getShellByName(String name) async {
    final shells = await getAvailableShells();
    return shells.firstWhere((s) => s.name == name, orElse: () => throw TerminalException(
      code: 'SHELL_NOT_FOUND',
      message: 'Shell $name not found',
    ));
  }
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


