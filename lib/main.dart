// ============================================================================
// File: lib/main.dart
// Mục đích: Điểm khởi chạy (Entrypoint) chính của ứng dụng HairFit AI.
// Kết cấu:
//  - Khởi tạo môi trường (Firebase, .env), cấu hình ProviderScope và khởi chạy MaterialApp.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/firebase_service.dart';
import 'core/services/tile_server_config.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Tải các biến môi trường từ file .env (nếu có)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Loaded .env file successfully');
  } catch (e) {
    debugPrint('⚠️ Không thể tải file .env: $e. Sử dụng cấu hình mặc định.');
  }

  // 2. Khởi tạo Firebase SDK (Auth, Firestore)
  await FirebaseService.initialize();

  // 3. Khởi tạo trước kết nối Tile Server trong nền (Task 3.5 fix DNS)
  unawaited(TileServerConfig.probe());

  // 4. Khởi chạy ứng dụng bọc trong ProviderScope của Riverpod (Task 1.14)
  runApp(const ProviderScope(child: HairFitApp()));
}

/// Widget gốc của ứng dụng HairFit AI
class HairFitApp extends ConsumerWidget {
  const HairFitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HairFit AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
