import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ai_consult/data/hairstyle_repository.dart';
import '../../../../core/constants/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final hairstylesAsyncValue = ref.watch(hairstylesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.content_cut, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Kiểu tóc hỗ trợ cắt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Đã chọn: ${_selectedIds.length}',
                  style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Chọn các kiểu tóc mà bạn có thể cắt',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        hairstylesAsyncValue.when(
          data: (hairstyles) {
            if (hairstyles.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Chưa có kiểu tóc nào trong hệ thống.'),
                  ],
                ),
              );
            }
            return Wrap(
              spacing: 8.0,
              runSpacing: 10.0,
              children: hairstyles.map((style) {
                final isSelected = _selectedIds.contains(style.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(style.id);
                      } else {
                        _selectedIds.add(style.id);
                      }
                    });
                    widget.onChanged(_selectedIds);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Icon(Icons.check_circle, size: 18, color: AppColors.accent),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          style.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.accent : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Lỗi tải danh mục: $err', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
