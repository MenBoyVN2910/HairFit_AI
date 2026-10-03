// ============================================================================
// File: test/app_avatar_test.dart
// Mục đích: Kiểm thử Widget AppAvatar hiển thị ảnh đại diện thợ và người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/core/widgets/app_avatar.dart';

void main() {
  group('AppAvatar Widget Tests', () {
    testWidgets('renders first letter of name when imageUrl is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: '',
              name: 'Thợ 1',
              width: 72,
              height: 72,
            ),
          ),
        ),
      );

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('renders fallback icon when both imageUrl and name are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: '',
              name: '',
              fallbackIcon: Icons.storefront_rounded,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    });

    testWidgets('renders fallbackUrl when primary imageUrl is empty', (
      tester,
    ) async {
      // 1x1 transparent PNG base64
      const transparentPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: '',
              fallbackUrl: transparentPngBase64,
              name: 'Thợ 2',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders base64 data URI image correctly without exception', (
      tester,
    ) async {
      const sampleBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar(
              imageUrl: sampleBase64,
              name: 'Thợ 1',
              width: 72,
              height: 72,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('AppAvatar.circle factory sets circular shape properly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppAvatar.circle(
              radius: 28,
              name: 'Minh Nhật',
            ),
          ),
        ),
      );

      expect(find.text('M'), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.shape, BoxShape.circle);
    });

    test('getAvatarImageProvider returns MemoryImage for data URI', () {
      const sampleBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
      final provider = getAvatarImageProvider(sampleBase64);
      expect(provider, isA<MemoryImage>());
    });

    test('getAvatarImageProvider returns null for empty or invalid url', () {
      expect(getAvatarImageProvider(''), isNull);
      expect(getAvatarImageProvider(null), isNull);
      expect(getAvatarImageProvider('   '), isNull);
    });
  });
}
