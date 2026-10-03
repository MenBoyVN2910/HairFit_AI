// ============================================================================
// File: test/chat_test.dart
// Mục đích: Chứa các kịch bản kiểm thử (Test) cho chat.
// Kết cấu:
//  - Sử dụng flutter_test, bao gồm các nhóm test (group) và các trường hợp test (test/testWidgets) cụ thể.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hairfit_ai/models/chat_model.dart';

void main() {
  group('1:1 Chat Feature Unit Tests', () {
    test('ChatMessage toMap and fromMap serialization work accurately', () {
      final now = DateTime(2026, 10, 1, 14, 30);
      final message = ChatMessage(
        id: 'msg_001',
        senderId: 'user_cust_01',
        senderName: 'Nguyễn Văn A',
        text: 'Xin chào anh thợ, em muốn cắt kiểu Side Part!',
        createdAt: now,
      );

      final map = message.toMap();
      expect(map['id'], 'msg_001');
      expect(map['senderId'], 'user_cust_01');
      expect(map['senderName'], 'Nguyễn Văn A');
      expect(map['text'], 'Xin chào anh thợ, em muốn cắt kiểu Side Part!');
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = ChatMessage.fromMap(map, docId: 'msg_001');
      expect(deserialized.id, 'msg_001');
      expect(deserialized.senderId, 'user_cust_01');
      expect(deserialized.senderName, 'Nguyễn Văn A');
      expect(
        deserialized.text,
        'Xin chào anh thợ, em muốn cắt kiểu Side Part!',
      );
      expect(deserialized.createdAt.year, 2026);
    });

    test(
      'ChatConversation toMap and fromMap serialization work accurately',
      () {
        final now = DateTime(2026, 10, 1, 14, 35);
        final conversation = ChatConversation(
          id: 'cust_01_barber_danang_01',
          customerId: 'cust_01',
          customerName: 'Khách hàng 1',
          barberId: 'barber_danang_01',
          barberName: '30Shine Đà Nẵng',
          participants: ['cust_01', 'barber_danang_01'],
          lastMessage: 'Dạ được bạn nhé, hẹn bạn chiều nay!',
          lastSenderId: 'barber_danang_01',
          updatedAt: now,
        );

        final map = conversation.toMap();
        expect(map['id'], 'cust_01_barber_danang_01');
        expect(map['customerId'], 'cust_01');
        expect(map['barberId'], 'barber_danang_01');
        expect(map['participants'], contains('cust_01'));
        expect(map['participants'], contains('barber_danang_01'));
        expect(map['lastMessage'], 'Dạ được bạn nhé, hẹn bạn chiều nay!');
        expect(map['lastSenderId'], 'barber_danang_01');

        final deserialized = ChatConversation.fromMap(
          map,
          docId: 'cust_01_barber_danang_01',
        );
        expect(deserialized.id, 'cust_01_barber_danang_01');
        expect(deserialized.customerId, 'cust_01');
        expect(deserialized.customerName, 'Khách hàng 1');
        expect(deserialized.barberId, 'barber_danang_01');
        expect(deserialized.barberName, '30Shine Đà Nẵng');
        expect(deserialized.lastMessage, 'Dạ được bạn nhé, hẹn bạn chiều nay!');
      },
    );

    test('ChatConversation.buildChatId generates deterministic unique ID', () {
      final chatId1 = ChatConversation.buildChatId('user_123', 'barber_456');
      final chatId2 = ChatConversation.buildChatId('user_123', 'barber_456');
      expect(chatId1, 'user_123_barber_456');
      expect(chatId1, equals(chatId2));
    });
  });
}
