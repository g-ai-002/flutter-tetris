import 'package:flutter/material.dart';

import '../../providers/settings_provider.dart';
import '../../theme/block_palette.dart';
import '../../utils/constants.dart';
import 'hero_board_preview.dart';

/// 首页主视觉：缩略棋盘与标题，宽屏左右排列、窄屏上下排列。
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.wide, required this.settings});

  final bool wide;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = settings.blockSkin.palette(dark: dark);
    final preview = HeroBoardPreview(palette: palette);
    final text = _HeroText(wide: wide);
    if (!wide) {
      return Column(children: [preview, const SizedBox(height: 20), text]);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        preview,
        const SizedBox(width: 34),
        Flexible(child: text),
      ],
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          AppConstants.appName,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: wide ? 38 : 32,
            letterSpacing: wide ? 7 : 6,
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
            letterSpacing: wide ? 2 : 1,
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
