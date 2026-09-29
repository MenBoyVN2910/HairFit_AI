import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Cấu hình mặc định cho Firebase Options
/// Tạo bởi FlutterFire CLI hoặc cấu hình thủ công cho Android
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  /// Cấu hình Firebase cho nền tảng Android (minSdk 26, targetSdk 34)
  /// Cần thay thế các giá trị bên dưới bằng thông tin từ Firebase Console của bạn
  /// hoặc chạy lệnh: flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCOboPC2qhJ3thYS4P2PCIHALjdPV7HuLg',
    appId: '1:982039538312:android:7de345c2c72f275c708d3d',
    messagingSenderId: '982039538312',
    projectId: 'hairfit-ai-a970f',
    storageBucket: 'hairfit-ai-a970f.firebasestorage.app',
  );
}
