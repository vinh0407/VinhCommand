import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Stdio protocol from the locally installed Codex app-server schema.
/// Unknown server requests fail closed; only individual decisions are supported.
class CodexSession {
  final Process process;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _done = Completer<Map<String, dynamic>>();
  int _sequence = 0;
  bool _stopped = false;
  Future<void> _events = Future.value();
  Future<void> _decisions = Future.value();
  final _output = StringBuffer();
  final _items = <String, Map<String, dynamic>>{};
  final _files = <String>{};
  final _commands = <Map<String, dynamic>>[];
  String _diff = '';
  String? _sessionId;
  CodexSession(this.process);
  void _send(Map<String, dynamic> message) {
    if (!_stopped) process.stdin.writeln(jsonEncode(message));
  }
  Future<Map<String, dynamic>> _request(String method, Map<String, dynamic> params) {
    final id = ++_sequence;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _send({'id': id, 'method': method, 'params': params});
    return completer.future.timeout(const Duration(seconds: 45)).whenComplete(() => _pending.remove(id));
  }
  Future<Map<String, dynamic>> run({required String cwd, required String prompt,
    required Future<void> Function(Map<String, dynamic>) onEvent,
    required Future<bool> Function(String, Map<String, dynamic>) onApproval}) async {
    void fail(Object error) { if (!_done.isCompleted) _done.completeError(error); }
    // Attach an error listener before startup requests, including early process exit.
    final completion = _done.future;
    unawaited(completion.catchError((Object _) => <String, dynamic>{}));
    process.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((chunk) {
      _events = _events.then((_) => onEvent({'type': 'log', 'text': chunk}));
    }, onError: fail);
    process.stdout.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter()).listen((line) {
      try {
        final message = jsonDecode(line) as Map<String, dynamic>;
        if (message['method'] == null && message['id'] is int) {
          final pending = _pending.remove(message['id']);
          if (pending != null && !pending.isCompleted) {
            if (message['error'] != null) { pending.completeError(StateError('${message['error']}')); }
            else { pending.complete(Map<String, dynamic>.from(message['result'] as Map? ?? {})); }
          }
          return;
        }
        final method = message['method'] as String? ?? '';
        final params = Map<String, dynamic>.from(message['params'] as Map? ?? {});
        if (method == 'item/started' && params['item'] is Map) { final item = Map<String, dynamic>.from(params['item'] as Map); _items[item['id'] as String] = item; }
        if (message.containsKey('id')) {
          if (['item/commandExecution/requestApproval', 'item/fileChange/requestApproval'].contains(method)) {
            _decisions = _decisions.then((_) async {
              if (_stopped) return;
              try {
                final accepted = await onApproval('${message['id']}', {...params, 'kind': method, if(_items.containsKey(params['itemId'])) 'item': _items[params['itemId']]});
                _send({'id': message['id'], 'result': {'decision': accepted ? 'accept' : 'decline'}});
              } catch (e) { _send({'id': message['id'], 'result': {'decision': 'cancel'}}); fail(e); }
            });
          } else {
            _send({'id': message['id'], 'error': {'code': -32601, 'message': 'Unsupported interaction; no permission granted'}});
            fail(StateError('Agent requested unsupported interaction: $method'));
          }
          return;
        }
        _events = _events.then((_) async {
          if (method == 'item/completed') {
            final item = Map<String, dynamic>.from(params['item'] as Map? ?? {});
            if (item['type'] == 'agentMessage') {
              final text = '${item['text'] ?? ''}';
              if (_output.length < 200000) _output.writeln(text.substring(0, text.length.clamp(0, 200000 - _output.length)));
              await onEvent({'type': 'log', 'text': text});
            }
            if (item['type'] == 'commandExecution') {
              final command = {'command': item['command'], 'exitCode': item['exitCode'], 'status': item['status']};
              _commands.add(command);
              await onEvent({'type': 'command', ...command, 'text': '${item['command']}\n${item['aggregatedOutput'] ?? ''}'});
            }
            if (item['type'] == 'fileChange' && item['status'] == 'completed') {
              for (final change in item['changes'] as List? ?? []) { if (change['path'] is String) _files.add(change['path']); }
            }
          }
          if (method == 'turn/diff/updated') _diff = '${params['diff'] ?? ''}';
          if (method == 'item/commandExecution/outputDelta') await onEvent({'type': 'log', 'text': '${params['delta'] ?? ''}'});
          if (method == 'turn/completed' && !_done.isCompleted) {
            final turn = Map<String, dynamic>.from(params['turn'] as Map);
            _done.complete({'sessionId': _sessionId, 'status': turn['status'], 'error': turn['error'], 'output': _output.toString(), 'diff': _diff, 'changedFiles': _files.toList(), 'commands': _commands});
          }
        }).catchError(fail);
      } catch(e) { fail(e); }
    }, onError: fail);
    unawaited(process.exitCode.then((code) async {
      await _events;
      if (!_done.isCompleted) fail(StateError('Codex app-server exited ($code)'));
      for (final pending in _pending.values) { if (!pending.isCompleted) pending.completeError(StateError('Agent disconnected')); }
      _pending.clear();
    }));
    try {
      await _request('initialize', {'clientInfo': {'name': 'vinhcommand', 'version': '1.0.0'}, 'capabilities': {'experimentalApi': false}});
      _send({'method': 'initialized'});
      final thread = await _request('thread/start', {'cwd': cwd, 'sandbox': 'workspace-write', 'approvalPolicy': 'untrusted', 'approvalsReviewer': 'user', 'ephemeral': true});
      _sessionId = (thread['thread'] as Map)['id'] as String;
      await onEvent({'type': 'session', 'sessionId': _sessionId});
      await _request('turn/start', {'threadId': _sessionId, 'input': [{'type': 'text', 'text': prompt, 'text_elements': <dynamic>[]} ], 'approvalPolicy': 'untrusted', 'approvalsReviewer': 'user', 'sandboxPolicy': {'type': 'workspaceWrite', 'writableRoots': [cwd], 'networkAccess': false, 'excludeTmpdirEnvVar': true, 'excludeSlashTmp': true}});
      return await completion.timeout(const Duration(minutes: 30));
    } finally { stop(); }
  }
  void stop() { if (_stopped) return; _stopped = true; process.kill(); }
}



