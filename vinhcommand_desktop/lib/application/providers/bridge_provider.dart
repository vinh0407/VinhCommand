import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/network/desktop_bridge.dart';
import 'app_providers.dart';

final bridgeProvider = Provider<DesktopBridge>((ref) {
  final db = ref.read(databaseProvider);
  final identity = db.rows('identity').firstOrNull;
  final bridge = DesktopBridge(
    db,
    desktopId: identity?['desktopId'] as String? ?? (100000000 + Random.secure().nextInt(900000000)).toString(),
    taskManager: ref.read(taskManagerProvider),
    discoveryService: ref.read(projectDiscoveryServiceProvider),
    agentDiscoveryService: ref.read(agentDiscoveryServiceProvider),
  );
  bridge.start();
  ref.onDispose(bridge.stop);
  return bridge;
});
