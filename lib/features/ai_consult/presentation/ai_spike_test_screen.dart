import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/seed_data_service.dart';
import '../../../core/widgets/app_button.dart';
import '../data/face_validation_service.dart';
import '../domain/face_shape_analyzer.dart';
import '../domain/hairstyle_recommendation_engine.dart';

/// Màn hình Phân Tích Gương Mặt & Tư Vấn Kiểu Tóc AI Cao Cấp
class AISpikeTestScreen extends StatefulWidget {
  const AISpikeTestScreen({super.key});

  @override
  State<AISpikeTestScreen> createState() => _AISpikeTestScreenState();
}

class _AISpikeTestScreenState extends State<AISpikeTestScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceValidationService _faceValidator = FaceValidationService();
  final FaceShapeAnalyzer _faceShapeAnalyzer = const FaceShapeAnalyzer();
  final HairstyleRecommendationEngine _recommendationEngine = const HairstyleRecommendationEngine();

  XFile? _selectedImage;

  bool _isAnalyzing = false;
  FaceValidationResult? _validationResult;
  FaceAnthropometricMetrics? _faceMetrics;
  RecommendationResult? _recommendationResult;

  @override
  void dispose() {
    _faceValidator.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (file != null) {
        setState(() {
          _selectedImage = file;
          _validationResult = null;
          _faceMetrics = null;
          _recommendationResult = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải ảnh: $e')),
      );
    }
  }

  Future<void> _runAIAnalysis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _validationResult = null;
      _faceMetrics = null;
      _recommendationResult = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);

      // 1. Kiểm tra chất lượng ảnh chân dung
      final validation = await _faceValidator.validateFace(inputImage);

      FaceAnthropometricMetrics? metrics;
      RecommendationResult? recommendations;

      // 2. Phân tích hình học nhân trắc học & Đề xuất kiểu tóc
      if (validation.isValid && validation.face != null) {
        metrics = _faceShapeAnalyzer.analyze(validation.face!);
        recommendations = _recommendationEngine.recommend(
          faceShape: metrics.faceShape,
          catalog: SeedDataService.sampleHairstyles,
        );
      }

      setState(() {
        _validationResult = validation;
        _faceMetrics = metrics;
        _recommendationResult = recommendations;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi phân tích AI: $e')),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Studio AI Tư Vấn Kiểu Tóc'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: AppDimensions.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSelectionSection(),
            const SizedBox(height: AppDimensions.lg),
            _buildAIAnalysisSection(),
            if (_recommendationResult != null) ...[
              const SizedBox(height: AppDimensions.lg),
              _buildRecommendationSection(),
              const SizedBox(height: AppDimensions.lg),
              _buildInstantBookingAndSalonSection(),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.camera_front_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 8),
                Text('1. Tải Lên Hoặc Chụp Ảnh Chân Dung', style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            const Text(
              'Đảm bảo khuôn mặt nhìn thẳng, đủ ánh sáng và không đeo kính râm để AI phân tích chính xác nhất.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.md),
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: AppDimensions.borderRadiusMd,
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ] else ...[
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: AppDimensions.borderRadiusMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.face_retouching_natural, size: 52, color: AppColors.textSecondary),
                    SizedBox(height: AppDimensions.sm),
                    Text('Chưa có ảnh chân dung nào được chọn', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.md),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Chụp ảnh mới',
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: AppButton.outline(
                    text: 'Chọn từ thư viện',
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                SizedBox(width: 8),
                Text('2. Quét & Phân Tích Cấu Trúc Gương Mặt AI', style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            const Text(
              'Trí tuệ nhân tạo quét tỷ lệ vàng, độ cân đối xương hàm và cấu trúc gương mặt trong giây lát.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.md),
            AppButton(
              text: 'Bắt Đầu Phân Tích Gương Mặt',
              isLoading: _isAnalyzing,
              onPressed: _selectedImage == null ? null : _runAIAnalysis,
            ),
            if (_validationResult != null) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: _validationResult!.isValid ? AppColors.successLight : AppColors.errorLight,
                  borderRadius: AppDimensions.borderRadiusSm,
                  border: Border.all(
                    color: _validationResult!.isValid ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _validationResult!.isValid ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _validationResult!.isValid ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Expanded(
                          child: Text(
                            _validationResult!.isValid ? 'ẢNH ĐẠT CHUẨN ĐỂ PHÂN TÍCH AI' : 'CHẤT LƯỢNG ẢNH CHƯA ĐẠT',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _validationResult!.isValid ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_validationResult!.isValid) ...[
                      const SizedBox(height: AppDimensions.xs),
                      Text('Nguyên nhân: ${_validationResult!.errorMessage}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                      if (_validationResult!.errorHint != null)
                        Text('Gợi ý: ${_validationResult!.errorHint}', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                    ],
                  ],
                ),
              ),
            ],
            if (_faceMetrics != null) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: AppDimensions.borderRadiusSm,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: AppDimensions.xs),
                        Expanded(
                          child: Text(
                            'DÁNG MẶT CỦA BẠN: ${_faceMetrics!.faceShape.displayNameVi.toUpperCase()}',
                            style: AppTextStyles.h4.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(_faceMetrics!.explanationVi, style: AppTextStyles.bodySmall),
                    const Divider(height: AppDimensions.md),
                    const Text('Chỉ số nhân trắc học gương mặt:', style: AppTextStyles.labelMedium),
                    const SizedBox(height: AppDimensions.xs),
                    Wrap(
                      spacing: AppDimensions.sm,
                      runSpacing: AppDimensions.xs,
                      children: [
                        _buildMetricChip('Tỷ lệ dài/rộng', _faceMetrics!.aspectRatio.toStringAsFixed(2)),
                        _buildMetricChip('Độ góc cạnh hàm', '${(_faceMetrics!.jawSquareness * 100).toStringAsFixed(0)}%'),
                        _buildMetricChip('Độ tin cậy AI', '${(_faceMetrics!.confidence * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildRecommendationSection() {
    final result = _recommendationResult!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '3. Kiểu Tóc Phù Hợp Nhất (${result.faceShape.displayNameVi})',
                    style: AppTextStyles.h4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 Lời khuyên chuyên gia: ${result.generalAdviceVi}', style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppDimensions.xs),
                  Text('⚠️ Kiểu nên tránh: ${result.avoidAdviceVi}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            const Text('Danh sách kiểu tóc được gợi ý riêng cho bạn:', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.sm),
            ...result.primaryRecommendations.map((rec) => _buildHairstyleCard(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildHairstyleCard(RecommendedHairstyle rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppDimensions.borderRadiusSm,
            child: Image.network(
              rec.style.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 76,
                height: 76,
                color: AppColors.inputBackground,
                child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(rec.style.name, style: AppTextStyles.h4),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: AppDimensions.borderRadiusSm,
                      ),
                      child: Text(
                        'Độ hợp: ${(rec.matchScore * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.badgeText.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(rec.matchReasonVi, style: AppTextStyles.bodySmall),
                if (rec.stylingTips.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Bí quyết tạo kiểu: ${rec.stylingTips.first}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.accent, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstantBookingAndSalonSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusLg),
      child: Padding(
        padding: AppDimensions.paddingCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event_available_rounded, color: AppColors.accent, size: 22),
                SizedBox(width: 8),
                Text('4. Lịch Trống & Salon Thợ Cắt Tóc Gần Nhất', style: AppTextStyles.h4),
              ],
            ),
            const SizedBox(height: AppDimensions.xs),
            const Text(
              'Hệ thống đã kết nối với các Salon hàng đầu tại Đà Nẵng có lịch trống ngay hôm nay để bạn đặt hẹn:',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.md),
            _buildSalonSlotItem(
              name: 'Master Barber Lê Duẩn',
              address: '245 Lê Duẩn, Hải Châu, Đà Nẵng',
              distance: '1.2 km',
              rating: '4.9 ★ (120 đánh giá)',
              availableSlots: ['10:00 - 10:30', '14:00 - 14:30', '16:30 - 17:00'],
            ),
            const SizedBox(height: AppDimensions.md),
            _buildSalonSlotItem(
              name: '30Shine Premium Nguyễn Văn Linh',
              address: '118 Nguyễn Văn Linh, Thanh Khê, Đà Nẵng',
              distance: '2.5 km',
              rating: '4.8 ★ (350 đánh giá)',
              availableSlots: ['11:00 - 11:30', '15:00 - 15:30', '18:00 - 18:30'],
            ),
            const SizedBox(height: AppDimensions.md),
            const Text('💡 Hướng Dẫn Chăm Sóc Tóc Chuyên Sâu:', style: AppTextStyles.labelMedium),
            const SizedBox(height: AppDimensions.xs),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppDimensions.borderRadiusSm,
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Sử dụng sáp định hình cao cấp (Matte Paste / Clay) để giữ form tối đa.', style: AppTextStyles.bodySmall),
                  Text('• Sử dụng xịt bảo vệ nhiệt trước khi sấy ngược chiều tóc.', style: AppTextStyles.bodySmall),
                  Text('• Cắt tỉa định kỳ sau mỗi 3-4 tuần để duy trì kiểu tóc hoàn hảo.', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonSlotItem({
    required String name,
    required String address,
    required String distance,
    required String rating,
    required List<String> availableSlots,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: AppTextStyles.labelMedium)),
              Text(distance, style: AppTextStyles.badgeText.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 2),
          Text(address, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(rating, style: AppTextStyles.caption.copyWith(color: Colors.amber[800], fontWeight: FontWeight.bold)),
          const SizedBox(height: AppDimensions.sm),
          const Text('Chọn khung giờ trống để đặt lịch ngay:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8.0,
            runSpacing: 6.0,
            children: availableSlots.map((slot) {
              return ActionChip(
                label: Text(slot, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.successLight,
                labelStyle: const TextStyle(color: AppColors.success),
                onPressed: () => _showBookingForm(context, name, slot),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showBookingForm(BuildContext context, String salonName, String initialSlot) {
    final nameController = TextEditingController();
    final dobController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSlot = initialSlot;
    String selectedBarber = 'Master Tuấn Anh (Top Stylist)';
    String selectedDate = 'Hôm nay (29/09/2026)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.lg,
            right: AppDimensions.lg,
            top: AppDimensions.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Xác Nhận Đặt Lịch Cắt Tóc', style: AppTextStyles.h3),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Text('Salon: $salonName', style: AppTextStyles.bodySmall.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
                const Divider(height: AppDimensions.lg),

                // Họ tên
                const Text('Họ và tên khách hàng', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập họ và tên của bạn',
                    prefixIcon: Icon(Icons.person_outline),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Ngày sinh
                const Text('Ngày sinh', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(
                    hintText: 'DD/MM/YYYY (Ví dụ: 15/08/1998)',
                    prefixIcon: Icon(Icons.cake_outlined),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                ),
                const SizedBox(height: AppDimensions.md),

                // Ngày hẹn & Giờ hẹn
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ngày cắt', style: AppTextStyles.labelMedium),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedDate,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Hôm nay (29/09/2026)', child: Text('Hôm nay (29/09/2026)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Ngày mai (30/09/2026)', child: Text('Ngày mai (30/09/2026)', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedDate = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Giờ hẹn', style: AppTextStyles.labelMedium),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSlot,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: ['10:00 - 10:30', '11:00 - 11:30', '14:00 - 14:30', '15:00 - 15:30', '16:30 - 17:00']
                                .map((slot) => DropdownMenuItem(value: slot, child: Text(slot, style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedSlot = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),

                // Chọn thợ cắt tóc
                const Text('Chọn thợ cắt tóc', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedBarber,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Master Tuấn Anh (Top Stylist)', child: Text('Master Tuấn Anh (Top Stylist)', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'Hoàng Long (Senior Barber)', child: Text('Hoàng Long (Senior Barber)', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'Văn Minh (Stylist)', child: Text('Văn Minh (Stylist)', style: TextStyle(fontSize: 13))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedBarber = val);
                  },
                ),
                const SizedBox(height: AppDimensions.md),

                // Ghi chú
                const Text('Yêu cầu / Ghi chú thêm', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Cắt sát 2 bên, uốn phồng nhẹ đỉnh đầu...',
                    filled: true,
                    fillColor: AppColors.inputBackground,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),

                // Nút xác nhận
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMd),
                    ),
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vui lòng nhập họ và tên của bạn!')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                              SizedBox(width: 8),
                              Text('Đặt Lịch Thành Công!'),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Khách hàng: $name', style: AppTextStyles.labelMedium),
                              Text('Salon: $salonName', style: AppTextStyles.bodySmall),
                              Text('Thợ: $selectedBarber', style: AppTextStyles.bodySmall),
                              Text('Thời gian: $selectedSlot, $selectedDate', style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppDimensions.sm),
                              const Text('Mã vé đặt lịch đã được lưu vào hệ thống. Vui lòng đến đúng giờ.', style: AppTextStyles.caption),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Xác Nhận Đặt Lịch Cắt Tóc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
