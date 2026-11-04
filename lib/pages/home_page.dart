import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_mode.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'game_page.dart';
import 'records_page.dart';
import 'settings_page.dart';
import 'widgets/entry_tile.dart';
import 'widgets/hero_board_preview.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF201B14), Color(0xFF121009)]
                : const [Color(0xFFFCF6E9), Color(0xFFF0E3CC)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
              final contentWidth = math.min(
                constraints.maxWidth - horizontal * 2,
                820.0,
              );
              final wide = contentWidth >= 700;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 38),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TopBar(),
                          const SizedBox(height: 24),
                          _Hero(wide: wide, settings: settings),
                          const SizedBox(height: 30),
                          _ModeCards(
                            settings: settings,
                            wide: wide,
                            contentWidth: contentWidth,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'v${AppConstants.version} · 本地离线 · Flutter + Flame',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final darkMode = theme.brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '方',
            style: TextStyle(
              color: colors.onPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.titleSmall?.copyWith(fontSize: 15),
            ),
            Text(
              AppConstants.appEnglishName,
              style: TextStyle(
                fontSize: 8.5,
                letterSpacing: 2.2,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: darkMode ? '切换浅色' : '切换深色',
          onPressed: () => settings.setDarkMode(!settings.darkMode),
          icon: Icon(
            darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: '本地纪录',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const RecordsPage())),
          icon: const Icon(Icons.emoji_events_outlined, size: 21),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
          icon: const Icon(Icons.settings_outlined, size: 21),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.wide, required this.settings});

  final bool wide;
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final palette = settings.darkMode
        ? BlockPalette.darkPalette
        : BlockPalette.light;
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

class _ModeCards extends StatelessWidget {
  const _ModeCards({
    required this.settings,
    required this.wide,
    required this.contentWidth,
  });

  final SettingsProvider settings;
  final bool wide;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cards = <Widget>[
      _modeCard(
        context: context,
        settings: settings,
        mode: GameMode.endless,
        icon: Icons.all_inclusive_rounded,
        accent: colors.primary,
      ),
      _modeCard(
        context: context,
        settings: settings,
        mode: GameMode.sprint,
        icon: Icons.timer_outlined,
        accent: appJade,
      ),
      _modeCard(
        context: context,
        settings: settings,
        mode: GameMode.ultra,
        icon: Icons.bolt_rounded,
        accent: appGold,
      ),
    ];
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
        ],
      );
    }
    final cardWidth = (contentWidth - 24) / 3;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final card in cards) SizedBox(width: cardWidth, child: card),
      ],
    );
  }

  Widget _modeCard({
    required BuildContext context,
    required SettingsProvider settings,
    required GameMode mode,
    required IconData icon,
    required Color accent,
  }) {
    return EntryTile(
      leading: EntryBadge(icon: icon, accent: accent),
      title: mode.label,
      subtitle: mode.tagline,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => GamePage(mode: mode))),
      footer: _RecordLine(settings: settings, mode: mode),
    );
  }
}

class _RecordLine extends StatelessWidget {
  const _RecordLine({required this.settings, required this.mode});

  final SettingsProvider settings;
  final GameMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final String text;
    switch (mode) {
      case GameMode.sprint:
        final best = settings.bestSprintTimeMs;
        text = best == null ? '尚未完成 40 行' : '最快 ${formatPreciseDuration(best)}';
        break;
      case GameMode.endless:
      case GameMode.ultra:
        final best = settings.bestScore(mode);
        text = best > 0 ? '最高 ${formatThousands(best)} 分' : '还没有纪录';
        break;
    }
    return Row(
      children: [
        Icon(Icons.workspace_premium_outlined, size: 13, color: colors.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
