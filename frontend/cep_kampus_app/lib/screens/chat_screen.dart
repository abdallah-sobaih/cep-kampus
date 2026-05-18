import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/ui_constants.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/history_drawer.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const HistoryDrawer(),
      appBar: _buildAppBar(context, ref, chatState),
      body: Column(
        children: [
          Expanded(
            child: chatState.isInitialising
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : chatState.messages.isEmpty
                    ? const _EmptyState()
                    : _MessageList(messages: chatState.messages),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, ChatState chatState) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleSpacing: 0,
      // Drawer toggle — replaces the old static logo.
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: AppColors.textSecondary, size: 22),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Sohbet Geçmişi',
        ),
      ),
      title: chatState.currentSession != null
          ? Text(
              chatState.currentSession!.title,
              style: AppTextStyles.appBarTitle
                  .copyWith(fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('Cep-Kampüs',
              style: AppTextStyles.appBarTitle),
      actions: [
        // New Chat button in the AppBar for quick access without
        // needing to open the drawer.
        IconButton(
          icon: const Icon(Icons.edit_square,
              color: AppColors.accent, size: 22),
          tooltip: 'Yeni Sohbet',
          onPressed: () =>
              ref.read(chatProvider.notifier).createNewSession(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message list (unchanged from Phase 3, now receives messages from ChatState)
// ---------------------------------------------------------------------------

class _MessageList extends StatefulWidget {
  const _MessageList({required this.messages});
  final List<ChatMessage> messages;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length ||
        (widget.messages.isNotEmpty &&
            widget.messages.last.content !=
                oldWidget.messages.last.content)) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final showDateSeparator = index == 0 ||
            _isDifferentDay(
              widget.messages[index - 1].timestamp,
              message.timestamp,
            );
        return Column(
          children: [
            if (showDateSeparator)
              _DateSeparator(date: message.timestamp),
            MessageBubble(message: message),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(DateTime a, DateTime b) =>
      a.year != b.year || a.month != b.month || a.day != b.day;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final label = isToday
        ? 'Bugün'
        : '${date.day}.${date.month}.${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: AppTextStyles.timestamp),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — shown when the active session has no messages yet.
// ---------------------------------------------------------------------------

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  static const _suggestions = [
    'Mazeret sınavına kimler girebilir?',
    'Çift anadal programına nasıl başvurabilirim?',
    'Ders kaydı hangi tarihlerde yapılır?',
    'Akademik takvimi öğrenebilir miyim?',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nasıl yardımcı olabilirim?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Yönetmelik ve ders programları hakkındaki\nsorularınızı yanıtlayabilirim.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...(_suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () =>
                      ref.read(chatProvider.notifier).sendMessage(s),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(s,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}