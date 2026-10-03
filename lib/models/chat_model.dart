// ============================================================================
// File: lib/models/chat_model.dart
// Mục đích: Định nghĩa cấu trúc dữ liệu (chat_model).
// Kết cấu:
//  - Lớp mô hình (Model) bao gồm các thuộc tính và phương thức chuyển đổi (toMap, fromMap, copyWith).
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình tin nhắn trong cuộc trò chuyện 1:1
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return ChatMessage(
      id: docId ?? map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: parsedDate,
    );
  }
}

/// Mô hình tóm tắt một cuộc trò chuyện giữa Khách hàng và Thợ
class ChatConversation {
  final String id;
  final String customerId;
  final String customerName;
  final String barberId;
  final String barberName;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.barberId,
    required this.barberName,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'barberId': barberId,
      'barberName': barberName,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate = DateTime.now();
    final rawDate = map['updatedAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return ChatConversation(
      id: docId ?? map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      updatedAt: parsedDate,
    );
  }

  /// Tiện ích sinh ID phòng chat chuẩn định danh giữa Khách và Thợ
  static String buildChatId(String customerId, String barberId) {
    return '${customerId}_$barberId';
  }
}
