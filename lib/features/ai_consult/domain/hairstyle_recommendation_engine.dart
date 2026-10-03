// ============================================================================
// File: lib/features/ai_consult/domain/hairstyle_recommendation_engine.dart
// Mục đích: Định nghĩa logic nghiệp vụ cốt lõi (Domain/Entity) cho tính năng ai_consult.
// Kết cấu:
//  - Các lớp xử lý logic độc lập, không phụ thuộc vào UI hay Framework (VD: AI Analyzer).
// ============================================================================

import '../../../models/hairstyle_model.dart';
import 'face_shape.dart';

/// Kết quả gợi ý kiểu tóc chi tiết cho người dùng
class RecommendedHairstyle {
  final HairstyleModel style;
  final double matchScore; // 0.0 - 1.0
  final String matchReasonVi;
  final List<String> stylingTips;

  const RecommendedHairstyle({
    required this.style,
    required this.matchScore,
    required this.matchReasonVi,
    this.stylingTips = const [],
  });
}

/// Gói kết quả toàn diện từ Engine đề xuất
class RecommendationResult {
  final FaceShape faceShape;
  final String generalAdviceVi;
  final String avoidAdviceVi;
  final List<RecommendedHairstyle> primaryRecommendations;
  final List<RecommendedHairstyle> alternativeRecommendations;

  const RecommendationResult({
    required this.faceShape,
    required this.generalAdviceVi,
    required this.avoidAdviceVi,
    required this.primaryRecommendations,
    required this.alternativeRecommendations,
  });
}

/// Quy tắc tạo kiểu chuyên gia theo từng dáng mặt (Styling Rules Matrix)
class FaceShapeStylingRule {
  final FaceShape faceShape;
  final String generalAdviceVi;
  final String avoidAdviceVi;
  final List<String> preferredKeywords;
  final List<String> avoidKeywords;
  final Map<String, String> specificStyleReasons;

  const FaceShapeStylingRule({
    required this.faceShape,
    required this.generalAdviceVi,
    required this.avoidAdviceVi,
    required this.preferredKeywords,
    required this.avoidKeywords,
    required this.specificStyleReasons,
  });
}

/// Bộ máy đối soát và đề xuất kiểu tóc theo ma trận quy tắc chuyên gia (Rule-based Engine)
/// Hoạt động 100% on-device, tốc độ tức thì (< 5ms), tính nhất quán cao,
/// cho phép tùy biến linh hoạt từ bộ dữ liệu của hệ thống.
class HairstyleRecommendationEngine {
  const HairstyleRecommendationEngine();

  /// Bảng ma trận quy tắc chuyên nghiệp cho 5 dáng mặt chuẩn
  static final Map<FaceShape, FaceShapeStylingRule> rulesMatrix = {
    FaceShape.square: const FaceShapeStylingRule(
      faceShape: FaceShape.square,
      generalAdviceVi: 'Khuôn mặt vuông có xương quai hàm mạnh mẽ và nam tính. Hãy ưu tiên các kiểu tóc có mái xéo, mái rẽ ngôi bất đối xứng, hoặc sấy phồng đỉnh đầu để làm mềm các đường nét góc cạnh và kéo dài khuôn mặt.',
      avoidAdviceVi: 'Tránh các kiểu tóc cắt mái bằng quá dày, tóc ép thẳng đuỗn hoặc húi cua quá vuông vức vì sẽ làm khuôn mặt trông bị bè ngang.',
      preferredKeywords: [
        'mái xéo',
        'side part',
        'layer',
        'quiff',
        'pompadour',
        'fade',
        'undercut',
      ],
      avoidKeywords: ['mái bằng dày', 'đầu vuông'],
      specificStyleReasons: {
        'undercut': 'Cắt gọn hai bên và vuốt mái ngược tạo độ cao đỉnh đầu, làm thon gọn khung xương vuông vức.',
        'pompadour': 'Độ phồng tối đa ở phần mái giúp kéo dài chiều dọc khuôn mặt, tôn vẻ nam tính quyền lực.',
        'quiff': 'Mái vuốt lệch nhẹ textured tạo hiệu ứng bất đối xứng, làm mềm góc cạnh của xương quai hàm.',
        'french_crop': 'Mái tỉa ngắn mỏng kết hợp fade mịn hai bên giúp gương mặt trông sắc sảo và hiện đại.',
        'side_part': 'Đường rẽ ngôi chéo phá vỡ tính đối xứng vuông vức, mang lại nét lịch lãm và mềm mại.',
        'buzz_cut': 'Tôn trọn vẻ đẹp nam tính, góc cạnh mạnh mẽ của quai hàm chuẩn mực.',
        'slicked_back': 'Vuốt bóng về sau mở rộng vầng trán, tạo phong thái đĩnh đạc và phong độ.',
      },
    ),
    FaceShape.round: const FaceShapeStylingRule(
      faceShape: FaceShape.round,
      generalAdviceVi: 'Khuôn mặt tròn có chiều dài và rộng tương đương, cằm tròn đầy đặn. Bí quyết là tạo thêm chiều cao ở đỉnh đầu (pompadour, quiff, vuốt dựng) và cắt sát gọn gàng hai bên (fade, undercut) để kéo thon khuôn mặt.',
      avoidAdviceVi: 'Tránh tóc mái bằng ngang trán, tóc xòe phồng hai bên má hoặc tóc quá dài uốn xoăn xù tròn vì sẽ làm mặt trông tròn trĩnh hơn.',
      preferredKeywords: [
        'pompadour',
        'quiff',
        'undercut',
        'side part vuốt cao',
        'vuốt dựng',
      ],
      avoidKeywords: ['mái ngố', 'phồng hai bên', 'xoăn xù'],
      specificStyleReasons: {
        'pompadour': 'Phần tóc mái sấy phồng cao tạo ảo giác kéo dài chiều cao gương mặt cực kỳ hiệu quả.',
        'undercut': 'Hai bên cắt sát làm giảm diện tích biểu kiến của đôi má bầu bĩnh, giúp mặt thon gọn.',
        'quiff': 'Tóc vuốt dựng hướng lên trên tạo góc nhìn thanh thoát, hiện đại và trẻ trung.',
        'two_block': 'Phần dưới cắt gọn, lớp trên tạo nếp nhẹ nhàng giúp giảm độ tròn của má.',
      },
    ),
    FaceShape.oval: const FaceShapeStylingRule(
      faceShape: FaceShape.oval,
      generalAdviceVi: 'Khuôn mặt trái xoan là dáng mặt lý tưởng nhất với các tỷ lệ vàng cân đối hoàn hảo. Bạn có thể tự tin trải nghiệm hầu hết mọi kiểu tóc từ cổ điển đến phá cách.',
      avoidAdviceVi: 'Chỉ cần lưu ý không để tóc mái quá dài che lấp toàn bộ khuôn mặt hoặc phủ kín vầng trán đẹp tự nhiên.',
      preferredKeywords: [
        'undercut',
        'side part',
        'layer',
        'pompadour',
        'slicked back',
        'mullet',
        'quiff',
      ],
      avoidKeywords: ['mái che kín mặt'],
      specificStyleReasons: {
        'undercut': 'Tôn vinh đường nét cân đối, tạo phong cách hiện đại và chuẩn mực quý ông.',
        'side_part': 'Rẽ ngôi kinh điển làm nổi bật thần thái tri thức và sự hài hòa tự nhiên.',
        'pompadour': 'Kiểu tóc phồng sang trọng tôn trọn vẹn từng đường nét trên gương mặt trái xoan.',
        'layer_male': 'Tỉa tầng bay bổng tự nhiên, mang đậm phong cách trẻ trung và lãng tử.',
        'two_block': 'Cân đối tuyệt đối, gọn gàng, thanh lịch cho mọi môi trường làm việc hay học tập.',
        'slicked_back': 'Tôn vinh toàn bộ gương mặt sáng rạng rỡ và quyền lực.',
        'mullet_modern': 'Thể hiện cá tính tự do và chất nghệ thuật mà vẫn giữ được sự hài hòa.',
        'quiff': 'Năng động, cuốn hút và tràn đầy năng lượng cho các buổi hẹn hò hay công việc.',
        'french_crop':
            'Gọn gàng, tối giản nhưng vô cùng thời thượng và cá tính.',
        'buzz_cut':
            'Tôn trọn từng đường nét thanh tú và vầng trán cân đối hoàn mỹ.',
      },
    ),
    FaceShape.heart: const FaceShapeStylingRule(
      faceShape: FaceShape.heart,
      generalAdviceVi: 'Mặt trái tim có vầng trán rộng và cằm thon nhọn. Lựa chọn tối ưu là các kiểu tóc có mái rủ nhẹ nhàng (layer, side part rủ, two block) hoặc có độ dài vừa phải để che bớt trán và tạo độ cân bằng cho cằm.',
      avoidAdviceVi: 'Tránh các kiểu vuốt phồng đỉnh đầu quá cao hoặc cắt quá sát phần chân tóc hai bên thái dương vì sẽ làm trán trông càng rộng hơn.',
      preferredKeywords: [
        'layer',
        'side part rủ',
        'two block',
        'tóc dài vừa',
        'mái thưa',
      ],
      avoidKeywords: ['phồng cao', 'cạo sát thái dương'],
      specificStyleReasons: {
        'layer_male': 'Các lớp tóc tỉa so le phủ nhẹ hai bên thái dương giúp thu hẹp bề ngang của vầng trán rộng.',
        'side_part': 'Mái rẽ 7/3 rủ tự nhiên chia nhỏ diện tích trán, tạo sự cân bằng tuyệt vời với chiếc cằm thon.',
        'two_block': 'Phần mái rủ che bớt phần trán trên, tạo vẻ thư sinh và trẻ trung cuốn hút.',
        'mullet_modern': 'Độ dài phía sau gáy cân bằng hoàn hảo với phần cằm nhọn phía trước.',
      },
    ),
    FaceShape.oblong: const FaceShapeStylingRule(
      faceShape: FaceShape.oblong,
      generalAdviceVi: 'Khuôn mặt dài có khoảng cách từ trán đến cằm lớn. Giải pháp tốt nhất là các kiểu tóc có mái ngang, mái rủ, hoặc tạo độ bồng bềnh hai bên (French crop, Layer, Side part rủ) để rút ngắn chiều dài thị giác của mặt.',
      avoidAdviceVi: 'Tuyệt đối tránh vuốt tóc dựng đứng lên trên (như Pompadour cao, Spiky) hoặc cạo sát trắng hai bên (High Fade) vì sẽ làm mặt càng dài hơn.',
      preferredKeywords: [
        'french crop',
        'mái ngang',
        'layer',
        'side part rủ',
        'xoăn nhẹ',
      ],
      avoidKeywords: ['vuốt dựng đứng', 'pompadour cao', 'high fade sát'],
      specificStyleReasons: {
        'french_crop': 'Mái cắt ngang che bớt 1/3 vầng trán, lập tức làm khuôn mặt trông ngắn lại và cân đối hơn.',
        'side_part': 'Mái chia ngôi ngang làm phân tán ánh nhìn theo chiều ngang thay vì chiều dọc.',
        'layer_male': 'Tóc mái rủ có độ phồng hai bên thái dương tạo cảm giác đầy đặn cho khuôn mặt.',
        'mullet_modern': 'Tạo thêm khối và chiều sâu phía sau, cân bằng chiều dài của khuôn mặt.',
        'slicked_back': 'Nếu vuốt thấp ôm sát đầu sẽ không làm tăng thêm chiều cao không mong muốn.',
      },
    ),
  };

  /// Phân tích và đưa ra danh sách đề xuất kiểu tóc phù hợp nhất từ catalog
  RecommendationResult recommend({
    required FaceShape faceShape,
    required List<HairstyleModel> catalog,
    String? gender,
    String? preferredLength,
    String? preferredTexture,
  }) {
    final rule = rulesMatrix[faceShape] ?? rulesMatrix[FaceShape.oval]!;
    final shapeKey = faceShape.keyName;

    // Lọc các kiểu tóc phù hợp trực tiếp với dáng mặt từ catalog
    final List<RecommendedHairstyle> matchedList = [];
    final List<RecommendedHairstyle> otherList = [];

    for (final style in catalog) {
      if (!style.active) continue;

      final isDirectMatch = style.matchesFaceShape(shapeKey);
      double score = isDirectMatch ? 0.85 : 0.40;

      // Tính điểm thưởng dựa trên từ khóa ưu tiên trong tags/name/description
      final combinedText =
          '${style.name} ${style.description} ${style.tags.join(" ")}'
              .toLowerCase();

      for (final kw in rule.preferredKeywords) {
        if (combinedText.contains(kw.toLowerCase())) {
          score += 0.05;
        }
      }

      for (final kw in rule.avoidKeywords) {
        if (combinedText.contains(kw.toLowerCase())) {
          score -= 0.15;
        }
      }

      // Giới hạn điểm số từ 0.1 đến 0.99
      score = score.clamp(0.1, 0.99);

      // Tìm lý do cụ thể theo từng styleId hoặc sinh lý do chuyên gia
      String reason =
          rule.specificStyleReasons[style.id] ??
          'Kiểu tóc ${style.name} hài hòa với dáng ${faceShape.displayNameVi}, giúp tôn lên đường nét khuôn mặt của bạn.';

      final tips = _generateStylingTips(style, faceShape);

      final rec = RecommendedHairstyle(
        style: style,
        matchScore: double.parse(score.toStringAsFixed(2)),
        matchReasonVi: reason,
        stylingTips: tips,
      );

      if (isDirectMatch) {
        matchedList.add(rec);
      } else {
        otherList.add(rec);
      }
    }

    // Sắp xếp theo điểm tương thích giảm dần
    matchedList.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    otherList.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return RecommendationResult(
      faceShape: faceShape,
      generalAdviceVi: rule.generalAdviceVi,
      avoidAdviceVi: rule.avoidAdviceVi,
      primaryRecommendations: matchedList,
      alternativeRecommendations: otherList,
    );
  }

  List<String> _generateStylingTips(HairstyleModel style, FaceShape faceShape) {
    final tips = <String>[];
    if (style.id == 'undercut' || style.id == 'pompadour') {
      tips.add(
        'Sử dụng sáp pomade gốc nước để giữ nếp sấy phồng suốt cả ngày.',
      );
      tips.add('Sấy ngược chân tóc kết hợp lược tròn trước khi bôi sáp.');
    } else if (style.id == 'side_part') {
      tips.add('Xác định đường rẽ ngôi thẳng từ đuôi lông mày lên đỉnh đầu.');
      tips.add('Dùng lược răng thưa chải đều để nếp rẽ ngôi tự nhiên nhất.');
    } else if (style.id == 'layer_male' || style.id == 'two_block') {
      tips.add(
        'Dùng sáp vuốt dạng matte clay không bóng để giữ độ bay tự nhiên.',
      );
      tips.add('Sấy khô tự nhiên bằng tay, không cần chải ép sát vào trán.');
    } else if (style.id == 'french_crop' || style.id == 'buzz_cut') {
      tips.add('Gội đầu và lau khô nhanh chóng, không tốn thời gian tạo kiểu.');
      tips.add('Nên tỉa fade lại chân tóc sau mỗi 2-3 tuần để giữ form chuẩn.');
    } else {
      tips.add('Nên sấy định hình form tóc ngay sau khi gội sạch.');
    }
    return tips;
  }
}
