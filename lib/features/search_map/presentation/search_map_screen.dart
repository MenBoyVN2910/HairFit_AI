import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../core/services/tile_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../ai_consult/data/hairstyle_repository.dart';
import '../../../../models/hairstyle_model.dart';
import '../../../../providers/search_provider.dart';
import 'widgets/barber_bottom_sheet.dart';
import 'widgets/barber_list_view.dart';
import 'widgets/map_marker.dart';

/// Màn hình Bản đồ & Tìm kiếm thợ cắt tóc (Task 3.5, 3.9, 3.11)
class SearchMapScreen extends ConsumerStatefulWidget {
  final String? initialHairstyleId;

  const SearchMapScreen({
    super.key,
    this.initialHairstyleId,
  });

  @override
  ConsumerState<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends ConsumerState<SearchMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _hasAppliedInitialHairstyle = false;
  bool _dismissedLocationBanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialHairstyleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasAppliedInitialHairstyle && mounted) {
          ref
              .read(searchNotifierProvider.notifier)
              .setHairstyleFilter(widget.initialHairstyleId);
          _hasAppliedInitialHairstyle = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMarkerTapped(BarberWithDistance item) {
    ref.read(searchNotifierProvider.notifier).selectBarber(item.barber);
    _mapController.move(
      LatLng(item.barber.location.latitude, item.barber.location.longitude),
      15.5,
    );
    BarberBottomSheet.show(context, item);
  }

  Future<void> _moveToCurrentGps() async {
    final notifier = ref.read(searchNotifierProvider.notifier);
    await notifier.refreshUserLocation();
    final state = ref.read(searchNotifierProvider).value;
    if (state != null) {
      _mapController.move(state.referenceLocation, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchNotifierProvider);
    final hairstylesAsync = ref.watch(hairstylesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: searchAsync.when(
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  SizedBox(height: AppDimensions.md),
                  Text(
                    'Đang tải bản đồ và vị trí tiệm thợ...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(title: const Text('Tìm thợ cắt tóc')),
            body: Center(
              child: ErrorRetry(
                errorMessage: 'Không thể tải dữ liệu thợ: $error',
                onRetry: () => ref.read(searchNotifierProvider.notifier).reload(),
              ),
            ),
          ),
          data: (state) {
            return Column(
              children: [
                // Thanh Header tìm kiếm và chuyển đổi chế độ xem
                _buildSearchHeader(state),

                // Danh sách Chips lọc kiểu tóc
                _buildHairstyleChips(state, hairstylesAsync),

                // Banner thông báo vị trí fallback (nếu có và chưa bị tắt)
                if (state.isGpsFallback &&
                    state.locationMessage != null &&
                    !_dismissedLocationBanner)
                  _buildLocationFallbackBanner(state.locationMessage!),

                // Nội dung chính: Bản đồ hoặc Danh sách thợ
                Expanded(
                  child: state.isListView
                      ? BarberListView(
                          searchState: state,
                          onRefresh: () async {
                            await ref.read(searchNotifierProvider.notifier).reload();
                          },
                          onClearFilter: () {
                            _searchController.clear();
                            ref.read(searchNotifierProvider.notifier).setSearchQuery('');
                            ref
                                .read(searchNotifierProvider.notifier)
                                .setHairstyleFilter(null);
                          },
                        )
                      : _buildMapView(state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Thanh tìm kiếm + Nút back + Toggle Map/List
  Widget _buildSearchHeader(SearchMapState state) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.sm,
        AppDimensions.sm,
        AppDimensions.sm,
        AppDimensions.xs,
      ),
      child: Row(
        children: [
          // Nút quay lại (nếu có thể pop)
          if (context.canPop())
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            )
          else
            const Padding(
              padding: EdgeInsets.only(left: AppDimensions.xs, right: AppDimensions.xs),
              child: Icon(Icons.location_on, color: AppColors.accent, size: 24),
            ),

          // Ô nhập tìm kiếm thợ
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppDimensions.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên thợ, địa chỉ...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchNotifierProvider.notifier)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  ref.read(searchNotifierProvider.notifier).setSearchQuery(val);
                },
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xs),

          // Nút toggle Map / List view
          IconButton(
            tooltip: state.isListView ? 'Xem trên Bản đồ' : 'Xem dạng Danh sách',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              state.isListView ? Icons.map_rounded : Icons.view_list_rounded,
              size: 20,
            ),
            onPressed: () {
              ref.read(searchNotifierProvider.notifier).toggleViewMode();
            },
          ),
        ],
      ),
    );
  }

  /// Dải chip lọc kiểu tóc ngang
  Widget _buildHairstyleChips(
    SearchMapState state,
    AsyncValue<List<HairstyleModel>> hairstylesAsync,
  ) {
    return Container(
      color: AppColors.surface,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Chip "Tất cả kiểu tóc"
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: const Text('Tất cả kiểu'),
              selected: state.selectedHairstyleId == null,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(searchNotifierProvider.notifier)
                      .setHairstyleFilter(null);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.selectedHairstyleId == null
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.selectedHairstyleId == null
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: state.selectedHairstyleId == null
                    ? AppColors.primary
                    : AppColors.border,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),

          // Danh sách các kiểu tóc từ catalog
          ...hairstylesAsync.when(
            data: (hairstyles) {
              return hairstyles.map((style) {
                final isSelected = state.selectedHairstyleId == style.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: isSelected
                        ? const Icon(Icons.auto_awesome,
                            size: 13, color: Colors.white)
                        : null,
                    label: Text(style.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref
                          .read(searchNotifierProvider.notifier)
                          .setHairstyleFilter(selected ? style.id : null);
                    },
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : AppColors.border,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList();
            },
            loading: () => [
              const SizedBox(
                width: 100,
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ],
            error: (_, _) => const [],
          ),
        ],
      ),
    );
  }

  /// Banner thông báo khi người dùng từ chối quyền GPS hoặc GPS yếu
  Widget _buildLocationFallbackBanner(String message) {
    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _dismissedLocationBanner = true;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Giao diện Bản đồ OpenStreetMap (Task 3.5)
  Widget _buildMapView(SearchMapState state) {
    final markers = <Marker>[];

    // 1. Marker vị trí người dùng (nếu có GPS thực)
    if (state.userGpsLocation != null) {
      markers.add(
        Marker(
          point: state.userGpsLocation!,
          width: 30,
          height: 30,
          child: const UserLocationMarker(),
        ),
      );
    }

    // 2. Markers các thợ cắt tóc đã duyệt
    for (final item in state.displayBarbers) {
      final loc = item.barber.location;
      markers.add(
        Marker(
          point: LatLng(loc.latitude, loc.longitude),
          width: 44,
          height: 48,
          child: BarberMapMarker(
            item: item,
            onTap: () => _onMarkerTapped(item),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Widget FlutterMap tương thích v8.x
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: state.referenceLocation,
            initialZoom: 14.5,
            minZoom: 10.0,
            maxZoom: 18.0,
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture) {
                // Cập nhật tâm tham chiếu khi người dùng tự kéo bản đồ
                ref
                    .read(searchNotifierProvider.notifier)
                    .setReferenceLocation(camera.center);
              }
            },
          ),
          children: [
            TileServerConfig.buildTileLayer(),
            MarkerLayer(markers: markers),
          ],
        ),

        // Nút định vị "Vị trí của tôi" (GPS)
        Positioned(
          right: AppDimensions.md,
          bottom: AppDimensions.xl,
          child: FloatingActionButton.small(
            heroTag: 'fab_my_location',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: state.isLocating ? null : _moveToCurrentGps,
            child: state.isLocating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),

        // Badge đếm số lượng thợ ở góc trái trên
        Positioned(
          left: AppDimensions.md,
          top: AppDimensions.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.content_cut,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.displayBarbers.length} thợ gần bạn',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
