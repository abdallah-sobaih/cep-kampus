import 'package:flutter/material.dart';

import '../core/constants/ui_constants.dart';
import '../models/source_document.dart';
import 'source_detail_sheet.dart';

/// Data contract passed to [SourceChip] from the message bubble.
class SourceChipData {
  const SourceChipData({required this.label, required this.source});
  final String label;
  final SourceDocument source;
}

/// A tappable citation tag rendered beneath assistant message bubbles.
/// Tapping opens a [SourceDetailSheet] with the full retrieved snippet.
class SourceChip extends StatelessWidget {
  const SourceChip({super.key, required this.data});
  final SourceChipData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SourceDetailSheet.show(context, data.source),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sourceChip,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.sourceChipText.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 12, color: AppColors.sourceChipText),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                data.label,
                style: AppTextStyles.sourceChipLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new_rounded,
                size: 10, color: AppColors.sourceChipText),
          ],
        ),
      ),
    );
  }
}