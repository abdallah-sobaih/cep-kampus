import 'package:flutter/material.dart';

import '../core/constants/ui_constants.dart';
import '../models/chat_session.dart';
import 'source_chip.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: message.isUser ? _UserBubble(message) : _AssistantBubble(message),
    );
  }
}

// ---------------------------------------------------------------------------
// User bubble — right-aligned, accent colour.
// ---------------------------------------------------------------------------

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.message);
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 48),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.userBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(message.content, style: AppTextStyles.messageText),
              ),
              const SizedBox(height: 4),
              Text(_formatTime(message.timestamp),
                  style: AppTextStyles.timestamp),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Assistant bubble — left-aligned with avatar, loading state, source chips.
// ---------------------------------------------------------------------------

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble(this.message);
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(hasError: message.hasError),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.hasError
                      ? AppColors.errorColor.withOpacity(0.12)
                      : AppColors.aiBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(
                    color: message.hasError
                        ? AppColors.errorColor.withOpacity(0.3)
                        : AppColors.divider,
                    width: 1,
                  ),
                ),
                child: message.isLoading
                    ? const _TypingIndicator()
                    : _BubbleContent(message: message),
              ),
              if (message.hasSources) ...[
                const SizedBox(height: 8),
                _SourceRow(sources: message.sources
                    .map((s) => SourceChipData(
                          label: s.citationLabel,
                          source: s,
                        ))
                    .toList()),
              ],
              const SizedBox(height: 4),
              if (!message.isLoading)
                Text(_formatTime(message.timestamp),
                    style: AppTextStyles.timestamp),
            ],
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.hasError});
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.errorColor.withOpacity(0.15)
            : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        hasError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
        color: hasError ? AppColors.errorColor : AppColors.accent,
        size: 16,
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      message.content,
      style: message.hasError
          ? AppTextStyles.messageText.copyWith(color: AppColors.errorColor)
          : AppTextStyles.messageText,
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.sources});
  final List<SourceChipData> sources;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: sources.map((s) => SourceChip(data: s)).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Typing / loading indicator — three animated dots.
// ---------------------------------------------------------------------------

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      final animation = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
      _controllers.add(controller);
      _animations.add(animation);
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';