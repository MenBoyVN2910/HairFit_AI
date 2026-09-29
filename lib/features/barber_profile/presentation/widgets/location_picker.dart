import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  bool _isLocatingGps = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);

    if (widget.initialLocation != null && widget.initialLocation!.latitude != 0.0) {
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

  /// Lấy vị trí GPS hiện tại của thiết bị
  Future<void> _fetchCurrentGps() async {
    setState(() => _isLocatingGps = true);
    try {
      final result = await LocationService().getCurrentPosition();
      if (mounted) {
        setState(() {
          _pickedLocation = result.coordinates;
          _hasPickedLocation = true;
        });
        _updateParent();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isFallback
                  ? (result.errorMessage ?? 'Sử dụng vị trí mặc định')
                  : 'Đã lấy toạ độ GPS thành công!',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: result.isFallback ? Colors.orange.shade800 : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy toạ độ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
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
            suffixIcon: _isLocatingGps
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.my_location, color: AppColors.accent),
                    tooltip: 'Lấy GPS hiện tại',
                    onPressed: _fetchCurrentGps,
                  ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => _updateParent(),
        ),
        const SizedBox(height: 16),

        // === Bản đồ preview — bấm để mở fullscreen ===
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ghim vị trí trên bản đồ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _openFullScreenMap,
              icon: const Icon(Icons.open_in_full, size: 16),
              label: const Text('Mở rộng bản đồ', style: TextStyle(fontSize: 13)),
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
                        TileServerConfig.buildTileLayer(),
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
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.touch_app, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _hasPickedLocation
                                ? 'Nhấn để điều chỉnh vị trí ghim chính xác'
                                : 'Nhấn để mở bản đồ chọn vị trí tiệm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
              const Icon(Icons.check_circle, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'Toạ độ ghim: ${_pickedLocation.latitude.toStringAsFixed(5)}, ${_pickedLocation.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi định vị: $e')),
        );
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
              TileServerConfig.buildTileLayer(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
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
                  const Icon(Icons.info_outline, size: 20, color: AppColors.accent),
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
