import 'package:flutter/material.dart';

import '../../game/tetris_controller.dart';
import '../../input/action_repeat.dart';

/// 触屏操作区：上排暂存 / 旋转 / 硬降，下排左移 / 软降 / 右移。
class TouchPad extends StatelessWidget {
  const TouchPad({super.key, required this.controller});

  final TetrisController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _PadButton(
                  label: '暂存',
                  icon: Icons.inventory_2_outlined,
                  accent: colors.secondary,
                  onPressed: controller.canHold ? controller.hold : null,
                  height: 40,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PadButton(
                  label: '旋转',
                  icon: Icons.rotate_right_rounded,
                  accent: colors.primary,
                  onPressed: controller.canControl
                      ? controller.rotateClockwise
                      : null,
                  height: 40,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PadButton(
                  label: '硬降',
                  icon: Icons.vertical_align_bottom_rounded,
                  accent: colors.tertiary,
                  onPressed: controller.canControl ? controller.hardDrop : null,
                  height: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PadButton(
                  label: '左移',
                  icon: Icons.arrow_back_rounded,
                  accent: colors.onSurfaceVariant,
                  onPressed: controller.canControl ? controller.moveLeft : null,
                  repeat: true,
                  height: 48,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PadButton(
                  label: '软降',
                  icon: Icons.arrow_downward_rounded,
                  accent: colors.onSurfaceVariant,
                  onPressed: controller.canControl ? controller.softDrop : null,
                  repeat: true,
                  height: 48,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PadButton(
                  label: '右移',
                  icon: Icons.arrow_forward_rounded,
                  accent: colors.onSurfaceVariant,
                  onPressed: controller.canControl
                      ? controller.moveRight
                      : null,
                  repeat: true,
                  height: 48,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PadButton extends StatefulWidget {
  const _PadButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
    required this.height,
    this.repeat = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
  final double height;

  /// 按住后连续触发（左右移动与软降）。
  final bool repeat;

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  late final ActionRepeat _repeat = ActionRepeat(
    onRepeat: () {
      if (mounted) widget.onPressed?.call();
    },
  );

  @override
  void dispose() {
    _repeat.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.onPressed == null) return;
    _repeat.start(
      interval: widget.repeat
          ? const Duration(milliseconds: 70)
          : Duration.zero,
      initialDelay: const Duration(milliseconds: 220),
    );
  }

  void _stop() => _repeat.stop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = widget.onPressed != null;
    final accent = enabled ? widget.accent : colors.outline;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _start() : null,
        onTapUp: (_) => _stop(),
        onTapCancel: _stop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: enabled ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.45 : 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 20, color: accent),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: enabled ? colors.onSurface : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
