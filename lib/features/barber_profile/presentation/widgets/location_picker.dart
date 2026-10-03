// ============================================================================
// File: lib/features/barber_profile/presentation/widgets/location_picker.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng barber_profile.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/tile_server_config.dart';
import '../../../../models/barber_profile_model.dart';

/// Widget chọn vị trí tiệm — nhúng trong Stepper đăng ký hồ sơ thợ (Task 3.5 & Task 2.x)
class LocationPicker extends StatefulWidget {
  final String initialAddress;
  final GeoLocation? initialLocation;
  final Function(String address, GeoLocation location) onChanged;

  const LocationPicker({
    super.key,
    this.initialAddress = '',
    this.initialLocation,
    required this.onChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late TextEditingController _addressController;
  late LatLng _pickedLocation;
  bool _hasPickedLocation = false;
  bool _isSearchingAddress = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);

    if (widget.initialLocation != null &&
        widget.initialLocation!.latitude != 0.0) {
      _pickedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _hasPickedLocation = true;
    } else {
      _pickedLocation = LocationService.defaultCoordinates;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _updateParent() {
    widget.onChanged(
      _addressController.text.trim(),
      GeoLocation(
        latitude: _pickedLocation.latitude,
        longitude: _pickedLocation.longitude,
      ),
    );
  }

  /// Geocoding địa chỉ qua OpenStreetMap Nominatim
  /// Thử nhiều biến thể để tối đa tỷ lệ tìm thấy vị trí chính xác của tiệm
  Future<LatLng?> _geocodeAddress(String rawAddress) async {
    final cleanAddress = rawAddress.trim();
    if (cleanAddress.isEmpty) return null;

    final queries = <String>[];
    queries.add(cleanAddress);

    if (!cleanAddress.toLowerCase().contains('việt nam') &&
        !cleanAddress.toLowerCase().contains('vietnam')) {
      queries.add('$cleanAddress, Việt Nam');
    }

    // Nếu có dạng số/hẻm: ví dụ "109/24 Nguyễn Văn Luông" -> thử thêm cụm từ tên đường trở đi
    if (cleanAddress.contains('/')) {
      final textOnly = cleanAddress.replaceFirst(
        RegExp(r'^[0-9\/A-Za-z]+[\s,]+'),
        '',
      );
      if (textOnly.isNotEmpty && textOnly != cleanAddress) {
        queries.add(textOnly);
        queries.add('$textOnly, Việt Nam');
      }
    }

    for (final q in queries) {
      try {
        final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': q,
          'format': 'json',
          'limit': '1',
          'countrycodes': 'vn',
        });

        final res = await http
            .get(
              uri,
              headers: {
                'User-Agent': 'HairFit_AI_App/1.0 (contact: admin@hairfit.vn)',
              },
            )
            .timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is List && data.isNotEmpty) {
            final first = data[0];
            final lat = double.tryParse(first['lat']?.toString() ?? '');
            final lon = double.tryParse(first['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              return LatLng(lat, lon);
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  /// Tìm vị trí dựa CHÍNH XÁC trên địa chỉ thợ vừa nhập
  /// Tuyệt đối không lấy vị trí GPS hiện tại của điện thoại
  Future<void> _locateAddressFromText() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ tiệm trước khi bấm tìm vị trí!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSearchingAddress = true);

    try {
      final coordinates = await _geocodeAddress(text);

      if (!mounted) return;

      if (coordinates != null) {
        setState(() {
          _pickedLocation = coordinates;
          _hasPickedLocation = true;
        });
        _updateParent();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Đã định vị đúng địa chỉ tiệm trên bản đồ!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Không tìm thấy tự động -> Gợi ý User tự ghim vị trí thủ công trên bản đồ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Không tìm thấy toạ độ tự động. Bạn hãy nhấn vào bản đồ để tự ghim vị trí tiệm!',
            ),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Mở bản đồ',
              textColor: Colors.white,
              onPressed: _openFullScreenMap,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tìm kiếm: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  Future<void> _openFullScreenMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _FullScreenMapPicker(initialCenter: _pickedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _pickedLocation = result;
        _hasPickedLocation = true;
      });
      _updateParent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === Ô nhập địa chỉ ===
        const Text(
          'Địa chỉ chi tiết của tiệm',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: 'VD: 123 Nguyễn Văn Linh, Hải Châu, Đà Nẵng',
            prefixIcon: const Icon(Icons.business_outlined),
            suffixIcon: _isSearchingAddress
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      color: AppColors.accent,
                    ),
                    tooltip: 'Tìm vị trí theo địa chỉ',
                    onPressed: _locateAddressFromText,
                  ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => _updateParent(),
        ),
        const SizedBox(height: 16),

        // === Bản đồ preview — bấm để mở fullscreen ===
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ghim vị trí trên bản đồ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: _openFullScreenMap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_full, size: 14),
              label: const Text(
                'Mở rộng bản đồ',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        GestureDetector(
          onTap: _openFullScreenMap,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  // Static map preview với key động để tự động cập nhật khi đổi toạ độ
                  AbsorbPointer(
                    child: FlutterMap(
                      key: ValueKey(
                        '${_pickedLocation.latitude}_${_pickedLocation.longitude}',
                      ),
                      options: MapOptions(
                        initialCenter: _pickedLocation,
                        initialZoom: 15.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        ValueListenableBuilder<TileServerInfo>(
                          valueListenable: TileServerConfig.serverNotifier,
                          builder: (context, currentServer, _) {
                            return TileServerConfig.buildTileLayer(
                              server: currentServer,
                            );
                          },
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Overlay hướng dẫn bấm vào
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _hasPickedLocation
                                  ? 'Nhấn để điều chỉnh vị trí ghim chính xác'
                                  : 'Nhấn để mở bản đồ chọn vị trí tiệm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_hasPickedLocation) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Toạ độ ghim: ${_pickedLocation.latitude.toStringAsFixed(5)}, ${_pickedLocation.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ===================================================================
// Trang Full Screen Map Picker: Cho phép kéo thả chọn vị trí salon
// ===================================================================
class _FullScreenMapPicker extends StatefulWidget {
  final LatLng initialCenter;

  const _FullScreenMapPicker({required this.initialCenter});

  @override
  State<_FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<_FullScreenMapPicker> {
  final MapController _mapController = MapController();
  late LatLng _center;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentGps() async {
    setState(() => _isLocating = true);
    try {
      final loc = await LocationService().getCurrentPosition();
      _center = loc.coordinates;
      _mapController.move(loc.coordinates, 16.5);
      if (mounted && loc.isFallback && loc.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorMessage!),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi định vị: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí tiệm trên bản đồ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Bản đồ chính với TileServerConfig
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              minZoom: 5.0,
              maxZoom: 18.5,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _center = camera.center;
                  });
                }
              },
            ),
            children: [
              ValueListenableBuilder<TileServerInfo>(
                valueListenable: TileServerConfig.serverNotifier,
                builder: (context, currentServer, _) {
                  return TileServerConfig.buildTileLayer(server: currentServer);
                },
              ),
            ],
          ),

          // Pin trung tâm cố định màu đỏ
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Vị trí salon',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 48,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Chấm bóng dưới chân pin
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),

          // Banner hướng dẫn trên đầu
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kéo bản đồ để đặt đầu kim pin đúng vị trí salon của bạn.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút điều khiển bên phải: Phóng to, Thu nhỏ, GPS
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút Zoom In
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_center, zoom + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),

                // Nút Zoom Out
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_center, zoom - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),

                // Nút GPS "Vị trí của tôi"
                FloatingActionButton(
                  heroTag: 'gps_locate_btn',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _isLocating ? null : _moveToCurrentGps,
                  child: _isLocating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),

      // Thanh dưới xác nhận toạ độ
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, -2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.place, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Toạ độ: ${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _center),
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận vị trí này'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
