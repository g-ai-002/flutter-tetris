import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../input/key_bindings.dart';
import '../../providers/settings_provider.dart';
import 'section_card.dart';

/// 设置页的键位与手柄区域：逐项改键、恢复默认与手柄操作说明。
class KeyBindingSection extends StatelessWidget {
  const KeyBindingSection({super.key});

  Future<void> _rebind(BuildContext context, GameAction action) async {
    final settings = context.read<SettingsProvider>();
    final key = await showDialog<LogicalKeyboardKey>(
      context: context,
      builder: (_) => KeyCaptureDialog(action: action),
    );
    if (key == null) return;
    await settings.bindKey(action, key);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bindings = settings.keyBindings;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SectionCard(
      title: '键位与手柄',
      icon: Icons.keyboard_alt_outlined,
      children: [
        Text(
          '点击任一操作即可重新绑定按键，与已有按键冲突时会自动交换。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        for (final action in GameAction.values)
          _BindingRow(
            action: action,
            labels: bindings.labelsFor(action),
            onTap: () => _rebind(context, action),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('reset-keys'),
            onPressed: settings.resetKeyBindings,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('恢复默认键位'),
          ),
        ),
        Divider(color: colors.outline.withValues(alpha: 0.6)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.videogame_asset_outlined,
              size: 17,
              color: colors.primary,
            ),
            const SizedBox(width: 8),
            Text('手柄 · 即插即用', style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '左摇杆 / 十字键：移动与软降　A：顺时针　B：逆时针\n'
          'X / LB：暂存　Y / RB / 十字键上：硬降　Start：暂停',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '支持 Xbox、PlayStation 及标准布局的 USB / 蓝牙手柄；'
          'Android 需系统已识别手柄，Web 需浏览器支持 Gamepad API。',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _BindingRow extends StatelessWidget {
  const _BindingRow({
    required this.action,
    required this.labels,
    required this.onTap,
  });

  final GameAction action;
  final List<String> labels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return InkWell(
      key: ValueKey('bind-${action.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            Text(action.label, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final label in labels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.outline.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit_outlined, size: 15, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// 捕获一次按键输入；Esc 取消，其余按键立即返回。
class KeyCaptureDialog extends StatelessWidget {
  const KeyCaptureDialog({super.key, required this.action});

  final GameAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('绑定「${action.label}」'),
      content: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop(key);
          }
          return KeyEventResult.handled;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请按下新的按键', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Esc 取消；若新按键已被其他操作使用，两者会自动交换。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
