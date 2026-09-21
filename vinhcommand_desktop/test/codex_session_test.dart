import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/infrastructure/agent_adapter/codex_session.dart';
void main() {
  test('app-server approval is relayed and denial is returned without auto approval', () async {
    final script = await File('${Directory.systemTemp.path}/vc-rpc-${DateTime.now().microsecondsSinceEpoch}.cjs').writeAsString(r'''
const readline=require('readline');
const send=x=>console.log(JSON.stringify(x));
readline.createInterface({input:process.stdin}).on('line', l=>{
 const m=JSON.parse(l);
 if(m.method==='initialize') send({id:m.id,result:{}});
 if(m.method==='thread/start') {
  if(m.params.approvalPolicy!=='untrusted'||m.params.sandbox!=='workspace-write') process.exit(6);
  send({id:m.id,result:{thread:{id:'session-1'}}});
 }
 if(m.method==='turn/start') {
  send({id:m.id,result:{turn:{id:'turn-1'}}});
  send({id:100,method:'item/commandExecution/requestApproval',params:{command:'npm install',reason:'Dependencies',itemId:'c1'}});
 }
 if(m.id===100&&m.result) {
  if(m.result.decision!=='decline') process.exit(8);
  send({method:'item/completed',params:{item:{type:'agentMessage',text:'Denied correctly'}}});
  send({method:'turn/completed',params:{turn:{status:'completed'}}});
 }
});
''');
    addTearDown(script.delete);
    final process = await Process.start('node', [script.path]);
    var asked = false;
    final session = CodexSession(process);
    addTearDown(session.stop);
    final result = await session.run(cwd: Directory.current.path, prompt: 'fixture', onEvent: (event) async {}, onApproval: (id, details) async {
      asked = true; expect(details['command'], 'npm install'); return false;
    });
    expect(asked, isTrue);
    expect(result['sessionId'], 'session-1');
    expect(result['output'], contains('Denied correctly'));
  });
}
