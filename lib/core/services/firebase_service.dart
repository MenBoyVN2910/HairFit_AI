// ============================================================================
// File: lib/core/services/firebase_service.dart
// Mục đích: Cung cấp dịch vụ hạ tầng (firebase).
// Kết cấu:
//  - Lớp Service xử lý giao tiếp với các hệ thống bên ngoài hoặc phần cứng (Firebase, Location, API).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Dịch vụ khởi tạo và quản lý kết nối Firebase (Auth, Firestore)
class FirebaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Khởi tạo Firebase App an toàn
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (optionsError) {
          debugPrint(
            'Thử khởi tạo Firebase mặc định không có options: $optionsError',
          );
          await Firebase.initializeApp();
        }
      }
      _isInitialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Lỗi khởi tạo Firebase: $e');
      debugPrint(
        '👉 Vui lòng cấu hình file google-services.json hoặc chạy: flutterfire configure',
      );
    }
  }

  /// Instance của Firebase Auth
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Instance của Cloud Firestore
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
