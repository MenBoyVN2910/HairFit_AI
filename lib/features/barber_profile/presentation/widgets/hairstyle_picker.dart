// ============================================================================
// File: lib/features/barber_profile/presentation/widgets/hairstyle_picker.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng barber_profile.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai_consult/data/hairstyle_repository.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../models/hairstyle_model.dart';

/// Bộ chọn kiểu tóc hỗ trợ cắt dành cho Thợ (Task 2.x & User Request)
/// Thiết kế hiện đại, hỗ trợ mượt mà từ 10 đến 1000+ kiểu tóc với tìm kiếm, phân loại và modal chọn nhiều.
class HairstylePicker extends ConsumerStatefulWidget {
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onChanged;

  const HairstylePicker({
    super.key,
    required this.initialSelectedIds,
    required this.onChanged,
  });

  @override
  ConsumerState<HairstylePicker> createState() => _HairstylePickerState();
}

class _HairstylePickerState extends ConsumerState<HairstylePicker> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
  }

  void _openMultiSelectModal(List<HairstyleModel> allStyles) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HairstyleMultiSelectModal(
        allStyles: allStyles,
        initialSelectedIds: _selectedIds,
        onConfirmed: (newSelected) {
          setState(() {
            _selectedIds = newSelected;
          });
          widget.onChanged(_selectedIds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hairstylesAsyncValue = ref.watch(hairstylesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.content_cut_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Kiểu tóc hỗ trợ cắt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Đã chọn: ${_selectedIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn các kiểu tóc mà salon bạn có thể cắt cho khách hàng',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),

        hairstylesAsyncValue.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text(
            'Lỗi tải danh mục kiểu tóc: $e',
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
          data: (allStyles) {
            // Lấy danh sách model của các kiểu đã chọn
            final selectedModels = allStyles
                .where((s) => _selectedIds.contains(s.id))
                .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút mở modal chọn kiểu tóc
                InkWell(
                  onTap: () => _openMultiSelectModal(allStyles),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedIds.isEmpty
                                    ? 'Nhấn để chọn kiểu tóc hỗ trợ'
                                    : 'Quản lý danh sách kiểu tóc (${_selectedIds.length}/${allStyles.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tìm kiếm & chọn nhanh trong ${allStyles.length} kiểu tóc',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),

                // Danh sách chip các kiểu tóc đã chọn
                if (selectedModels.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...selectedModels.take(10).map((style) {
                        return InputChip(
                          avatar: const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          label: Text(style.name),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          backgroundColor: AppColors.surface,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() {
                              _selectedIds.remove(style.id);
                            });
                            widget.onChanged(_selectedIds);
                          },
                        );
                      }),
                      if (selectedModels.length > 10)
                        ActionChip(
                          label: Text(
                            '+${selectedModels.length - 10} kiểu khác...',
                          ),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                          backgroundColor: AppColors.accent.withValues(
                            alpha: 0.1,
                          ),
                          onPressed: () => _openMultiSelectModal(allStyles),
                        ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Modal chọn nhiều kiểu tóc hỗ trợ hàng trăm/nghìn kiểu tóc
class _HairstyleMultiSelectModal extends StatefulWidget {
  final List<HairstyleModel> allStyles;
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onConfirmed;

  const _HairstyleMultiSelectModal({
    required this.allStyles,
    required this.initialSelectedIds,
    required this.onConfirmed,
  });

  @override
  State<_HairstyleMultiSelectModal> createState() =>
      _HairstyleMultiSelectModalState();
}

class _HairstyleMultiSelectModalState
    extends State<_HairstyleMultiSelectModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Set<String> _tempSelectedIds;
  String _searchQuery = '';
  String _genderFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = Set.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<HairstyleModel> _getFiltered() {
    return widget.allStyles.where((style) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = style.name.toLowerCase().contains(q);
        final descMatch = style.description.toLowerCase().contains(q);
        final faceMatch = style.faceShapes.any(
          (f) => f.toLowerCase().contains(q),
        );
        final tagMatch = style.tags.any((t) => t.toLowerCase().contains(q));
        if (!nameMatch && !descMatch && !faceMatch && !tagMatch) return false;
      }

      if (_genderFilter != 'all') {
        final tags = style.tags.map((t) => t.toLowerCase()).toList();
        if (_genderFilter == 'male') {
          if (!tags.any((t) => t.contains('nam') || t == 'men')) return false;
        } else if (_genderFilter == 'female') {
          if (!tags.any(
            (t) => t.contains('nữ') || t.contains('nu') || t == 'women',
          )) {
            return false;
          }
        } else if (_genderFilter == 'unisex') {
          if (!tags.any((t) => t.contains('unisex'))) return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();

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
          // Drag handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn Kiểu Tóc Hỗ Trợ',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Đã chọn ${_tempSelectedIds.length}/${widget.allStyles.length} kiểu tóc',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_tempSelectedIds.length == widget.allStyles.length) {
                        _tempSelectedIds.clear();
                      } else {
                        _tempSelectedIds = widget.allStyles
                            .map((s) => s.id)
                            .toSet();
                      }
                    });
                  },
                  child: Text(
                    _tempSelectedIds.length == widget.allStyles.length
                        ? 'Bỏ chọn hết'
                        : 'Chọn tất cả',
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

          // Thanh tìm kiếm
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
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên kiểu tóc, dáng mặt...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
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

          // Tabs giới tính
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
            child: Row(
              children: [
                _buildGenderTab('all', 'Tất cả (${widget.allStyles.length})'),
                const SizedBox(width: 8),
                _buildGenderTab('male', 'Nam giới'),
                const SizedBox(width: 8),
                _buildGenderTab('female', 'Nữ giới'),
                const SizedBox(width: 8),
                _buildGenderTab('unisex', 'Unisex'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          const Divider(height: 1, color: AppColors.divider),

          // Danh sách kiểu tóc dạng ListView (tối ưu hóa cho hàng trăm/nghìn kiểu)
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy kiểu tóc nào phù hợp.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: AppDimensions.sm,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final style = filtered[index];
                      final isChecked = _tempSelectedIds.contains(style.id);
                      final imgUrl = style.displayImages.isNotEmpty
                          ? style.displayImages.first
                          : style.imageUrl;

                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: AppColors.accent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        secondary: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imgUrl.isNotEmpty
                              ? Image.network(
                                  imgUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.background,
                                    child: const Icon(
                                      Icons.content_cut,
                                      size: 24,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.background,
                                  child: const Icon(
                                    Icons.content_cut,
                                    size: 24,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                        title: Text(
                          style.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isChecked
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isChecked
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          style.faceShapes.isNotEmpty
                              ? 'Mặt: ${style.faceShapes.take(2).join(', ')}'
                              : style.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _tempSelectedIds.add(style.id);
                            } else {
                              _tempSelectedIds.remove(style.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // Nút xác nhận ở chân trang
          Container(
            padding: const EdgeInsets.all(AppDimensions.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    widget.onConfirmed(_tempSelectedIds.toList());
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Xác Nhận Đã Chọn (${_tempSelectedIds.length} Kiểu Tóc)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTab(String key, String label) {
    final isSelected = _genderFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _genderFilter = key),
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
}
