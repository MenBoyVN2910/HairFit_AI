import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seed_data_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/barber_profile_model.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final MapController _mapController = MapController();
  BarberProfileModel? _selectedBarber;
  bool _isListView = false;

  // Tọa độ trung tâm Đà Nẵng
  static final LatLng _daNangCenter = const LatLng(16.0544, 108.2022);

  @override
  void initState() {
    super.initState();
    final barbers = SeedDataService.sampleBarbers;
    if (barbers.isNotEmpty) {
      _selectedBarber = barbers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final barbers = SeedDataService.sampleBarbers;

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _daNangCenter,
              initialZoom: 13.5,
              onTap: (_, __) {
                setState(() {
                  _selectedBarber = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hairfit_ai',
              ),
              MarkerLayer(
                markers: barbers.map((barber) {
                  final isSelected = _selectedBarber?.uid == barber.uid;
                  return Marker(
                    point: LatLng(barber.location.latitude, barber.location.longitude),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBarber = barber;
                        });
                        _mapController.move(
                          LatLng(barber.location.latitude, barber.location.longitude),
                          15.0,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.content_cut_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Header Bar & Toggle View
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppDimensions.borderRadiusMd,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bản Đồ Barber Đà Nẵng (${barbers.length} tiệm)',
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppDimensions.borderRadiusMd,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(_isListView ? Icons.map_outlined : Icons.list_alt_rounded, color: AppColors.primary),
                      tooltip: _isListView ? 'Xem bản đồ' : 'Xem danh sách',
                      onPressed: () {
                        setState(() {
                          _isListView = !_isListView;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List View Overlay if toggled
          if (_isListView)
            Positioned.fill(
              top: 90,
              child: Container(
                color: AppColors.background,
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  itemCount: barbers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedBarber = barber;
                          _isListView = false;
                        });
                        _mapController.move(
                          LatLng(barber.location.latitude, barber.location.longitude),
                          15.0,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppDimensions.borderRadiusMd,
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: AppDimensions.borderRadiusSm,
                              child: Image.network(
                                barber.avatarUrl,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.inputBackground,
                                  child: const Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(barber.displayName, style: AppTextStyles.h4),
                                  const SizedBox(height: 2),
                                  Text(barber.address, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: AppDimensions.xs),
                                  Row(
                                    children: [
                                      RatingStars(rating: barber.ratingAvg, reviewCount: barber.ratingCount),
                                      const Spacer(),
                                      Text(
                                        DateFormatter.formatPriceRange(barber.priceMin, barber.priceMax),
                                        style: AppTextStyles.badgeText.copyWith(color: AppColors.accent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Bottom Selected Barber Card
          if (_selectedBarber != null && !_isListView)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: AppDimensions.borderRadiusMd,
                            child: Image.network(
                              _selectedBarber!.avatarUrl,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 68,
                                height: 68,
                                color: AppColors.inputBackground,
                                child: const Icon(Icons.person),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedBarber!.displayName,
                                        style: AppTextStyles.h4,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const StatusBadge.approval(status: 'approved'),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedBarber!.address,
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppDimensions.xs),
                                Row(
                                  children: [
                                    RatingStars(rating: _selectedBarber!.ratingAvg, reviewCount: _selectedBarber!.ratingCount),
                                    const Spacer(),
                                    Text(
                                      DateFormatter.formatPriceRange(_selectedBarber!.priceMin, _selectedBarber!.priceMax),
                                      style: AppTextStyles.badgeText.copyWith(color: AppColors.accent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gọi điện cho: ${_selectedBarber!.displayName}')),
                                );
                              },
                              icon: const Icon(Icons.phone_outlined, size: 16),
                              label: const Text('Liên hệ'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppColors.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  builder: (context) => Padding(
                                    padding: const EdgeInsets.all(AppDimensions.lg),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Dịch Vụ Tại ${_selectedBarber!.displayName}', style: AppTextStyles.h3),
                                        const SizedBox(height: AppDimensions.md),
                                        ..._selectedBarber!.services.map((s) => ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(s.name, style: AppTextStyles.labelMedium),
                                              subtitle: Text('${s.durationMinutes} phút', style: AppTextStyles.caption),
                                              trailing: Text(DateFormatter.formatCurrency(s.price), style: AppTextStyles.labelMedium.copyWith(color: AppColors.accent)),
                                            )),
                                        const SizedBox(height: AppDimensions.lg),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Tính năng đặt lịch hẹn đang sẵn sàng trong phiên bản Pro')),
                                              );
                                            },
                                            child: const Text('Xác Nhận Đặt Lịch'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.calendar_month_outlined, size: 16),
                              label: const Text('Đặt Lịch'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
