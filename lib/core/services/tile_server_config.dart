// ============================================================================
// File: lib/core/services/tile_server_config.dart
// Mục đích: Cung cấp dịch vụ hạ tầng (tile_server_config.dart).
// Kết cấu:
//  - Lớp Service xử lý giao tiếp với các hệ thống bên ngoài hoặc phần cứng (Firebase, Location, API).
// ============================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

/// Thông tin cấu hình của một Tile Server
class TileServerInfo {
  final String name;
  final String urlTemplate;
  final String? fallbackUrl;
  final List<String> subdomains;
  final String attribution;
  final int maxZoom;

  const TileServerInfo({
    required this.name,
    required this.urlTemplate,
    this.fallbackUrl,
    this.subdomains = const ['a', 'b', 'c'],
    required this.attribution,
    this.maxZoom = 18,
  });
}

/// Quản lý tập trung cấu hình Tile Server cho OpenStreetMap toàn bộ ứng dụng HairFit AI.
///
/// Giải quyết triệt để:
/// 1. Loại bỏ CartoDB vì CartoDB bắt buộc API Key và in hình chìm 'API KEY REQUIRED'.
/// 2. Sử dụng OpenStreetMap DE (`tile.openstreetmap.de` do FOSSGIS e.V. vận hành) làm nguồn chính:
///    - Dữ liệu OpenStreetMap 100% nguyên bản, đầy đủ tên đường tiếng Việt.
///    - Miễn phí, KHÔNG cần API key, KHÔNG có watermark.
///    - Không bị chặn DNS tại Việt Nam như domain `tile.openstreetmap.org`.
///    - Hỗ trợ 3 subdomain xoay vòng (`a, b, c`) tăng tốc tải bản đồ.
/// 3. Cung cấp Google Maps tile server làm `fallbackUrl` tự động nếu có bất kỳ mảnh nào lỗi.
class TileServerConfig {
  TileServerConfig._();

  /// Package name cho User-Agent header (tuân thủ OpenStreetMap Tile Usage Policy)
  static const String userAgentPackageName = 'com.example.hairfit_ai';

  /// Danh sách các tile server đã kiểm nghiệm thực tế tại Việt Nam (không watermark, dịu mắt, sắc nét)
  static const List<TileServerInfo> servers = [
    // 1. Google Maps Standard (Dịu mắt, đường phố Việt Nam rõ ràng, không rối rác nhãn)
    TileServerInfo(
      name: 'Google Maps (Chuẩn dịu mắt)',
      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&hl=vi&x={x}&y={y}&z={z}',
      fallbackUrl: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
      subdomains: ['0', '1', '2', '3'],
      attribution: '© Google Maps',
      maxZoom: 20,
    ),
    // 2. Google Maps Hybrid (Ảnh vệ tinh có nhãn đường sắc nét)
    TileServerInfo(
      name: 'Google Maps (Vệ tinh)',
      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=y&hl=vi&x={x}&y={y}&z={z}',
      fallbackUrl: 'https://mt{s}.google.com/vt/lyrs=m&hl=vi&x={x}&y={y}&z={z}',
      subdomains: ['0', '1', '2', '3'],
      attribution: '© Google Maps Satellite',
      maxZoom: 20,
    ),
    // 3. OpenStreetMap (DE Mirror - FOSSGIS): Dự phòng OSM
    TileServerInfo(
      name: 'OpenStreetMap',
      urlTemplate: 'https://{s}.tile.openstreetmap.de/{z}/{x}/{y}.png',
      fallbackUrl: 'https://mt1.google.com/vt/lyrs=m&hl=vi&x={x}&y={y}&z={z}',
      subdomains: ['a', 'b', 'c'],
      attribution: '© OpenStreetMap contributors',
      maxZoom: 18,
    ),
  ];

  /// Server hiện tại đang sử dụng (mặc định là Google Maps chuẩn dịu mắt)
  static TileServerInfo _currentServer = servers[0];
  static final ValueNotifier<TileServerInfo> serverNotifier =
      ValueNotifier<TileServerInfo>(servers[0]);
  static bool _isProbing = false;

  /// Thiết lập đổi server / style bản đồ
  static void setServer(TileServerInfo server) {
    _currentServer = server;
    serverNotifier.value = server;
  }

  /// Lấy cấu hình server hiện tại
  static TileServerInfo get currentServer => _currentServer;

  /// URL template chính
  static String get urlTemplate => _currentServer.urlTemplate;

  /// Fallback URL khi tile chính tải thất bại
  static String? get fallbackUrl => _currentServer.fallbackUrl;

  /// Subdomains phân tải
  static List<String> get subdomains => _currentServer.subdomains;

  /// Tạo TileLayer hoàn chỉnh không có watermark, tự động fallback và xử lý lỗi
  static TileLayer buildTileLayer({
    TileServerInfo? server,
    String? customUrlTemplate,
    String? customFallbackUrl,
    List<String>? customSubdomains,
  }) {
    final s = server ?? _currentServer;
    return TileLayer(
      urlTemplate: customUrlTemplate ?? s.urlTemplate,
      fallbackUrl: customFallbackUrl ?? s.fallbackUrl,
      subdomains: customSubdomains ?? s.subdomains,
      userAgentPackageName: userAgentPackageName,
      maxZoom: s.maxZoom.toDouble(),
      tileProvider: NetworkTileProvider(),
      errorTileCallback: (tile, error, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [TileError] Tile z=${tile.coordinates.z} '
            'x=${tile.coordinates.x} y=${tile.coordinates.y} lỗi: $error',
          );
        }
      },
    );
  }

  /// Tự động kiểm tra (probe) kết nối ngầm khi mở app
  static Future<TileServerInfo> probe() async {
    if (_isProbing) return _currentServer;
    _isProbing = true;

    try {
      for (final server in servers) {
        try {
          // Thử tải 1 tile kiểm tra
          final subdomain = server.subdomains.isNotEmpty
              ? server.subdomains.first
              : '';
          final testUrl = server.urlTemplate
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', '15')
              .replaceAll('{x}', '26232')
              .replaceAll('{y}', '14903');

          final response = await http
              .get(
                Uri.parse(testUrl),
                headers: {
                  'User-Agent': 'HairFitAI/1.0 ($userAgentPackageName)',
                },
              )
              .timeout(const Duration(seconds: 4));

          if (response.statusCode == 200 && response.bodyBytes.length > 500) {
            _currentServer = server;
            serverNotifier.value = server;
            debugPrint(
              '🗺️ [TileServerConfig] Đã kết nối thành công tới Tile Server: ${server.name}',
            );
            return server;
          }
        } catch (e) {
          debugPrint(
            '⚠️ [TileServerConfig] Không kết nối được tới ${server.name}: $e',
          );
        }
      }

      _currentServer = servers[0];
      serverNotifier.value = servers[0];
      return _currentServer;
    } finally {
      _isProbing = false;
    }
  }
}
