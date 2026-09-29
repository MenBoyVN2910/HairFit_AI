import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seed_data_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/status_badge.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = 'hairstyles'; // 'hairstyles' or 'barbers'
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hairstyles = SeedDataService.sampleHairstyles;
    final barbers = SeedDataService.sampleBarbers;

    final filteredHairstyles = hairstyles.where((h) {
      if (_query.isEmpty) return true;
      return h.name.toLowerCase().contains(_query.toLowerCase()) ||
          h.tags.any((t) => t.toLowerCase().contains(_query.toLowerCase())) ||
          h.faceShapes.any((f) => f.toLowerCase().contains(_query.toLowerCase()));
    }).toList();

    final filteredBarbers = barbers.where((b) {
      if (_query.isEmpty) return true;
      return b.displayName.toLowerCase().contains(_query.toLowerCase()) ||
          b.address.toLowerCase().contains(_query.toLowerCase()) ||
          b.services.any((s) => s.name.toLowerCase().contains(_query.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tìm Kiếm Nâng Cao', style: AppTextStyles.h2),
              const SizedBox(height: AppDimensions.md),
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _query = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: _searchType == 'hairstyles' ? 'Tìm kiểu tóc, dáng mặt (Oval, Square...)' : 'Tìm tên barber, địa chỉ, dịch vụ...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppDimensions.borderRadiusMd,
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              // Type Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Kiểu Tóc')),
                      selected: _searchType == 'hairstyles',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _searchType == 'hairstyles' ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: AppColors.surface,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = 'hairstyles';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Barber Shop')),
                      selected: _searchType == 'barbers',
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _searchType == 'barbers' ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: AppColors.surface,
                      onSelected: (selected) {
                        setState(() {
                          _searchType = 'barbers';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              // Results Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchType == 'hairstyles' ? 'Kết quả kiểu tóc' : 'Kết quả Barber',
                    style: AppTextStyles.h4,
                  ),
                  Text(
                    '${_searchType == 'hairstyles' ? filteredHairstyles.length : filteredBarbers.length} kết quả',
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              // Results List
              Expanded(
                child: _searchType == 'hairstyles'
                    ? (filteredHairstyles.isEmpty
                        ? const Center(child: Text('Không tìm thấy kiểu tóc nào phù hợp'))
                        : ListView.separated(
                            itemCount: filteredHairstyles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
                            itemBuilder: (context, index) {
                              final item = filteredHairstyles[index];
                              return Container(
                                padding: const EdgeInsets.all(AppDimensions.sm),
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
                                        item.imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 70,
                                          height: 70,
                                          color: AppColors.inputBackground,
                                          child: const Icon(Icons.image),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppDimensions.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.name, style: AppTextStyles.h4),
                                          const SizedBox(height: 2),
                                          Text(item.description, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: AppDimensions.xs),
                                          Text(
                                            'Tags: ${item.tags.join(', ')}',
                                            style: AppTextStyles.caption.copyWith(color: AppColors.accent),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ))
                    : (filteredBarbers.isEmpty
                        ? const Center(child: Text('Không tìm thấy Barber nào phù hợp'))
                        : ListView.separated(
                            itemCount: filteredBarbers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.md),
                            itemBuilder: (context, index) {
                              final barber = filteredBarbers[index];
                              return Container(
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
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 70,
                                          height: 70,
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
                                              Expanded(child: Text(barber.displayName, style: AppTextStyles.h4)),
                                              const StatusBadge.approval(status: 'approved'),
                                            ],
                                          ),
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
                              );
                            },
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
