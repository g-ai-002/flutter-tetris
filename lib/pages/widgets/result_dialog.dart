import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/daily_challenge.dart';
import '../../game/game_mode.dart';
import '../../game/level.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'star_rating.dart';
import 'stat_value.dart';
import 'status_chip.dart';

/// 终局结算弹窗：成绩、纪录与再来一局。
Future<void> showGameResultDialog(
  BuildContext context, {
  required GameResult result,
  required RecordOutcome outcome,
  required int bestScore,
  required VoidCallback onRestart,
  required VoidCallback onExit,
  LevelDefinition? level,
  DailyChallenge? daily,
  bool hasNext = false,
  VoidCallback? onNext,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ResultDialog(
      result: result,
      outcome: outcome,
      bestScore: bestScore,
      level: level,
      daily: daily,
      hasNext: hasNext,
      onRestart: () {
        Navigator.of(dialogContext).pop();
        onRestart();
      },
      onNext: onNext == null
          ? null
          : () {
              Navigator.of(dialogContext).pop();
              onNext();
            },
      onExit: () {
        Navigator.of(dialogContext).pop();
        onExit();
      },
    ),
  );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.result,
    required this.outcome,
    required this.bestScore,
    required this.onRestart,
    required this.onExit,
    this.level,
    this.daily,
    this.hasNext = false,
    this.onNext,
  });

  final GameResult result;
  final RecordOutcome outcome;
  final int bestScore;
  final LevelDefinition? level;
  final DailyChallenge? daily;
  final bool hasNext;
  final VoidCallback? onNext;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  String get _title {
    if (daily != null) return '每日挑战结束';
    if (result.won) return level == null ? '完成挑战' : '第 ${level!.id} 关完成';
    return '游戏结束';
  }

  String get _bestLabel {
    if (daily != null) return '当日';
    return level == null ? '历史' : '本关';
  }

  Future<void> _share(BuildContext context) async {
    final challenge = daily;
    if (challenge == null) return;
    await Clipboard.setData(
      ClipboardData(
        text: challenge.shareText(
          score: result.score,
          lines: result.lines,
          level: result.level,
        ),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('战报已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final won = result.won;
    final unlocked = outcome.unlocked.take(3).toList();
    final hiddenUnlocked = outcome.unlocked.length - unlocked.length;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (won ? appGold : colors.primary).withValues(
                    alpha: 0.12,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.emoji_events_rounded : Icons.grid_view_rounded,
                  size: 27,
                  color: won ? appGold : colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(_title, style: theme.textTheme.titleLarge),
              if (won && result.stars > 0) ...[
                const SizedBox(height: 8),
                StarRating(stars: result.stars, size: 28),
              ],
              const SizedBox(height: 4),
              Text(
                result.reason,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatThousands(result.score),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 6),
                    child: Text(
                      '分',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (outcome.isRecord) ...[
                const SizedBox(height: 8),
                StatusChip(
                  accent: appGold,
                  filled: true,
                  child: Text(
                    outcome.newBestStars
                        ? '新的星级纪录'
                        : outcome.newBestTime
                        ? '新的最快纪录'
                        : '新的最高分',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (unlocked.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final achievement in unlocked)
                      StatusChip(
                        accent: appGold,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(achievement.icon, size: 12, color: appGold),
                            const SizedBox(width: 4),
                            Text(
                              '新成就 · ${achievement.title}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: appGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hiddenUnlocked > 0)
                      StatusChip(
                        accent: appGold,
                        child: Text(
                          '另有 $hiddenUnlocked 项',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: appGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StatValue(
                        label: '消行',
                        value: '${result.lines}',
                        center: true,
                        valueStyle: theme.textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: StatValue(
                        label: '等级',
                        value: '${result.level}',
                        center: true,
                        valueStyle: theme.textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: StatValue(
                        label: '用时',
                        value: formatPreciseDuration(
                          result.elapsed.inMilliseconds,
                        ),
                        center: true,
                        valueStyle: theme.textTheme.titleSmall,
                      ),
                    ),
                    Expanded(
                      child: StatValue(
                        label: '最高连击',
                        value: '${result.maxCombo}',
                        center: true,
                        valueStyle: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_bestLabel最高 ${formatThousands(bestScore)} 分',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (daily != null) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: const Text('复制战报'),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      child: Text(level == null ? '返回首页' : '返回关卡'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: hasNext && onNext != null ? onNext : onRestart,
                      child: Text(hasNext && onNext != null ? '下一关' : '再来一局'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
