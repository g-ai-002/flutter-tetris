import 'package:flutter/material.dart';

import '../../game/game_mode.dart';
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
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _ResultDialog(
      result: result,
      outcome: outcome,
      bestScore: bestScore,
      onRestart: () {
        Navigator.of(dialogContext).pop();
        onRestart();
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
  });

  final GameResult result;
  final RecordOutcome outcome;
  final int bestScore;
  final VoidCallback onRestart;
  final VoidCallback onExit;

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
              Text(won ? '完成挑战' : '游戏结束', style: theme.textTheme.titleLarge),
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
                    outcome.newBestTime ? '新的最快纪录' : '新的最高分',
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
                '历史最高 ${formatThousands(bestScore)} 分',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onExit,
                      child: const Text('返回首页'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onRestart,
                      child: const Text('再来一局'),
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
    builder: (dialogContext) => AlertDialog(
      title: const Text('已暂停'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${controller.mode.label} · 分数 ${formatThousands(controller.score)}',
          ),
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
          child: const Text('返回首页'),
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
    ),
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
