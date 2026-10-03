// ============================================================================
// File: lib/features/barber_profile/presentation/widgets/working_hours_editor.dart
// Mục đích: Thành phần giao diện (Widget) con thuộc tính năng barber_profile.
// Kết cấu:
//  - Widget nhận dữ liệu và hiển thị UI, đóng gói giao diện cho gọn gàng.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../models/barber_profile_model.dart';

class WorkingHoursEditor extends StatefulWidget {
  final Map<String, DayWorkingHours> initialHours;
  final ValueChanged<Map<String, DayWorkingHours>> onChanged;

  const WorkingHoursEditor({
    super.key,
    required this.initialHours,
    required this.onChanged,
  });

  @override
  State<WorkingHoursEditor> createState() => _WorkingHoursEditorState();
}

class _WorkingHoursEditorState extends State<WorkingHoursEditor> {
  late Map<String, DayWorkingHours> _hours;

  final Map<String, String> _dayLabels = {
    'mon': 'Thứ 2',
    'tue': 'Thứ 3',
    'wed': 'Thứ 4',
    'thu': 'Thứ 5',
    'fri': 'Thứ 6',
    'sat': 'Thứ 7',
    'sun': 'Chủ Nhật',
  };

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.initialHours);
    if (_hours.isEmpty) {
      for (final day in _dayLabels.keys) {
        _hours[day] = const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:00',
        );
      }
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpenTime,
  ) async {
    final currentStr = isOpenTime ? _hours[day]!.open : _hours[day]!.close;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isOpenTime ? 'Chọn giờ mở cửa' : 'Chọn giờ đóng cửa',
    );

    if (picked != null) {
      setState(() {
        final timeStr =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        final current = _hours[day]!;
        _hours[day] = DayWorkingHours(
          closed: current.closed,
          open: isOpenTime ? timeStr : current.open,
          close: !isOpenTime ? timeStr : current.close,
        );
      });
      widget.onChanged(_hours);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _dayLabels.entries.map((entry) {
        final day = entry.key;
        final label = entry.value;
        final current = _hours[day]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: !current.closed,
                  onChanged: (val) {
                    setState(() {
                      _hours[day] = DayWorkingHours(
                        closed: !val,
                        open: current.open,
                        close: current.close,
                      );
                    });
                    widget.onChanged(_hours);
                  },
                ),
                if (!current.closed) ...[
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(current.open, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context, day, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(current.close, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Text(
                      'Nghỉ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
