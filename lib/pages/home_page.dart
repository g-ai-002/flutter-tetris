import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/block_palette.dart';
import '../utils/constants.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_mode_cards.dart';
import 'widgets/home_top_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final palette = settings.blockSkin.palette(dark: isDark);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.screenGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontal = width >= 1200
                  ? 48.0
                  : width >= 700
                  ? 28.0
                  : 16.0;
              const maxContent = 960.0;
              final contentWidth = math.min(width - horizontal * 2, maxContent);
              final tight = constraints.maxHeight < 680;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  tight ? 10 : 14,
                  horizontal,
                  tight ? 18 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 38)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: maxContent),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HomeTopBar(),
                          SizedBox(height: tight ? 16 : 24),
                          const HomeHero(),
                          SizedBox(height: tight ? 20 : 30),
                          HomeModeCards(settings: settings, contentWidth: contentWidth),
                          SizedBox(height: tight ? 16 : 24),
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
