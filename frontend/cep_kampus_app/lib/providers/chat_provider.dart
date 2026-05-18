import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_exception.dart';
import '../models/chat_session.dart';
import '../repositories/chat_repository.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final chatRepositoryProvider =
    Provider<ChatRepository>((_) => ChatRepository());

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

// ---------------------------------------------------------------------------
// ChatState — immutable snapshot of the entire chat feature
// ---------------------------------------------------------------------------

// Sentinel used to distinguish an explicit null from "no value provided"
// in copyWith, allowing currentSessionId to be set to null intentionally.
const _absent = Object();

@immutable
class ChatState {
  const ChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
    this.isInitialising = true,
  });

  /// All sessions shown in the drawer, ordered by most-recently-updated.
  final List<ChatSession> sessions;

  /// The ID of the session currently open in the chat view.
  /// Null when the app has launched with no history yet.
  final String? currentSessionId;

  /// Messages belonging to [currentSessionId].
  final List<ChatMessage> messages;

  /// True only during the initial DB load on app launch.
  final bool isInitialising;

  ChatSession? get currentSession =>
      sessions.where((s) => s.id == currentSessionId).firstOrNull;

  bool get hasActiveSession => currentSessionId != null;

  ChatState copyWith({
    List<ChatSession>? sessions,
    Object? currentSessionId = _absent,
    List<ChatMessage>? messages,
    bool? isInitialising,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSessionId: identical(currentSessionId, _absent)
          ? this.currentSessionId
          : currentSessionId as String?,
      messages: messages ?? this.messages,
      isInitialising: isInitialising ?? this.isInitialising,
    );
  }
}

// ---------------------------------------------------------------------------
// ChatNotifier
// ---------------------------------------------------------------------------

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  static const _uuid = Uuid();

  ChatRepository get _repo => ref.read(chatRepositoryProvider);
  ApiService get _api => ref.read(apiServiceProvider);

  @override
  ChatState build() {
    // Kick off async initialisation without blocking the synchronous build.
    Future.microtask(_initialise);
    return const ChatState();
  }

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  Future<void> _initialise() async {
    final sessions = await _repo.getAllSessions();
    final mostRecent = sessions.isNotEmpty ? sessions.first : null;

    state = state.copyWith(
      sessions: sessions,
      currentSessionId: mostRecent?.id,
      isInitialising: false,
    );

    // Pre-load the most recent session's messages so the user sees their
    // last conversation immediately on launch, matching ChatGPT behaviour.
    if (mostRecent != null) {
      await _loadMessages(mostRecent.id);
    }
  }

  Future<void> _loadMessages(String sessionId) async {
    final messages = await _repo.getMessagesForSession(sessionId);
    state = state.copyWith(messages: messages);
  }

  // -------------------------------------------------------------------------
  // Session management
  // -------------------------------------------------------------------------

  /// Creates a new session, persists it, and sets it as the active view.
  Future<void> createNewSession() async {
    final session = ChatSession(
      id: _uuid.v4(),
      title: 'Yeni Sohbet',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repo.insertSession(session);
    state = state.copyWith(
      sessions: [session, ...state.sessions],
      currentSessionId: session.id,
      messages: [],
    );
  }

  /// Switches the active session and loads its messages from the database.
  /// Clears the message list immediately to prevent a stale-content flash.
  Future<void> switchSession(String sessionId) async {
    if (sessionId == state.currentSessionId) return;
    state = state.copyWith(
      currentSessionId: sessionId,
      messages: [],
    );
    await _loadMessages(sessionId);
  }

  /// Deletes a session and its messages. If the deleted session is currently
  /// active, the view automatically switches to the next available session.
  Future<void> deleteSession(String sessionId) async {
    await _repo.deleteSession(sessionId);
    final remaining = state.sessions.where((s) => s.id != sessionId).toList();

    if (state.currentSessionId == sessionId) {
      final next = remaining.isNotEmpty ? remaining.first : null;
      state = state.copyWith(
        sessions: remaining,
        currentSessionId: next?.id,
        messages: [],
      );
      if (next != null) await _loadMessages(next.id);
    } else {
      state = state.copyWith(sessions: remaining);
    }
  }

  // -------------------------------------------------------------------------
  // Messaging
  // -------------------------------------------------------------------------

  Future<void> sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Lazily create a session on the very first message if none exists.
    if (!state.hasActiveSession) {
      await createNewSession();
    }

    final sessionId = state.currentSessionId!;
    final isFirstMessage = state.messages.isEmpty;

    // Auto-title: derive the session name from the opening query so the
    // drawer shows meaningful labels instead of "Yeni Sohbet" for every row.
    if (isFirstMessage) {
      final title = _deriveTitle(trimmed);
      await _repo.updateSessionTitle(sessionId, title);
      state = state.copyWith(
        sessions: state.sessions
            .map((s) => s.id == sessionId ? s.copyWith(title: title) : s)
            .toList(),
      );
    }

    // 1 — Append user message with instant UI feedback.
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      sessionId: sessionId,
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );
    await _repo.insertMessage(userMsg);
    state = state.copyWith(messages: [...state.messages, userMsg]);

    // 2 — Append an animated loading placeholder for the assistant turn.
    final loadingId = _uuid.v4();
    final loadingMsg = ChatMessage(
      id: loadingId,
      sessionId: sessionId,
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: MessageStatus.loading,
    );
    state = state.copyWith(messages: [...state.messages, loadingMsg]);

    // 3 — Call the RAG API and atomically replace the placeholder.
    try {
      final result = await _api.ask(trimmed);
      final assistantMsg = loadingMsg.copyWith(
        content: result.answer,
        sources: result.sources,
        status: MessageStatus.delivered,
      );
      await _repo.insertMessage(assistantMsg);
      await _repo.touchSession(sessionId);
      _replaceMessage(loadingId, assistantMsg);
      _bubbleSessionToTop(sessionId);
    } on AppException catch (e) {
      _replaceMessage(
        loadingId,
        loadingMsg.copyWith(content: e.message, status: MessageStatus.error),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  void _replaceMessage(String id, ChatMessage replacement) {
    state = state.copyWith(
      messages:
          state.messages.map((m) => m.id == id ? replacement : m).toList(),
    );
  }

  /// Moves the session that just received a message to position 0 in the
  /// sidebar list, keeping the order consistent with [updated_at DESC].
  void _bubbleSessionToTop(String sessionId) {
    final list = [...state.sessions];
    final idx = list.indexWhere((s) => s.id == sessionId);
    if (idx > 0) {
      final session = list.removeAt(idx);
      list.insert(0, session);
      state = state.copyWith(sessions: list);
    }
  }

  /// Takes the first six words of [query], capped at 42 characters.
  String _deriveTitle(String query) {
    final words = query.trim().split(RegExp(r'\s+'));
    final joined = words.take(6).join(' ');
    return joined.length > 42 ? '${joined.substring(0, 39)}...' : joined;
  }
}
