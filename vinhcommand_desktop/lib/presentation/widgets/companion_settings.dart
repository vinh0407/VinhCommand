import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../application/providers/bridge_provider.dart';

class CompanionSettings extends ConsumerStatefulWidget {
  const CompanionSettings({super.key});
  @override ConsumerState<CompanionSettings> createState() => _CompanionSettingsState();
}

class _CompanionSettingsState extends ConsumerState<CompanionSettings> {
  List<String> validAddresses = [];
  String primaryAddress = '';
  String? error;
  bool busy = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _refreshAddresses();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshAddresses();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAddresses() async {
    try {
      final bridge = ref.read(bridgeProvider);
      final port = bridge.port ?? 8444;
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final list = <String>[];

      // Prioritize Wi-Fi and common private LAN IPs first
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        final isVirtual = name.contains('wsl') || name.contains('veth') || name.contains('vmware') || name.contains('virtual') || name.contains('hyper-v');
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.') || ip.startsWith('169.254.')) continue;
          final url = 'http://$ip:$port';
          if (!isVirtual && (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.16.'))) {
            list.insert(0, url);
          } else if (!isVirtual) {
            list.add(url);
          } else {
            list.add('$url (Virtual/WSL)');
          }
        }
      }

      if (mounted) {
        setState(() {
          validAddresses = list;
          primaryAddress = list.isNotEmpty ? list.first.replaceAll(' (Virtual/WSL)', '') : 'http://127.0.0.1:$port';
        });
      }
    } catch (_) {}
  }

  Future<void> toggle(bool enabled) async {
    setState(() { busy = true; error = null; });
    try {
      final bridge = ref.read(bridgeProvider);
      if (enabled) {
        await bridge.start();
        await _refreshAddresses();
      } else {
        await bridge.stop();
      }
    } catch (e) {
      error = '$e';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void showQrDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, size: 24),
            SizedBox(width: 8),
            Text('Mã QR Kết nối Mobile (Android)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mở ứng dụng VinhCommand trên điện thoại và quét mã QR hoặc nhập thông tin bên dưới:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220.0,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(qrData, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void copyText(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label: $text'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bridge = ref.watch(bridgeProvider);
    final qrData = 'vinhcommand://connect?address=${Uri.encodeComponent(primaryAddress)}&id=${bridge.desktopId}&pin=${bridge.accessCode}';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Android Companion (Kết nối Điện thoại)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Kết nối điện thoại Android qua mạng Wi-Fi nội bộ để xem dự án, gửi yêu cầu AI, phê duyệt và giám sát tác vụ từ xa.'),
      const SizedBox(height: 12),
      SwitchListTile(
        title: const Text('Bật máy chủ kết nối nội bộ (LAN Connection)'),
        subtitle: Text(bridge.running ? 'Đang chạy trên cổng ${bridge.port ?? 8444} (Sẵn sàng kết nối)' : 'Đã tắt'),
        value: bridge.running,
        onChanged: busy ? null : toggle,
      ),
      if (error != null) Semantics(liveRegion: true, child: Text('Lỗi kết nối: $error', style: const TextStyle(color: Colors.red))),
      if (bridge.running) ...[
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 120.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Địa chỉ máy chủ (Server URL):', style: Theme.of(context).textTheme.titleSmall),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'Sao chép URL',
                                onPressed: () => copyText(primaryAddress, 'Server URL'),
                              ),
                            ],
                          ),
                          SelectableText(primaryAddress, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 15)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Desktop ID:', style: Theme.of(context).textTheme.titleSmall),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'Sao chép Desktop ID',
                                onPressed: () => copyText(bridge.desktopId, 'Desktop ID'),
                              ),
                            ],
                          ),
                          SelectableText(bridge.desktopId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Mã PIN kết nối (Pairing PIN):', style: Theme.of(context).textTheme.titleSmall),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                tooltip: 'Sao chép PIN',
                                onPressed: () => copyText(bridge.accessCode, 'Mã PIN'),
                              ),
                            ],
                          ),
                          SelectableText(bridge.accessCode, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 18)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => showQrDialog(qrData),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Phóng to Mã QR'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(bridge.rotateCode),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Tạo mã PIN mới'),
                    ),
                  ],
                ),
                if (validAddresses.length > 1) ...[
                  const SizedBox(height: 12),
                  const Text('Các địa chỉ IP mạng khả dụng trên máy tính:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  for (final addr in validAddresses)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          SelectableText(addr, style: const TextStyle(fontSize: 12)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => copyText(addr.split(' ').first, 'IP Address'),
                            child: const Text('Copy', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Cho phép điện thoại gửi lệnh AI và chạy tác vụ từ xa'),
          subtitle: const Text('Các dự án được cấp quyền chỉnh sửa vẫn yêu cầu phê duyệt từng bước hành động.'),
          value: bridge.allowRemoteControl,
          onChanged: (value) => setState(() => bridge.allowRemoteControl = value),
        ),
        for (final device in bridge.devices)
          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.blueAccent),
            title: Text(device['name'] ?? 'Thiết bị di động'),
            subtitle: Text('ID: ${device['id']}'),
            trailing: IconButton(
              tooltip: 'Ngắt kết nối thiết bị này',
              icon: const Icon(Icons.link_off, color: Colors.redAccent),
              onPressed: () => setState(() => bridge.revokeDevice(device['id']!)),
            ),
          ),
      ],
    ]);
  }
}

