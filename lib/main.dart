import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';

void main() {
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
