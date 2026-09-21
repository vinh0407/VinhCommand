import 'dart:math';

String generateId() {
  final random = Random.secure();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${timestamp}_${random.nextInt(1000000)}';
}