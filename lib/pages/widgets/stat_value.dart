import 'package:flutter/material.dart';

/// 数值与标签的统一排版：纪录卡片、结算弹窗与对局 HUD 共用。
/// 默认数值在上、标签在下；[StatValue.inline] 为左右一行，
/// [labelFirst] 用于窄屏 HUD 这类标签在上的场景。
class StatValue extends StatelessWidget {
  const StatValue({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.accent,
    this.center = false,
    this.labelFirst = false,
    this.alignment,
    this.valueStyle,
  }) : inline = false;

  const StatValue.inline({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.valueStyle,
  }) : suffix = null,
       center = false,
       labelFirst = false,
       alignment = null,
       inline = true;

  final String label;
  final String value;

  /// 数值后缀，如「局」「行」「分」。
  final String? suffix;

  /// 数值强调色，未指定时使用正文色。
  final Color? accent;

  /// 居中排版，默认左对齐。
  final bool center;

  /// 标签显示在数值上方。
  final bool labelFirst;

  /// 指定交叉轴对齐，默认左对齐；设置后覆盖 [center] 的对齐效果。
  final CrossAxisAlignment? alignment;

  final bool inline;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final caption = theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant);

    if (inline) {
      return Row(
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            style: (valueStyle ?? theme.textTheme.bodyMedium)?.copyWith(
              fontWeight: FontWeight.w600,
              color: accent ?? colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    final align = center ? TextAlign.center : TextAlign.start;
    final cross = alignment ?? (center ? CrossAxisAlignment.center : CrossAxisAlignment.start);
    final numberStyle = (valueStyle ?? theme.textTheme.titleMedium)?.copyWith(
      fontWeight: FontWeight.w700,
      color: accent ?? colors.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final valueWidget = suffix == null
        ? Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: numberStyle,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: numberStyle,
                ),
              ),
              const SizedBox(width: 2),
              Text(suffix!, style: caption),
            ],
          );
    final labelWidget = Text(label, textAlign: align, style: caption);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: labelFirst
          ? [labelWidget, const SizedBox(height: 2), valueWidget]
          : [valueWidget, const SizedBox(height: 3), labelWidget],
    );
  }
}
