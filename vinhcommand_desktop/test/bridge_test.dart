import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vinhcommand_desktop/infrastructure/database/database_service.dart';
import 'package:vinhcommand_desktop/infrastructure/network/desktop_bridge.dart';

void main() {
  test('LAN bridge requires pairing, rejects wrong PIN, and revokes sessions on stop', () async {
    final db = DatabaseService.memory();
    final bridge = DesktopBridge(db, desktopId: '123456789');
    await bridge.start(address: InternetAddress.loopbackIPv4, port: 0);
    addTearDown(bridge.stop);
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    Future<(int, Map<String,dynamic>)> request(String path, {Map<String,dynamic>? body, String? token}) async {
      final r = await client.openUrl(body == null ? 'GET' : 'POST', Uri.parse('http://127.0.0.1:${bridge.port}$path'));
      if(token != null) r.headers.set('Authorization', 'Bearer $token');
      if(body != null) { r.headers.contentType = ContentType.json; r.write(jsonEncode(body)); }
      final response = await r.close();
      return (response.statusCode, jsonDecode(await utf8.decoder.bind(response).join()) as Map<String,dynamic>);
    }
    expect((await request('/api/projects')).$1, 401);
    expect((await request('/api/auth/connect', body: {'desktopId': '123456789', 'accessCode': 'wrong', 'deviceId': 'phone'})).$1, 401);
    final auth = await request('/api/auth/connect', body: {'desktopId': '123456789', 'accessCode': bridge.accessCode, 'deviceId': 'phone'});
    expect(auth.$1, 200);
    final token = auth.$2['data']['sessionToken'] as String;
    expect((await request('/api/projects', token: token)).$2['data']['projects'], isEmpty);
    await bridge.stop();
    await bridge.start(address: InternetAddress.loopbackIPv4, port: 0);
    expect((await request('/api/projects', token: token)).$1, 401);
  });
}
