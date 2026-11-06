import 'package:flutter/material.dart';

import '../../game/daily_challenge.dart';
import '../../game/game_mode.dart';
import '../../game/level.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/mode_visuals.dart';
import '../../utils/formatters.dart';
import '../game_page.dart';
import '../level_select_page.dart';
import 'entry_tile.dart';
import 'status_chip.dart';

/// 首页玩法入口：三种经典玩法、每日挑战与关卡模式。
class HomeModeCards extends StatelessWidget {
  const HomeModeCards({
    super.key,
    required this.settings,
    required this.wide,
    required this.contentWidth,
  });

  final SettingsProvider settings;
  final bool wide;
  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _modeCard(context: context, settings: settings, mode: GameMode.endless),
      _modeCard(context: context, settings: settings, mode: GameMode.sprint),
      _modeCard(context: context, settings: settings, mode: GameMode.ultra),
    ];
    if (!wide) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            cards[i],
          ],
          const SizedBox(height: 12),
          _dailyCard(context),
          const SizedBox(height: 12),
          _levelCard(context),
        ],
      );
    }
    final cardWidth = (contentWidth - 24) / 3;
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        ),
        const SizedBox(height: 12),
        _dailyCard(context),
        const SizedBox(height: 12),
        _levelCard(context),
      ],
    );
  }

  Widget _dailyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final challenge = DailyChallenge.today();
    final record = settings.dailyRecord(challenge.key);
    final streak = settings.dailyStreak(challenge.date);
    final refresh = challenge.refreshIn(DateTime.now());
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return EntryTile(
      leading: EntryBadge(icon: Icons.today_rounded, accent: colors.primary),
      title: GameMode.daily.label,
      subtitle:
          '${challenge.label} ${challenge.weekdayLabel} · ${GameMode.daily.tagline}',
      trailing: StatusChip(
        accent: colors.primary,
        active: record.played,
        child: Text(
          record.played ? '今日 ${formatThousands(record.bestScore)} 分' : '未挑战',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GamePage(mode: GameMode.daily, daily: challenge),
        ),
      ),
      footer: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 14,
                color: appGold,
              ),
              const SizedBox(width: 4),
              Text('连续打卡 $streak 天', style: muted),
            ],
          ),
          Text('距刷新 ${formatDuration(refresh.inMilliseconds)}', style: muted),
        ],
      ),
    );
  }

  Widget _levelCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return EntryTile(
      leading: const EntryBadge(icon: Icons.flag_rounded, accent: appJade),
      title: GameMode.level.label,
      subtitle: GameMode.level.tagline,
      trailing: StatusChip(
        accent: appJade,
        child: Text(
          '${settings.completedLevels}/${kLevels.length}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: appJade,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const LevelSelectPage())),
      footer: Row(
        children: [
          const Icon(Icons.star_rounded, size: 14, color: appGold),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '已通关 ${settings.completedLevels} 关 · 累计 ${settings.totalStars} 星',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required BuildContext context,
    required SettingsProvider settings,
    required GameMode mode,
  }) {
    final visual = modeVisualFor(mode, Theme.of(context).colorScheme);
    return EntryTile(
      leading: EntryBadge(icon: visual.icon, accent: visual.accent),
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
      case GameMode.level:
      case GameMode.daily:
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
