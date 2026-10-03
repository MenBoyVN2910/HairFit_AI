// ============================================================================
// File: lib/features/chat/presentation/chat_screen.dart
// Mục đích: Màn hình giao diện (Screen) chính của tính năng chat.
// Kết cấu:
//  - Sử dụng ConsumerWidget/StatefulWidget, kết nối UI với Provider để hiển thị trạng thái và xử lý sự kiện người dùng.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_retry.dart';
import '../../../models/chat_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';

/// Màn hình trò chuyện 1:1 thời gian thực giữa Khách hàng và Thợ
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String customerId;
  final String customerName;
  final String barberId;
  final String barberName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.customerId,
    required this.customerName,
    required this.barberId,
    required this.barberName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return;

    setState(() => _isSending = true);
    _textController.clear();

    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            chatId: widget.chatId,
            customerId: widget.customerId,
            customerName: widget.customerName,
            barberId: widget.barberId,
            barberName: widget.barberName,
            senderId: currentUser.uid,
            senderName: currentUser.displayName.isNotEmpty
                ? currentUser.displayName
                : (currentUser.role == UserRole.barber
                      ? 'Thợ cắt tóc'
                      : 'Khách hàng'),
            text: text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi tin nhắn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: AppTextStyles.h4,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentUser?.role == UserRole.customer
                        ? 'Thợ cắt tóc'
                        : 'Khách hàng',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Khu vực hiển thị danh sách tin nhắn realtime
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (err, _) => Center(
                child: ErrorRetry(
                  errorMessage: 'Không thể tải tin nhắn: $err',
                  onRetry: () =>
                      ref.refresh(chatMessagesStreamProvider(widget.chatId)),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chưa có tin nhắn nào',
                    message:
                        'Hãy gửi lời chào hoặc trao đổi về kiểu tóc mong muốn với ${widget.otherUserName}!',
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      reverse: true, // Tin mới nhất nằm dưới đáy
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUserId;
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Thanh nhập tin nhắn
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width * 0.76).clamp(240.0, 520.0),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppDimensions.radiusMd),
            topRight: const Radius.circular(AppDimensions.radiusMd),
            bottomLeft: Radius.circular(isMe ? AppDimensions.radiusMd : 2),
            bottomRight: Radius.circular(isMe ? 2 : AppDimensions.radiusMd),
          ),
          border: isMe ? null : Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding =
        bottomInset > 0 ? 0.0 : MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.md,
        right: AppDimensions.sm,
        top: AppDimensions.sm,
        bottom: AppDimensions.sm + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: const InputDecoration(
                      hintText: 'Nhập tin nhắn trao đổi...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.xs),
              IconButton(
                onPressed: _isSending ? null : _handleSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
