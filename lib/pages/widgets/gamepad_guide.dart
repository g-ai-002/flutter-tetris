import 'package:flutter/material.dart';

import '../../input/gamepad_input.dart';

/// 手柄操作速查：条目与按键全部来自 [gamepadButtonActions]。
class GamepadGuide extends StatelessWidget {
  const GamepadGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final action in gamepadGuideOrder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
            ),
            child: Text(
              '${action.label} ${gamepadLabelsFor(action) ?? '—'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
