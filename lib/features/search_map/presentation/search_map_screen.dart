// ============================================================================
// File: lib/features/search_map/presentation/search_map_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng search_map.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/services/tile_server_config.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../ai_consult/data/hairstyle_repository.dart';
import '../../../../models/hairstyle_model.dart';
import '../../../../providers/search_provider.dart';
import 'widgets/barber_bottom_sheet.dart';
import 'widgets/barber_list_view.dart';
import 'widgets/hairstyle_picker_bottom_sheet.dart';
import 'widgets/map_marker.dart';

/// Màn hình Bản đồ & Tìm kiếm thợ cắt tóc (Task 3.5, 3.9, 3.11)
class SearchMapScreen extends ConsumerStatefulWidget {
  final String? initialHairstyleId;

  const SearchMapScreen({super.key, this.initialHairstyleId});

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

  void _showPriceFilterSheet(SearchMapState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (ctx) {
        final currentMax = state.maxPriceFilter;
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lọc theo giá dịch vụ', style: AppTextStyles.h4),
                  if (currentMax != null)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(searchNotifierProvider.notifier)
                            .setMaxPriceFilter(null);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Đặt lại',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              const Text(
                'Chọn mức giá khởi điểm tối đa:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriceChip(
                    ctx,
                    null,
                    'Tất cả mức giá',
                    currentMax == null,
                  ),
                  _buildPriceChip(
                    ctx,
                    80000,
                    'Dưới 80.000đ',
                    currentMax == 80000,
                  ),
                  _buildPriceChip(
                    ctx,
                    100000,
                    'Dưới 100.000đ',
                    currentMax == 100000,
                  ),
                  _buildPriceChip(
                    ctx,
                    150000,
                    'Dưới 150.000đ',
                    currentMax == 150000,
                  ),
                  _buildPriceChip(
                    ctx,
                    200000,
                    'Dưới 200.000đ',
                    currentMax == 200000,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceChip(
    BuildContext ctx,
    int? price,
    String label,
    bool isSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.accent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        ref.read(searchNotifierProvider.notifier).setMaxPriceFilter(price);
        Navigator.pop(ctx);
      },
    );
  }

  void _showMapStyleSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (ctx) {
        return ValueListenableBuilder<TileServerInfo>(
          valueListenable: TileServerConfig.serverNotifier,
          builder: (context, current, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.lg,
                vertical: AppDimensions.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chọn kiểu bản đồ', style: AppTextStyles.h4),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  ...TileServerConfig.servers.map((server) {
                    final isSelected = server.name == current.name;
                    IconData iconData = Icons.map_outlined;
                    if (server.name.contains('Vệ tinh')) {
                      iconData = Icons.satellite_alt_outlined;
                    } else if (server.name.contains('OpenStreetMap')) {
                      iconData = Icons.public_outlined;
                    }
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[700],
                        ),
                      ),
                      title: Text(
                        server.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () {
                        TileServerConfig.setServer(server);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                  const SizedBox(height: AppDimensions.sm),
                ],
              ),
            );
          },
        );
      },
    );
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
                onRetry: () =>
                    ref.read(searchNotifierProvider.notifier).reload(),
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
                            await ref
                                .read(searchNotifierProvider.notifier)
                                .reload();
                          },
                          onClearFilter: () {
                            _searchController.clear();
                            ref
                                .read(searchNotifierProvider.notifier)
                                .setSearchQuery('');
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
              padding: EdgeInsets.only(
                left: AppDimensions.xs,
                right: AppDimensions.xs,
              ),
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
            tooltip: state.isListView
                ? 'Xem trên Bản đồ'
                : 'Xem dạng Danh sách',
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
          const SizedBox(width: AppDimensions.xs),

          // Nút lọc giá (Task 6.11)
          IconButton(
            tooltip: 'Lọc theo giá',
            style: IconButton.styleFrom(
              backgroundColor: state.maxPriceFilter != null
                  ? AppColors.accent
                  : AppColors.background,
              foregroundColor: state.maxPriceFilter != null
                  ? Colors.white
                  : AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: state.maxPriceFilter != null
                      ? AppColors.accent
                      : AppColors.border,
                ),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 20),
            onPressed: () => _showPriceFilterSheet(state),
          ),
        ],
      ),
    );
  }

  /// Dải chọn và lọc kiểu tóc hiện đại hỗ trợ danh mục lớn (100+ kiểu tóc)
  Widget _buildHairstyleChips(
    SearchMapState state,
    AsyncValue<List<HairstyleModel>> hairstylesAsync,
  ) {
    final allHairstyles = hairstylesAsync.value ?? [];
    HairstyleModel? selectedStyle;
    if (state.selectedHairstyleId != null && allHairstyles.isNotEmpty) {
      final matches = allHairstyles.where(
        (s) => s.id == state.selectedHairstyleId,
      );
      if (matches.isNotEmpty) {
        selectedStyle = matches.first;
      }
    }

    return Container(
      color: AppColors.surface,
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Nút mở modal Danh mục kiểu tóc lớn (100+ kiểu tóc)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: AppColors.accent,
              ),
              label: Text(
                allHairstyles.isNotEmpty
                    ? 'Bộ sưu tập (${allHairstyles.length} kiểu)'
                    : 'Bộ sưu tập kiểu tóc',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              side: const BorderSide(color: AppColors.accent, width: 1.2),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (allHairstyles.isNotEmpty) {
                  HairstylePickerBottomSheet.show(
                    context: context,
                    hairstyles: allHairstyles,
                    selectedHairstyleId: state.selectedHairstyleId,
                    onSelectHairstyle: (styleId) {
                      ref
                          .read(searchNotifierProvider.notifier)
                          .setHairstyleFilter(styleId);
                    },
                  );
                }
              },
            ),
          ),

          // Chip lọc giá đang kích hoạt (nếu có)
          if (state.maxPriceFilter != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text('≤ ${state.maxPriceFilter! ~/ 1000}k'),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: AppColors.accent,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                onDeleted: () {
                  ref
                      .read(searchNotifierProvider.notifier)
                      .setMaxPriceFilter(null);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],

          // Nếu đang có một kiểu tóc được chọn: Hiển thị InputChip nổi bật có nút X xóa và đổi
          if (selectedStyle != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                avatar: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white,
                ),
                label: Text(selectedStyle.name),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                backgroundColor: AppColors.accent,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                onDeleted: () {
                  ref
                      .read(searchNotifierProvider.notifier)
                      .setHairstyleFilter(null);
                },
                onPressed: () {
                  HairstylePickerBottomSheet.show(
                    context: context,
                    hairstyles: allHairstyles,
                    selectedHairstyleId: state.selectedHairstyleId,
                    onSelectHairstyle: (styleId) {
                      ref
                          .read(searchNotifierProvider.notifier)
                          .setHairstyleFilter(styleId);
                    },
                  );
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],

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

          // Hiển thị một số kiểu tóc để chọn nhanh
          ...allHairstyles.take(6).map((style) {
            final isSelected = state.selectedHairstyleId == style.id;
            if (isSelected) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(style.name),
                selected: false,
                onSelected: (selected) {
                  ref
                      .read(searchNotifierProvider.notifier)
                      .setHairstyleFilter(selected ? style.id : null);
                },
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.border),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),

          if (allHairstyles.length > 6)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text('+${allHairstyles.length - 6} kiểu khác...'),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.border),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  HairstylePickerBottomSheet.show(
                    context: context,
                    hairstyles: allHairstyles,
                    selectedHairstyleId: state.selectedHairstyleId,
                    onSelectHairstyle: (styleId) {
                      ref
                          .read(searchNotifierProvider.notifier)
                          .setHairstyleFilter(styleId);
                    },
                  );
                },
              ),
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
      if (loc.latitude == 0.0 && loc.longitude == 0.0) continue;
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
            ValueListenableBuilder<TileServerInfo>(
              valueListenable: TileServerConfig.serverNotifier,
              builder: (context, currentServer, _) {
                return TileServerConfig.buildTileLayer(server: currentServer);
              },
            ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Nút đổi giao diện bản đồ (Dịu mắt / Vệ tinh / OSM)
        Positioned(
          right: AppDimensions.md,
          bottom: AppDimensions.xl + 54,
          child: FloatingActionButton.small(
            heroTag: 'fab_map_style',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            elevation: 3,
            tooltip: 'Đổi kiểu bản đồ',
            onPressed: _showMapStyleSheet,
            child: const Icon(Icons.layers_outlined),
          ),
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
