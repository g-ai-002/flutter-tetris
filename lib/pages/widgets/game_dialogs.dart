import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/daily_challenge.dart';
import '../../game/game_mode.dart';
import '../../game/level.dart';
import '../../game/tetris_controller.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        i < result.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 28,
                        color: i < result.stars
                            ? appGold
                            : colors.outline.withValues(alpha: 0.7),
                      ),
                  ],
                ),
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
                    _ResultStat(label: '消行', value: '${result.lines}'),
                    _ResultStat(label: '等级', value: '${result.level}'),
                    _ResultStat(
                      label: '用时',
                      value: formatPreciseDuration(
                        result.elapsed.inMilliseconds,
                      ),
                    ),
                    _ResultStat(label: '最高连击', value: '${result.maxCombo}'),
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

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 暂停弹窗：继续、重开或返回首页。
Future<void> showPauseDialog(
  BuildContext context, {
  required TetrisController controller,
  required VoidCallback onRestart,
  required VoidCallback onExit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final level = controller.levelDef;
      final label = level == null
          ? controller.mode.label
          : '第 ${level.id} 关 · ${level.name}';
      return AlertDialog(
        title: const Text('已暂停'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label · 分数 ${formatThousands(controller.score)}'),
            const SizedBox(height: 6),
            Text(
              '消行 ${controller.lines} · 等级 ${controller.level}',
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onExit();
            },
            child: Text(level == null ? '返回首页' : '返回关卡'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onRestart();
            },
            child: const Text('重新开始'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.resume();
            },
            child: const Text('继续游戏'),
          ),
        ],
      );
    },
  );
}

/// 规则与操作说明。
Future<void> showHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final bodyStyle = theme.textTheme.bodySmall?.copyWith(
        height: 1.7,
        color: theme.colorScheme.onSurfaceVariant,
      );
      return AlertDialog(
        title: const Text('玩法与操作'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '堆叠方块填满整行即可消除，消除越多得分越高；'
                  '一次消除 4 行可获得额外奖励，连续消行还有连击加分。'
                  '每消除 10 行提升一级，下落速度随之加快。',
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text('键盘', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '← → 左右移动　↓ 软降　空格 硬降\n'
                  '↑ / X 顺时针旋转　Z 逆时针旋转\n'
                  'C / Shift 暂存　P / Esc 暂停　R 重新开始',
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text('触屏与鼠标', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '点击棋盘旋转，左右拖动移动，向下拖动软降，'
                  '向上滑动暂存；下方按钮可完成全部操作。',
                  style: bodyStyle,
                ),
                const SizedBox(height: 14),
                Text('模式', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                for (final mode in GameMode.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '· ${mode.label}：${mode.tagline}',
                      style: bodyStyle,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
        ],
      );
    },
  );
}
