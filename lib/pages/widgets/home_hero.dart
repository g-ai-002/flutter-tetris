import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// 首页主视觉：朱印、标题与一行题记，任意宽度都居中排版。
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFB03A2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '方',
            style: TextStyle(
              color: Color(0xFFFFF6EA),
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 34,
            letterSpacing: 7,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OrnamentLine(color: colors.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '堆 叠 · 消 行 · 连 击',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            _OrnamentLine(color: colors.outline),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '方寸之间，一局接一局',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _OrnamentLine extends StatelessWidget {
  const _OrnamentLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 30, height: 1, color: color.withValues(alpha: 0.9));
  }
}
