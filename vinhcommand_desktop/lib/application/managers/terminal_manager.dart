import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/vinhcommand_core.dart';
import '../../infrastructure/vinhcommand_infrastructure.dart';


class TerminalManager {
  final TerminalService _terminalService;

  TerminalManager(TerminalRepository terminalRepository, ShellRepository shellRepository)
      : _terminalService = TerminalService(terminalRepository, shellRepository);

  Future<Terminal> createTerminal({
    String? shell,
    String? workingDirectory,
    int rows = 24,
    int cols = 80,
    Map<String, String>? environment,
  }) async {
    return await _terminalService.createTerminal(
      shell: shell,
      workingDirectory: workingDirectory,
      rows: rows,
      cols: cols,
      environment: environment,
    );
  }

  Future<void> writeInput(TerminalId terminalId, String input) async {
    await _terminalService.writeInput(terminalId, input);
  }

  Future<void> resizeTerminal(TerminalId terminalId, int rows, int cols) async {
    await _terminalService.resizeTerminal(terminalId, rows, cols);
  }

  Future<void> closeTerminal(TerminalId terminalId) async {
    await _terminalService.closeTerminal(terminalId);
  }

  Future<void> restartTerminal(TerminalId terminalId) async {
    await _terminalService.restartTerminal(terminalId);
  }

  Stream<TerminalOutput> getOutputStream(TerminalId terminalId) {
    return _terminalService.getOutputStream(terminalId);
  }

  Future<List<ShellInfo>> getAvailableShells() async {
    return await _terminalService.getAvailableShells();
  }

  void dispose() {
    _terminalService.dispose();
  }
}

final terminalManagerProvider = Provider<TerminalManager>((ref) {
  throw UnimplementedError('TerminalManager requires repository injection');
});
