/// Các dáng khuôn mặt chuẩn mà hệ thống HairFit AI phân loại
enum FaceShape {
  oval,
  round,
  square,
  heart,
  oblong;

  static FaceShape fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'round':
        return FaceShape.round;
      case 'square':
        return FaceShape.square;
      case 'heart':
        return FaceShape.heart;
      case 'oblong':
      case 'long':
        return FaceShape.oblong;
      case 'oval':
      default:
        return FaceShape.oval;
    }
  }

  String get keyName {
    switch (this) {
      case FaceShape.oval:
        return 'oval';
      case FaceShape.round:
        return 'round';
      case FaceShape.square:
        return 'square';
      case FaceShape.heart:
        return 'heart';
      case FaceShape.oblong:
        return 'oblong';
    }
  }

  String get displayNameVi {
    switch (this) {
      case FaceShape.oval:
        return 'Trái xoan (Oval)';
      case FaceShape.round:
        return 'Mặt tròn (Round)';
      case FaceShape.square:
        return 'Mặt vuông (Square)';
      case FaceShape.heart:
        return 'Mặt trái tim (Heart)';
      case FaceShape.oblong:
        return 'Mặt dài (Oblong)';
    }
  }

  String get descriptionVi {
    switch (this) {
      case FaceShape.oval:
        return 'Tỷ lệ cân đối hoàn hảo, chiều dài khuôn mặt lớn hơn chiều rộng xương gò má, phù hợp hầu hết mọi kiểu tóc.';
      case FaceShape.round:
        return 'Chiều dài và chiều rộng khuôn mặt gần tương đương, xương hàm tròn mềm mại, cần kiểu tóc có độ phồng đỉnh đầu để kéo dài khuôn mặt.';
      case FaceShape.square:
        return 'Xương quai hàm góc cạnh và rộng bằng trán, toát lên vẻ nam tính, hợp các kiểu tóc undercut, vuốt dựng hoặc cắt tỉa mềm mại.';
      case FaceShape.heart:
        return 'Trán rộng và cằm thon nhọn, hợp với các kiểu tóc rẽ ngôi hoặc tỉa layer có độ phủ hai bên thái dương.';
      case FaceShape.oblong:
        return 'Khuôn mặt thon dài, khoảng cách từ trán đến cằm lớn, nên chọn tóc có mái ngang hoặc side part để cân bằng chiều dài.';
    }
  }
}
