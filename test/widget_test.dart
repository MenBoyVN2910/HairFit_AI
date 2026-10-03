// ============================================================================
// File: test/widget_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho widget.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/widgets/app_button.dart';
import 'package:hairfit_ai/core/widgets/app_text_field.dart';
import 'package:hairfit_ai/core/widgets/empty_state.dart';
import 'package:hairfit_ai/core/widgets/error_retry.dart';
import 'package:hairfit_ai/core/widgets/loading_shimmer.dart';
import 'package:hairfit_ai/core/widgets/rating_stars.dart';
import 'package:hairfit_ai/core/widgets/status_badge.dart';

void main() {
  group('Core Shared Widgets Test (Task 1.6)', () {
    testWidgets('AppButton renders text and triggers callback when tapped', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Bấm vào đây',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Bấm vào đây'), findsOneWidget);
      await tester.tap(find.text('Bấm vào đây'));
      expect(tapped, isTrue);
    });

    testWidgets(
      'AppButton shows CircularProgressIndicator when isLoading is true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                text: 'Đang tải...',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('AppTextField renders label, hint and accepts input', (
      tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppTextField(
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên của bạn',
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Nhập họ và tên của bạn'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Nguyễn Văn A');
      expect(controller.text, 'Nguyễn Văn A');
    });

    testWidgets('StatusBadge renders appropriate label and colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge.approval(status: 'pending'),
                StatusBadge.approval(status: 'approved'),
                StatusBadge.appointment(status: 'confirmed'),
                StatusBadge.appointment(status: 'cancelled'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Chờ duyệt'), findsOneWidget);
      expect(find.text('Đã duyệt'), findsOneWidget);
      expect(find.text('Đã xác nhận'), findsOneWidget);
      expect(find.text('Đã hủy'), findsOneWidget);
    });

    testWidgets('RatingStars renders score correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: RatingStars(rating: 4.8, reviewCount: 25)),
        ),
      );

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(25)'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('EmptyState renders title, message and triggers action', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Không có dữ liệu',
              message: 'Danh sách hiện đang trống',
              actionText: 'Tạo mới',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Không có dữ liệu'), findsOneWidget);
      expect(find.text('Danh sách hiện đang trống'), findsOneWidget);
      expect(find.text('Tạo mới'), findsOneWidget);

      await tester.tap(find.text('Tạo mới'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorRetry renders error message and triggers retry', (
      tester,
    ) async {
      bool retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetry(
              errorMessage: 'Không thể tải dữ liệu từ máy chủ',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Đã xảy ra sự cố'), findsOneWidget);
      expect(find.text('Không thể tải dữ liệu từ máy chủ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      expect(retryTriggered, isTrue);
    });

    testWidgets('LoadingShimmer renders correctly with custom dimensions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingShimmer(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('LoadingShimmer.card and listTile render properly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LoadingShimmer.card(height: 150),
                LoadingShimmer.listTile(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LoadingShimmer), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
