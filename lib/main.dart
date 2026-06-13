import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_storage.dart';
import 'core/storage/local_db.dart';
import 'core/network/dio_client.dart';
import 'core/helpers/device_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initializeDateFormatting('id_ID', null);

  // 1. Storage first — auth depends on it
  await AppStorage.instance.init();

  // 2. Local SQLite database — offline transactions
  await LocalDb.instance.init();

  // 3. Dio HTTP client
  DioClient.instance.init();

  // 4. Device ID (one-time generation)
  await DeviceHelper.getOrCreateDeviceId();

  runApp(
    const ProviderScope(
      child: BobKasirApp(),
    ),
  );
}

class BobKasirApp extends ConsumerWidget {
  const BobKasirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

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
