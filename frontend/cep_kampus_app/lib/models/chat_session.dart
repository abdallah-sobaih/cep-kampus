import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'source_document.dart';

enum MessageRole { user, assistant }

enum MessageStatus { delivered, loading, error }

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sources = const [],
    this.status = MessageStatus.delivered,
  });

  final String id;
  final String sessionId; // Foreign key — links message to its session.
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<SourceDocument> sources;
  final MessageStatus status;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isLoading => status == MessageStatus.loading;
  bool get hasError => status == MessageStatus.error;
  bool get hasSources => sources.isNotEmpty;

  ChatMessage copyWith({
    String? content,
    List<SourceDocument>? sources,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      sources: sources ?? this.sources,
      status: status ?? this.status,
    );
  }

  /// Serialises to a SQLite row. Sources are JSON-encoded as a TEXT column.
  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'role': role.name,
        'content': content,
        'sources': jsonEncode(sources.map((s) => s.toJson()).toList()),
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final sourcesRaw = map['sources'] as String? ?? '[]';
    final sourcesList = (jsonDecode(sourcesRaw) as List<dynamic>)
        .map((s) => SourceDocument.fromJson(s as Map<String, dynamic>))
        .toList();

    return ChatMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      role: MessageRole.values.byName(map['role'] as String),
      content: map['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      sources: sourcesList,
      status: MessageStatus.delivered,
    );
  }
}

@immutable
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}

