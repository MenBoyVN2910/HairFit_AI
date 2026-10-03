// ============================================================================
// File: lib/core/services/seed_data_service.dart
// Mục đích: Cung cấp dịch vụ hạ tầng (seed_data).
// Kết cấu:
//  - Lớp Service xử lý giao tiếp với các hệ thống bên ngoài hoặc phần cứng (Firebase, Location, API).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/barber_profile_model.dart';
import '../../models/hairstyle_model.dart';
import '../../models/service_model.dart';

/// Dịch vụ khởi tạo dữ liệu mẫu (Seed Data) cho 10 kiểu tóc và 5 thợ cắt tóc
class SeedDataService {
  final FirebaseFirestore _firestore;

  SeedDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 10 kiểu tóc chuẩn trong catalog của hệ thống
  static final List<HairstyleModel> sampleHairstyles = [
    const HairstyleModel(
      id: 'undercut',
      name: 'Undercut Cổ Điển',
      description: 'Cắt ngắn gọn gàng hai bên và sau gáy, phần mái để dài vuốt ngược, giúp khuôn mặt trông thon gọn và góc cạnh hơn.',
      imageUrl: 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['round', 'square', 'oval'],
      tags: ['nam', 'gọn gàng', 'hiện đại', 'công sở'],
      active: true,
    ),
    const HairstyleModel(
      id: 'side_part',
      name: 'Side Part 7/3 Lịch Lãm',
      description: 'Kiểu tóc rẽ ngôi 7/3 hoặc 8/2 kinh điển, tôn lên đường nét tri thức, hài hoà cho người mặt dài hoặc trái xoan.',
      imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'oblong', 'heart'],
      tags: ['nam', 'lịch lãm', 'cổ điển', 'công sở'],
      active: true,
    ),
    const HairstyleModel(
      id: 'pompadour',
      name: 'Pompadour Phồng',
      description: 'Phần tóc mái được sấy phồng và vuốt ngược ra sau tạo độ bồng bềnh, tăng thêm chiều cao biểu kiến cho người mặt tròn.',
      imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['round', 'oval', 'square'],
      tags: ['nam', 'quý ông', 'bồng bềnh', 'tiệc'],
      active: true,
    ),
    const HairstyleModel(
      id: 'layer_male',
      name: 'Tóc Layer Nam Hàn Quốc',
      description: 'Các lọn tóc được cắt tỉa so le tạo tầng lớp tự nhiên, che khuyết điểm trán cao và làm mềm các góc cạnh khuôn mặt.',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'oblong', 'heart'],
      tags: ['nam', 'trẻ trung', 'hàn quốc', 'tự nhiên'],
      active: true,
    ),
    const HairstyleModel(
      id: 'two_block',
      name: 'Two Block Học Đường',
      description: 'Đặc trưng với 2 khối rõ rệt: phần dưới cắt sát, phần trên để layer tự nhiên, phù hợp mọi độ tuổi học sinh và sinh viên.',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'heart', 'round'],
      tags: ['nam', 'học sinh', 'sinh viên', 'dễ chăm'],
      active: true,
    ),
    const HairstyleModel(
      id: 'french_crop',
      name: 'French Crop Cá Tính',
      description: 'Mái bằng ngắn ngang trán kết hợp fade sát hai bên, cực kỳ thoáng mát và tôn lên xương hàm góc cạnh.',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['square', 'oval', 'oblong'],
      tags: ['nam', 'cá tính', 'ngắn', 'mát mẻ'],
      active: true,
    ),
    const HairstyleModel(
      id: 'buzz_cut',
      name: 'Buzz Cut Nam Tính',
      description: 'Húi cua quân đội siêu ngắn, làm nổi bật đường nét nam tính, không tốn công tạo kiểu hay sấy tóc mỗi ngày.',
      imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'square'],
      tags: ['nam', 'thể thao', 'quân đội', 'siêu ngắn'],
      active: true,
    ),
    const HairstyleModel(
      id: 'mullet_modern',
      name: 'Mullet Hiện Đại',
      description: 'Ngắn phía trước và hai bên, dài dần về phía gáy, mang phong cách đường phố phá cách và phóng khoáng.',
      imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'heart', 'oblong'],
      tags: ['nam', 'phá cách', 'streetwear', 'nghệ thuật'],
      active: true,
    ),
    const HairstyleModel(
      id: 'quiff',
      name: 'Textured Quiff',
      description: 'Tóc mái vuốt chếch lên trên với các thớ tóc lọn rõ ràng, tạo cảm giác năng động và cực kỳ thu hút.',
      imageUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['round', 'square', 'oval'],
      tags: ['nam', 'năng động', 'hiện đại', 'hẹn hò'],
      active: true,
    ),
    const HairstyleModel(
      id: 'slicked_back',
      name: 'Slicked Back Vuốt Ngược',
      description: 'Toàn bộ tóc vuốt ngược bóng bẩy về sau, tạo thần thái quyền lực và sang trọng của quý ông.',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
      imageUrls: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop',
      ],
      faceShapes: ['oval', 'square', 'oblong'],
      tags: ['nam', 'sang trọng', 'quý ông', 'sự kiện'],
      active: true,
    ),
  ];

  /// 5 thợ cắt tóc mẫu tại Đà Nẵng (với toạ độ thật, dịch vụ bội số 30 phút, giờ làm việc chuẩn)
  static final List<BarberProfileModel> sampleBarbers = [
    BarberProfileModel(
      uid: 'barber_danang_01',
      displayName: 'HairFit Studio Đà Nẵng',
      avatarUrl: 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=500&auto=format&fit=crop',
      bio: 'Tiệm cắt tóc chuẩn phong cách Barber Châu Âu, hơn 8 năm kinh nghiệm tạo kiểu cho các quý ông.',
      address: '123 Nguyễn Văn Linh, Quận Hải Châu, Đà Nẵng',
      location: const GeoLocation(latitude: 16.0544, longitude: 108.2022),
      priceMin: 80000,
      priceMax: 150000,
      ratingAvg: 4.9,
      ratingCount: 128,
      approvalStatus: 'approved',
      hairstyleIds: ['undercut', 'side_part', 'pompadour', 'quiff'],
      services: const [
        ServiceModel(
          id: 'svc_01',
          name: 'Cắt tạo kiểu cao cấp',
          price: 80000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_02',
          name: 'Combo Cắt + Gội massage + Sấy vuốt sáp',
          price: 120000,
          durationMinutes: 60,
        ),
        ServiceModel(
          id: 'svc_03',
          name: 'Uốn tóc tạo phồng Textured',
          price: 150000,
          durationMinutes: 90,
        ),
      ],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '20:00',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '20:00',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '20:00',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '20:00',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '20:00',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '08:30',
          close: '21:00',
        ),
        'sun': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '18:00',
        ),
      },
    ),
    BarberProfileModel(
      uid: 'barber_danang_02',
      displayName: '30Shine Hải Châu',
      avatarUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=500&auto=format&fit=crop',
      bio: 'Chuỗi cắt tóc nam hiện đại, phục vụ nhanh chóng, chuyên nghiệp và ứng dụng công nghệ.',
      address: '45 Lê Duẩn, Quận Hải Châu, Đà Nẵng',
      location: const GeoLocation(latitude: 16.0680, longitude: 108.2160),
      priceMin: 100000,
      priceMax: 180000,
      ratingAvg: 4.8,
      ratingCount: 95,
      approvalStatus: 'approved',
      hairstyleIds: ['side_part', 'two_block', 'layer_male', 'french_crop'],
      services: const [
        ServiceModel(
          id: 'svc_04',
          name: 'Combo Shine 7 bước',
          price: 100000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_05',
          name: 'Nhuộm màu thời trang',
          price: 180000,
          durationMinutes: 60,
        ),
      ],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:30',
        ),
        'sun': const DayWorkingHours(
          closed: false,
          open: '08:00',
          close: '21:00',
        ),
      },
    ),
    BarberProfileModel(
      uid: 'barber_danang_03',
      displayName: 'Tiệm Cắt Tóc Quý Ông Retro',
      avatarUrl: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=500&auto=format&fit=crop',
      bio: 'Không gian cổ điển thập niên 80, chuyên cạo râu khăn nóng và các kiểu tóc Pompadour, Slicked Back.',
      address: '88 Bạch Đằng, Quận Hải Châu, Đà Nẵng',
      location: const GeoLocation(latitude: 16.0645, longitude: 108.2235),
      priceMin: 90000,
      priceMax: 200000,
      ratingAvg: 4.95,
      ratingCount: 84,
      approvalStatus: 'approved',
      hairstyleIds: ['pompadour', 'slicked_back', 'buzz_cut', 'undercut'],
      services: const [
        ServiceModel(
          id: 'svc_06',
          name: 'Cắt tóc cổ điển Classic',
          price: 90000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_07',
          name: 'Cạo mặt khăn nóng tinh dầu',
          price: 60000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_08',
          name: 'Gói chăm sóc Quý Ông Toàn Diện',
          price: 200000,
          durationMinutes: 90,
        ),
      ],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:30',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:30',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:30',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:30',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:30',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'sun': const DayWorkingHours(
          closed: true,
          open: '00:00',
          close: '00:00',
        ),
      },
    ),
    BarberProfileModel(
      uid: 'barber_danang_04',
      displayName: 'Street Barber Club',
      avatarUrl: 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=500&auto=format&fit=crop',
      bio: 'Chuyên Fade nghệ thuật, Mullet và các kiểu tóc đường phố phá cách cho giới trẻ.',
      address: '210 Điện Biên Phủ, Quận Thanh Khê, Đà Nẵng',
      location: const GeoLocation(latitude: 16.0610, longitude: 108.1950),
      priceMin: 70000,
      priceMax: 130000,
      ratingAvg: 4.7,
      ratingCount: 62,
      approvalStatus: 'approved',
      hairstyleIds: ['mullet_modern', 'french_crop', 'buzz_cut', 'two_block'],
      services: const [
        ServiceModel(
          id: 'svc_09',
          name: 'Skin Fade sắc nét',
          price: 70000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_10',
          name: 'Tạo kiểu Mullet nghệ thuật',
          price: 90000,
          durationMinutes: 60,
        ),
        ServiceModel(
          id: 'svc_11',
          name: 'Tẩy tóc & Nhuộm highlight',
          price: 130000,
          durationMinutes: 90,
        ),
      ],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:00',
        ),
        'sun': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '18:00',
        ),
      },
    ),
    BarberProfileModel(
      uid: 'barber_danang_05',
      displayName: 'Korean Hair Studio',
      avatarUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=500&auto=format&fit=crop',
      bio: 'Tạo mẫu tóc nam phong cách Hàn Quốc: Layer bay, Two Block, Uốn phồng chân tóc nhẹ nhàng.',
      address: '15 Võ Văn Kiệt, Quận Sơn Trà, Đà Nẵng',
      location: const GeoLocation(latitude: 16.0602, longitude: 108.2390),
      priceMin: 85000,
      priceMax: 160000,
      ratingAvg: 4.85,
      ratingCount: 110,
      approvalStatus: 'approved',
      hairstyleIds: ['layer_male', 'two_block', 'side_part', 'quiff'],
      services: const [
        ServiceModel(
          id: 'svc_12',
          name: 'Cắt Layer chuẩn Hàn',
          price: 85000,
          durationMinutes: 30,
        ),
        ServiceModel(
          id: 'svc_13',
          name: 'Uốn phồng chân tóc tự nhiên',
          price: 160000,
          durationMinutes: 60,
        ),
      ],
      workingHours: {
        'mon': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:30',
        ),
        'tue': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:30',
        ),
        'wed': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:30',
        ),
        'thu': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:30',
        ),
        'fri': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '20:30',
        ),
        'sat': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '21:00',
        ),
        'sun': const DayWorkingHours(
          closed: false,
          open: '09:00',
          close: '19:00',
        ),
      },
    ),
  ];

  /// Nạp toàn bộ dữ liệu 10 kiểu tóc vào Firestore
  Future<void> seedHairstyles({bool overwrite = false}) async {
    final collection = _firestore.collection('hairstyleCatalog');

    for (final hairstyle in sampleHairstyles) {
      final docRef = collection.doc(hairstyle.id);
      if (!overwrite) {
        final existing = await docRef.get();
        if (existing.exists) {
          debugPrint('⏭️ Bỏ qua kiểu tóc đã tồn tại: ${hairstyle.name}');
          continue;
        }
      }
      await docRef.set(hairstyle.toMap());
      debugPrint('✅ Đã nạp kiểu tóc: ${hairstyle.name}');
    }
  }

  /// Nạp toàn bộ dữ liệu 5 thợ cắt tóc vào Firestore
  Future<void> seedBarbers({bool overwrite = false}) async {
    final collection = _firestore.collection('barberProfiles');

    for (final barber in sampleBarbers) {
      final docRef = collection.doc(barber.uid);
      if (!overwrite) {
        final existing = await docRef.get();
        if (existing.exists) {
          debugPrint('⏭️ Bỏ qua thợ đã tồn tại: ${barber.displayName}');
          continue;
        }
      }
      await docRef.set(barber.toMap());
      debugPrint('✅ Đã nạp hồ sơ thợ: ${barber.displayName}');
    }
  }

  /// Nạp tất cả dữ liệu seed cùng lúc
  Future<void> seedAll({bool overwrite = false}) async {
    debugPrint('🚀 Bắt đầu quá trình nạp dữ liệu Seed Data...');
    await seedHairstyles(overwrite: overwrite);
    await seedBarbers(overwrite: overwrite);
    debugPrint('🎉 Đã hoàn tất nạp toàn bộ Seed Data thành công!');
  }

  /// Xoá toàn bộ 5 thợ mẫu Seed Data khỏi Firestore
  Future<void> clearSampleBarbers() async {
    final collection = _firestore.collection('barberProfiles');
    for (final barber in sampleBarbers) {
      try {
        await collection.doc(barber.uid).delete();
        debugPrint('🗑️ Đã xoá thợ mẫu: ${barber.displayName}');
      } catch (e) {
        debugPrint('⚠️ Không thể xoá ${barber.uid}: $e');
      }
    }
  }
}
