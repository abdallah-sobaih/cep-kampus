import 'package:flutter/foundation.dart';

@immutable
class SourceDocument {
  const SourceDocument({
    required this.source,
    required this.page,
    required this.snippet,
  });

  final String source;
  final int page;
  final String snippet;

  /// Derives a short human-readable label for the source chip UI element.
  /// e.g. "lisans_egitim_yonetmeligi.pdf" → "Lisans Eğitim Yönetmeliği"
  String get displayName {
    return source
        .replaceAll('.pdf', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w)
        .join(' ');
  }

  /// Full citation label shown on the source chip.
  String get citationLabel => 'Kaynak: $displayName, Sayfa $page';

  factory SourceDocument.fromJson(Map<String, dynamic> json) {
    return SourceDocument(
      source: json['source'] as String? ?? 'Bilinmeyen Kaynak',
      page: json['page'] as int? ?? 0,
      snippet: json['snippet'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'source': source,
        'page': page,
        'snippet': snippet,
      };
}