import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/ui_constants.dart';
import '../models/chat_session.dart';
import '../providers/chat_provider.dart';

class HistoryDrawer extends ConsumerWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              onNewChat: () {
                ref.read(chatProvider.notifier).createNewSession();
                Navigator.pop(context);
              },
            ),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: state.isInitialising
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.accent, strokeWidth: 2))
                  : state.sessions.isEmpty
                      ? const _EmptyHistory()
                      : _SessionList(
                          sessions: state.sessions,
                          currentId: state.currentSessionId,
                        ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onNewChat});
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Cep-Kampüs', style: AppTextStyles.appBarTitle),
          const Spacer(),
          Tooltip(
            message: 'Yeni Sohbet',
            child: InkWell(
              onTap: onNewChat,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit_square,
                    color: AppColors.accent, size: 21),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              color: AppColors.textSecondary, size: 36),
          SizedBox(height: 12),
          Text(
            'Henüz sohbet geçmişi yok.',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'İlk sorunuzu sorun.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session list — grouped by recency (Bugün / Dün / Son 7 Gün / Daha Eski)
// ---------------------------------------------------------------------------

class _SessionList extends ConsumerWidget {
  const _SessionList({required this.sessions, required this.currentId});

  final List<ChatSession> sessions;
  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = _groupByRecency(sessions);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      children: [
        for (final entry in groups.entries) ...[
          _GroupLabel(label: entry.key),
          for (final session in entry.value)
            _SessionTile(
              session: session,
              isActive: session.id == currentId,
              onTap: () {
                ref.read(chatProvider.notifier).switchSession(session.id);
                Navigator.pop(context);
              },
              onDelete: () =>
                  _confirmDelete(context, ref, session),
            ),
        ],
      ],
    );
  }

  /// Groups sessions into labelled buckets based on [updatedAt].
  /// Empty buckets are omitted so no orphan section headers appear.
  Map<String, List<ChatSession>> _groupByRecency(
      List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<ChatSession>>{
      'Bugün': [],
      'Dün': [],
      'Son 7 Gün': [],
      'Daha Eski': [],
    };

    for (final s in sessions) {
      final d = DateTime(
          s.updatedAt.year, s.updatedAt.month, s.updatedAt.day);
      if (!d.isBefore(today)) {
        groups['Bugün']!.add(s);
      } else if (!d.isBefore(yesterday)) {
        groups['Dün']!.add(s);
      } else if (d.isAfter(sevenDaysAgo)) {
        groups['Son 7 Gün']!.add(s);
      } else {
        groups['Daha Eski']!.add(s);
      }
    }

    groups.removeWhere((_, list) => list.isEmpty);
    return groups;
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ChatSession session) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sohbeti Sil',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '"${session.title}" adlı sohbet kalıcı olarak silinecek.',
          style:
              const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(chatProvider.notifier)
                  .deleteSession(session.id);
            },
            child: const Text('Sil',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 5),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isActive ? AppColors.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 15,
                  color: isActive
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    session.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // Delete icon visible only on the active tile to keep
                // the list visually clean — swipe-to-delete is not used
                // because the drawer scroll and swipe gestures conflict.
                if (isActive) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: AppColors.textSecondary, size: 17),
          ),
          const SizedBox(width: 10),
          const Text(
            'Öğrenci',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}