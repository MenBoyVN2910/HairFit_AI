import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AIChatTab extends ConsumerStatefulWidget {
  const AIChatTab({super.key});

  @override
  ConsumerState<AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends ConsumerState<AIChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Xin chào! Tôi là Trợ lý AI HairFit. Tôi có thể giúp bạn phân tích dáng mặt, gợi ý kiểu tóc nam thịnh hành hoặc tư vấn chăm sóc tóc phù hợp nhất với bạn.',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  final List<String> _quickPrompts = [
    'Mặt vuông hợp kiểu tóc nào?',
    'Tóc dày cứng nên cắt Undercut hay Fade?',
    'Cách giữ nếp tóc Quiff cả ngày?',
    'Tư vấn kiểu tóc cho mặt trái xoan (Oval)',
  ];

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
    });

    _scrollToBottom();

    // Giả lập phản hồi từ AI thông minh
    Future.delayed(const Duration(milliseconds: 800), () {
      String response = 'Cảm ơn câu hỏi của bạn! Dựa trên phân tích On-Device AI, ';
      final lower = text.toLowerCase();
      if (lower.contains('mặt vuông')) {
        response += 'với khuôn mặt vuông góc cạnh, các kiểu tóc như Undercut vuốt ngược, Side Part cổ điển hoặc Buzz Cut ngắn gọn sẽ giúp làm mềm các đường nét góc hàm và tôn lên vẻ nam tính mạnh mẽ.';
      } else if (lower.contains('tóc dày') || lower.contains('undercut') || lower.contains('fade')) {
        response += 'tóc dày và cứng rất thích hợp với các kỹ thuật Skin Fade kết hợp Texture Crop hoặc Moderm Quiff để kiểm soát độ phồng và tạo form gọn gàng.';
      } else if (lower.contains('giữ nếp') || lower.contains('quiff')) {
        response += 'để giữ nếp tóc Quiff cả ngày, bạn nên sấy ngược chiều tóc khi tóc ẩm, dùng pre-styling (xịt tạo phồng) và hoàn thiện bằng sáp (wax) có độ giữ nếp cao (High Hold, Matte Finish).';
      } else {
        response += 'để có kết quả chính xác tuyệt đối, bạn hãy thử sử dụng tính năng Camera AI quét trực tiếp khuôn mặt của mình nhé!';
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppDimensions.borderRadiusSm,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: AppDimensions.sm),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Tư Vấn Kiểu Tóc', style: AppTextStyles.h4),
                Text('Trực tuyến • On-Device AI', style: TextStyle(fontSize: 11, color: AppColors.accent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mở Camera AI',
            icon: const Icon(Icons.camera_alt_outlined, color: AppColors.accent),
            onPressed: () => context.push('/spike-test'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner nhắc nhở chụp ảnh AI
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            color: AppColors.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Muốn AI quét trực tiếp khuôn mặt bạn? Hãy bấm vào Camera AI.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/spike-test'),
                  child: const Text('Thử ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppDimensions.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(AppDimensions.md),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: msg.isUser ? null : Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      msg.text,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: msg.isUser ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Prompts Chips
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.divider),
                  onPressed: () => _handleSubmitted(prompt),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _handleSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi cho AI tư vấn...',
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: AppDimensions.borderRadiusFull,
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  onPressed: () => _handleSubmitted(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
