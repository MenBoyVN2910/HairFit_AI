import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/main.dart';

void main() {
  testWidgets('HairFitApp smoke test and splash navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HairFitApp(),
      ),
    );

    // Xác nhận Splash screen render đúng nội dung ban đầu
    expect(find.text('HairFit AI'), findsOneWidget);
    expect(find.text('Tư Vấn Kiểu Tóc & Đặt Lịch Thông Minh'), findsOneWidget);

    // Tua thời gian qua 1500ms để hoàn thành timer của SplashScreen
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Xác nhận sau splash đã chuyển qua Customer Home Screen
    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
