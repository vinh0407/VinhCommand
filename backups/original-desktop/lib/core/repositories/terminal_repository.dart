import '../entities/terminal.dart';
import '../value_objects/ids.dart';

abstract class TerminalRepository {
  Future<List<Terminal>> getAllTerminals();

  Future<Terminal?> getTerminalById(TerminalId id);

  Future<Terminal> saveTerminal(Terminal terminal);

  Future<void> deleteTerminal(TerminalId id);

  Future<void> addTerminalOutput(TerminalId terminalId, TerminalOutput output);

  Future<List<TerminalOutput>> getTerminalOutput(TerminalId terminalId, {int? limit});

  Future<void> clearTerminalOutput(TerminalId terminalId);

  Future<void> updateTerminalSize(TerminalId terminalId, int rows, int cols);
}

abstract class ShellRepository {
  Future<List<ShellInfo>> getAvailableShells();

  Future<ShellInfo?> getDefaultShell();

  Future<ShellInfo?> getShellByName(String name);
}