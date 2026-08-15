import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'src/screens/onboarding.dart';
import 'src/screens/shell.dart';
import 'src/state/app_state.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SQLite on desktop uses the FFI implementation.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final state = AppState();
  await state.load();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const AuraStylistApp(),
    ),
  );
}

class AuraStylistApp extends StatelessWidget {
  const AuraStylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Aura Stylist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      home: state.profile.onboarded ? const ShellScreen() : const OnboardingScreen(),
    );
  }
}
