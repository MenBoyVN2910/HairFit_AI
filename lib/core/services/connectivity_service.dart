import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Dịch vụ theo dõi trạng thái kết nối mạng của thiết bị
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Kiểm tra xem hiện tại thiết bị có kết nối mạng hay không
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Stream lắng nghe sự thay đổi trạng thái mạng theo thời gian thực
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }
}
