import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/service_model.dart';

class ServiceEditor extends StatefulWidget {
  final List<ServiceModel> initialServices;
  final ValueChanged<List<ServiceModel>> onChanged;

  const ServiceEditor({
    super.key,
    required this.initialServices,
    required this.onChanged,
  });

  @override
  State<ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends State<ServiceEditor> {
  late List<ServiceModel> _services;

  @override
  void initState() {
    super.initState();
    _services = List.from(widget.initialServices);
  }

  void _showServiceDialog([ServiceModel? serviceToEdit, int? index]) {
    final isEditing = serviceToEdit != null && index != null;
    final nameCtrl = TextEditingController(text: serviceToEdit?.name ?? '');
    final priceCtrl = TextEditingController(text: serviceToEdit?.price.toString() ?? '');
    int duration = serviceToEdit?.durationMinutes ?? 30;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Sửa dịch vụ' : 'Thêm dịch vụ mới'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên dịch vụ'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Giá (VNĐ)'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Thời lượng: '),
                      DropdownButton<int>(
                        value: duration,
                        items: [30, 60, 90, 120, 150, 180].map((e) {
                          return DropdownMenuItem(value: e, child: Text('$e phút'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => duration = val);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập đúng tên và giá')),
                      );
                      return;
                    }
                    
                    final newService = ServiceModel(
                      id: isEditing ? serviceToEdit.id : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      price: price,
                      durationMinutes: duration,
                      active: serviceToEdit?.active ?? true,
                    );

                    setState(() {
                      if (isEditing) {
                        _services[index] = newService;
                      } else {
                        _services.add(newService);
                      }
                    });
                    widget.onChanged(_services);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Danh sách dịch vụ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showServiceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm mới'),
            ),
          ],
        ),
        if (_services.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Chưa có dịch vụ nào.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              return Card(
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text('${currencyFormatter.format(service.price)} • ${service.durationMinutes} phút'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: service.active,
                        onChanged: (val) {
                          setState(() {
                            _services[index] = service.copyWith(active: val);
                          });
                          widget.onChanged(_services);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showServiceDialog(service, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _services.removeAt(index);
                          });
                          widget.onChanged(_services);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
