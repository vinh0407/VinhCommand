import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/database/database_service.dart';
import 'app_providers.dart';

class Preferences {
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  const Preferences({this.textScale = 1, this.highContrast = false, this.reduceMotion = false});
}
class PreferencesController extends StateNotifier<Preferences> {
  final DatabaseService db;
  PreferencesController(this.db) : super(const Preferences()) {
    final row = db.rows('preferences').firstOrNull;
    if (row != null) state = Preferences(textScale: (row['textScale'] as num).toDouble().clamp(1, 2), highContrast: row['highContrast'] == true, reduceMotion: row['reduceMotion'] == true);
  }
  Future<void> update({double? textScale, bool? highContrast, bool? reduceMotion}) async {
    final next = Preferences(textScale: (textScale ?? state.textScale).clamp(1, 2), highContrast: highContrast ?? state.highContrast, reduceMotion: reduceMotion ?? state.reduceMotion);
    await db.put('preferences', 'ui', {'id': 'ui', 'textScale': next.textScale, 'highContrast': next.highContrast, 'reduceMotion': next.reduceMotion});
    state = next;
  }
}
final preferencesProvider = StateNotifierProvider<PreferencesController, Preferences>((ref) => PreferencesController(ref.read(databaseProvider)));
