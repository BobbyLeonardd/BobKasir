import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/services/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RevenueCatService.init();
  runApp(const ProviderScope(child: BobKasirApp()));
}

class BobKasirApp extends ConsumerWidget {
  const BobKasirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    
    // Initialize SyncService
    ref.watch(syncServiceProvider);

    return MaterialApp.router(
      title: 'BobKasir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
