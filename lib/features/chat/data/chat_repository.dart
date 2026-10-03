// ============================================================================
// File: lib/features/chat/data/chat_repository.dart
// Mục đích: Quản lý dữ liệu (Repository) cho tính năng chat.
// Kết cấu:
//  - Tương tác với cơ sở dữ liệu (Firestore) hoặc API, cung cấp CRUD operations.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/chat_model.dart';

/// Repository quản lý dữ liệu tin nhắn và phòng chat 1:1 qua Cloud Firestore
class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gửi tin nhắn mới vào phòng chat 1:1 và cập nhật bản ghi tóm tắt phòng chat
  Future<void> sendMessage({
    required String chatId,
    required String customerId,
    required String customerName,
    required String barberId,
    required String barberName,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final batch = _firestore.batch();

    // 1. Tạo bản ghi tin nhắn con trong subcollection messages
    final messageDocRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageDocRef, {
      'id': messageDocRef.id,
      'senderId': senderId,
      'senderName': senderName,
      'text': cleanText,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Cập nhật hoặc khởi tạo thông tin phòng chat
    final chatDocRef = _firestore.collection('chats').doc(chatId);
    batch.set(chatDocRef, {
      'id': chatId,
      'customerId': customerId,
      'customerName': customerName,
      'barberId': barberId,
      'barberName': barberName,
      'participants': [customerId, barberId],
      'lastMessage': cleanText,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Lắng nghe luồng tin nhắn thời gian thực (Realtime stream) của một cuộc hội thoại
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ChatMessage.fromMap(doc.data(), docId: doc.id);
          }).toList();
        });
  }

  /// Lắng nghe danh sách tất cả các cuộc hội thoại của một người dùng (Khách hoặc Thợ)
  Stream<List<ChatConversation>> getUserConversationsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return ChatConversation.fromMap(doc.data(), docId: doc.id);
          }).toList();
          // Sắp xếp thời gian cập nhật mới nhất lên đầu
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }
}
