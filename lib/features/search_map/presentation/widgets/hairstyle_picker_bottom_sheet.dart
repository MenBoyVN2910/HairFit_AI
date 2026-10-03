// ============================================================================
// File: lib/features/search_map/presentation/widgets/hairstyle_picker_bottom_sheet.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng search_map.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../models/hairstyle_model.dart';

/// Modal BottomSheet chọn kiểu tóc chuyên nghiệp hỗ trợ danh mục lớn (100+ kiểu tóc)
class HairstylePickerBottomSheet extends StatefulWidget {
  final List<HairstyleModel> hairstyles;
  final String? selectedHairstyleId;
  final ValueChanged<String?> onSelectHairstyle;

  const HairstylePickerBottomSheet({
    super.key,
    required this.hairstyles,
    required this.selectedHairstyleId,
    required this.onSelectHairstyle,
  });

  static Future<void> show({
    required BuildContext context,
    required List<HairstyleModel> hairstyles,
    required String? selectedHairstyleId,
    required ValueChanged<String?> onSelectHairstyle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HairstylePickerBottomSheet(
        hairstyles: hairstyles,
        selectedHairstyleId: selectedHairstyleId,
        onSelectHairstyle: onSelectHairstyle,
      ),
    );
  }

  @override
  State<HairstylePickerBottomSheet> createState() =>
      _HairstylePickerBottomSheetState();
}

class _HairstylePickerBottomSheetState
    extends State<HairstylePickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGenderFilter = 'all'; // 'all', 'male', 'female', 'unisex'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HairstyleModel> _getFilteredHairstyles() {
    return widget.hairstyles.where((style) {
      // 1. Lọc theo tìm kiếm từ khóa (tên hoặc mô tả hoặc tag hoặc dáng mặt)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = style.name.toLowerCase().contains(q);
        final descMatch = style.description.toLowerCase().contains(q);
        final faceMatch = style.faceShapes.any(
          (face) => face.toLowerCase().contains(q),
        );
        final tagMatch = style.tags.any((tag) => tag.toLowerCase().contains(q));
        if (!nameMatch && !descMatch && !faceMatch && !tagMatch) {
          return false;
        }
      }

      // 2. Lọc theo giới tính / tag
      if (_selectedGenderFilter != 'all') {
        final tagsLower = style.tags.map((t) => t.toLowerCase()).toList();
        if (_selectedGenderFilter == 'male') {
          final isMale = tagsLower.any((t) => t.contains('nam') || t == 'men');
          if (!isMale) return false;
        } else if (_selectedGenderFilter == 'female') {
          final isFemale = tagsLower.any(
            (t) => t.contains('nữ') || t.contains('nu') || t == 'women',
          );
          if (!isFemale) return false;
        } else if (_selectedGenderFilter == 'unisex') {
          final isUnisex = tagsLower.any((t) => t.contains('unisex'));
          if (!isUnisex) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredHairstyles();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: AppDimensions.sm),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Header: Tiêu đề, số lượng & nút reset
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danh Mục Kiểu Tóc', style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.hairstyles.length} kiểu tóc phong cách',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selectedHairstyleId != null)
                  TextButton.icon(
                    onPressed: () {
                      widget.onSelectHairstyle(null);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 18),
                    label: const Text('Xem tất cả'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Thanh Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
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
                  hintText: 'Tìm theo tên kiểu tóc, dáng mặt...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val.trim());
                },
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // Bộ lọc Tabs giới tính / danh mục
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Row(
              children: [
                _buildFilterTab('all', 'Tất cả (${widget.hairstyles.length})'),
                const SizedBox(width: 8),
                _buildFilterTab('male', 'Nam giới'),
                const SizedBox(width: 8),
                _buildFilterTab('female', 'Nữ giới'),
                const SizedBox(width: 8),
                _buildFilterTab('unisex', 'Unisex'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          const Divider(height: 1, color: AppColors.divider),

          // GridView danh sách kiểu tóc
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.content_cut_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        const Text(
                          'Không tìm thấy kiểu tóc phù hợp',
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thử tìm với từ khóa khác hoặc xóa bộ lọc',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final style = filtered[index];
                      final isSelected = style.id == widget.selectedHairstyleId;

                      return _buildHairstyleCard(style, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String key, String label) {
    final isSelected = _selectedGenderFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGenderFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildHairstyleCard(HairstyleModel style, bool isSelected) {
    final displayImg = style.displayImages.isNotEmpty
        ? style.displayImages.first
        : style.imageUrl;

    return InkWell(
      onTap: () {
        widget.onSelectHairstyle(style.id);
        Navigator.pop(context);
      },
      borderRadius: AppDimensions.borderRadiusMd,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadiusMd,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hình ảnh kiểu tóc
                Expanded(
                  flex: 3,
                  child: displayImg.isNotEmpty
                      ? Image.network(
                          displayImg,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: AppColors.background,
                                child: const Center(
                                  child: Icon(
                                    Icons.content_cut_rounded,
                                    color: AppColors.textSecondary,
                                    size: 36,
                                  ),
                                ),
                              ),
                        )
                      : Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.content_cut_rounded,
                              color: AppColors.textSecondary,
                              size: 36,
                            ),
                          ),
                        ),
                ),

                // Thông tin tên & dáng mặt
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (style.faceShapes.isNotEmpty)
                          Text(
                            'Mặt: ${style.faceShapes.take(2).join(', ')}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Badge Đang chọn
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
