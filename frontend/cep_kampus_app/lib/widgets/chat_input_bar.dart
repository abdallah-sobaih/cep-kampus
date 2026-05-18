import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/ui_constants.dart';
import '../providers/chat_provider.dart';
import 'voice_input_button.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({super.key});

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
    _focusNode.requestFocus();
  }

  /// Populates the text field with the recognised transcript and
  /// returns focus so the user can review before sending.
  void _onSpeechResult(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isLoading =
        chatState.messages.isNotEmpty && chatState.messages.last.isLoading;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          VoiceInputButton(
            onResult: _onSpeechResult,
            onListeningChanged: (listening) {
              setState(() => _isListening = listening);
              // Dismiss the keyboard while the microphone is active
              // to prevent visual clutter and input conflicts.
              if (listening) _focusNode.unfocus();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? AppColors.accent.withOpacity(0.5)
                      : AppColors.divider,
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !isLoading && !_isListening,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.messageText,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? 'Dinleniyor...'
                      : 'Sorunuzu yazın veya sesli sorun...',
                  hintStyle: AppTextStyles.messageText
                      .copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(
            isLoading: isLoading,
            hasText: _hasText,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isLoading,
    required this.hasText,
    required this.onSend,
  });

  final bool isLoading;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: hasText && !isLoading
            ? AppColors.accent
            : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasText && !isLoading ? onSend : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  )
                : Icon(
                    Icons.arrow_upward_rounded,
                    color: hasText ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}