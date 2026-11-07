import 'package:flutter/material.dart';

import '../game/game_mode.dart';
import 'app_theme.dart';

/// 玩法的图标与主色，首页和纪录页共用同一套映射。
class ModeVisual {
  const ModeVisual({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

ModeVisual modeVisualFor(GameMode mode, ColorScheme colors) => switch (mode) {
  GameMode.endless => ModeVisual(
    icon: Icons.all_inclusive_rounded,
    accent: colors.primary,
  ),
  GameMode.sprint => const ModeVisual(
    icon: Icons.timer_outlined,
    accent: appJade,
  ),
  GameMode.ultra => const ModeVisual(icon: Icons.bolt_rounded, accent: appGold),
  GameMode.arcade => const ModeVisual(
    icon: Icons.videogame_asset_rounded,
    accent: appJade,
  ),
  GameMode.level => const ModeVisual(icon: Icons.flag_rounded, accent: appJade),
  GameMode.daily => ModeVisual(
    icon: Icons.today_rounded,
    accent: colors.primary,
  ),
};
