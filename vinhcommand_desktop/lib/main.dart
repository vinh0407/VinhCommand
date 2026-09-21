import 'core/enums/task_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'infrastructure/database/database_service.dart';
import 'application/providers/preferences_provider.dart';
import 'application/vinhcommand_application.dart';
import 'presentation/vinhcommand_presentation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final directory = await getApplicationSupportDirectory();
  final database = await DatabaseService.open(File('${directory.path}/vinhcommand-state.json'));
  if (database.rows('identity').isEmpty) {
    await database.put('identity', 'desktop', {'id': 'desktop', 'desktopId': (100000000 + Random.secure().nextInt(900000000)).toString()});
  }
  final taskRepository = DatabaseTaskRepository(database);
  for (final task in await taskRepository.getAllTasks()) {
    if (task.isActive) await taskRepository.saveTask(task.copyWith(state: TaskState.failed, completedAt: DateTime.now(), error: 'Desktop restarted; execution was interrupted. Review files before retrying.', metadata: {...task.metadata, 'approval': null}));
  }
  runApp(ProviderScope(overrides: [databaseProvider.overrideWithValue(database)], child: const VinhCommandApp()));
}

class VinhCommandApp extends ConsumerWidget {
  const VinhCommandApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(preferencesProvider);
    
    return MaterialApp.router(
      title: 'VinhCommand',
      debugShowCheckedModeBanner: false,
      theme: preferences.highContrast ? AppTheme.darkTheme.copyWith(scaffoldBackgroundColor: Colors.black, colorScheme: const ColorScheme.dark(primary: Colors.yellow, onSurface: Colors.white, surface: Colors.black)) : AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: preferences.textScale),
            disableAnimations: preferences.reduceMotion || MediaQuery.of(context).disableAnimations,
          ),
          child: child!,
        );
      },
    );
  }
}


