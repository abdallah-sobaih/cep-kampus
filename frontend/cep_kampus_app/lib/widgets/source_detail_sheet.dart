import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/ui_constants.dart';
import '../models/source_document.dart';

/// A modal bottom sheet displaying the full retrieved document snippet
/// that the LLM used to generate a given answer.
class SourceDetailSheet extends StatelessWidget {
  const SourceDetailSheet({super.key, required this.source});
  final SourceDocument source;

  static void show(BuildContext context, SourceDocument source) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SourceDetailSheet(source: source),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            _SheetHeader(source: source),
            const Divider(color: AppColors.divider, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                child: _SnippetBody(source: source),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.source});
  final SourceDocument source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sayfa ${source.page}',
                  style: AppTextStyles.timestamp
                      .copyWith(color: AppColors.accent),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                color: AppColors.textSecondary, size: 20),
            tooltip: 'Metni Kopyala',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: source.snippet));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Kaynak metni kopyalandı.'),
                  backgroundColor: AppColors.surfaceAlt,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SnippetBody extends StatelessWidget {
  const _SnippetBody({required this.source});
  final SourceDocument source;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlgili Kaynak Metni',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: SelectableText(
            source.snippet.isNotEmpty
                ? source.snippet
                : 'Önizleme metni mevcut değil.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bu metin, yanıtı oluşturmak için kullanılan orijinal yönetmelik bölümüdür.',
          style: AppTextStyles.timestamp.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}