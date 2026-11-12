import 'package:flutter/material.dart';

import '../../theme/block_palette.dart';

/// 设置页的皮肤卡片：七色方块预览、名称与选中态。
class SkinOptionCard extends StatelessWidget {
  const SkinOptionCard({
    super.key,
    required this.skin,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final BlockSkin skin;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = skin.palette(dark: dark);
    return Semantics(
      button: true,
      selected: selected,
      label: '${skin.label}皮肤',
      child: InkWell(
        key: ValueKey('skin-${skin.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 152,
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          decoration: BoxDecoration(
            color: selected ? palette.primaryContainer : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? palette.accent : theme.colorScheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (var i = 0; i < palette.legend.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: palette.legend[i].$2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                    skin.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (selected) Icon(Icons.check_rounded, size: 14, color: palette.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
