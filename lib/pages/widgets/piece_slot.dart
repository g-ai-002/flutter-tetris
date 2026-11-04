import 'package:flutter/material.dart';

import '../../game/tetromino.dart';
import '../../theme/block_palette.dart';
import 'piece_preview.dart';

/// 暂存与下一个区块的统一槽位：小标题 + 方块预览。
class PieceSlot extends StatelessWidget {
  const PieceSlot({
    super.key,
    required this.label,
    required this.type,
    required this.palette,
    this.size = 44,
    this.onTap,
    this.hint,
    this.showLabel = true,
  });

  final String label;
  final TetrominoType? type;
  final BlockPalette palette;
  final double size;
  final VoidCallback? onTap;
  final String? hint;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typeNow = type;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
        ],
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outline.withValues(alpha: 0.55)),
          ),
          alignment: Alignment.center,
          child: PiecePreview(
            type: typeNow,
            color: typeNow == null ? colors.outline : palette.colorOf(typeNow),
            size: size * 0.82,
            faded: onTap == null && type != null,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: content,
    );
  }
}
