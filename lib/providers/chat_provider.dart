// ============================================================================
// File: lib/providers/chat_provider.dart
// Mục đích: Quản lý trạng thái (State Management) cho chat.
// Kết cấu:
//  - Sử dụng Riverpod (Notifier/StateNotifier/Provider) để cung cấp trạng thái và xử lý logic nghiệp vụ.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/chat/data/chat_repository.dart';
import '../models/chat_model.dart';

/// Provider cung cấp ChatRepository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

/// StreamProvider lắng nghe luồng tin nhắn realtime theo chatId
final chatMessagesStreamProvider = StreamProvider.family
    .autoDispose<List<ChatMessage>, String>((ref, chatId) {
      final repository = ref.watch(chatRepositoryProvider);
      return repository.getMessagesStream(chatId);
    });

/// StreamProvider lắng nghe danh sách cuộc trò chuyện của một User
final userConversationsStreamProvider = StreamProvider.family
    .autoDispose<List<ChatConversation>, String>((ref, userId) {
      final repository = ref.watch(chatRepositoryProvider);
      return repository.getUserConversationsStream(userId);
    });
