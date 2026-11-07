import 'package:flutter/material.dart';

import '../../game/tetris_controller.dart';
import '../../input/action_repeat.dart';

/// 触屏操作区。
/// 竖屏默认三列两行；[columns] 为 2 时改为两列三行，供横屏侧栏使用。
/// [dense] 收窄按键高度，把空间还给棋盘。
class TouchPad extends StatelessWidget {
  const TouchPad({
    super.key,
    required this.controller,
    this.dense = false,
    this.columns = 3,
  });

  final TetrisController controller;
  final bool dense;
  final int columns;

  List<_Spec> _specs(ColorScheme colors, bool enabled) {
    final hold = controller.rules.holdEnabled;
    if (columns == 2) {
      return [
        _Spec('左移', Icons.arrow_back_rounded, colors.onSurfaceVariant,
            enabled ? controller.moveLeft : null, repeat: true),
        _Spec('右移', Icons.arrow_forward_rounded, colors.onSurfaceVariant,
            enabled ? controller.moveRight : null, repeat: true),
        _Spec('软降', Icons.arrow_downward_rounded, colors.onSurfaceVariant,
            enabled ? controller.softDrop : null, repeat: true),
        _Spec('旋转', Icons.rotate_right_rounded, colors.primary,
            enabled ? controller.rotateClockwise : null),
        _Spec('硬降', Icons.vertical_align_bottom_rounded, colors.tertiary,
            enabled ? controller.hardDrop : null),
        if (hold)
          _Spec('暂存', Icons.inventory_2_outlined, colors.secondary,
              controller.canHold ? controller.hold : null),
      ];
    }
    return [
      if (hold)
        _Spec('暂存', Icons.inventory_2_outlined, colors.secondary,
            controller.canHold ? controller.hold : null),
      _Spec('旋转', Icons.rotate_right_rounded, colors.primary,
          enabled ? controller.rotateClockwise : null),
      _Spec('硬降', Icons.vertical_align_bottom_rounded, colors.tertiary,
          enabled ? controller.hardDrop : null),
      _Spec('左移', Icons.arrow_back_rounded, colors.onSurfaceVariant,
          enabled ? controller.moveLeft : null, repeat: true),
      _Spec('软降', Icons.arrow_downward_rounded, colors.onSurfaceVariant,
          enabled ? controller.softDrop : null, repeat: true),
      _Spec('右移', Icons.arrow_forward_rounded, colors.onSurfaceVariant,
          enabled ? controller.moveRight : null, repeat: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final specs = _specs(Theme.of(context).colorScheme, controller.canControl);
    final height = dense ? 44.0 : 50.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 2, 10, dense ? 4 : 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < specs.length; i += columns) ...[
            if (i > 0) SizedBox(height: dense ? 5 : 8),
            Row(
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(
                    child: i + j < specs.length
                        ? _PadButton(spec: specs[i + j], height: height)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Spec {
  const _Spec(this.label, this.icon, this.accent, this.onPressed,
      {this.repeat = false});

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool repeat;
}

class _PadButton extends StatefulWidget {
  const _PadButton({required this.spec, required this.height});

  final _Spec spec;
  final double height;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  late final ActionRepeat _repeat = ActionRepeat(
    onRepeat: () {
      if (mounted) widget.spec.onPressed?.call();
    },
  );

  bool _pressed = false;

  @override
  void dispose() {
    _repeat.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.spec.onPressed == null) return;
    setState(() => _pressed = true);
    _repeat.start(
      interval: widget.spec.repeat
          ? const Duration(milliseconds: 70)
          : Duration.zero,
      initialDelay: const Duration(milliseconds: 220),
    );
  }

  void _stop() {
    _repeat.stop();
    if (_pressed && mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spec = widget.spec;
    final enabled = spec.onPressed != null;
    final accent = enabled ? spec.accent : colors.outline;
    return Semantics(
      button: true,
      label: spec.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _start() : null,
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: !enabled
                  ? 0.03
                  : _pressed
                  ? 0.20
                  : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.45 : 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, size: 19, color: accent),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  spec.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
