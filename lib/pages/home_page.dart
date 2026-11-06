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
              final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
              final contentWidth = math.min(
                constraints.maxWidth - horizontal * 2,
                820.0,
              );
              final wide = contentWidth >= 700;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 38),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HomeTopBar(),
                          const SizedBox(height: 24),
                          HomeHero(wide: wide, settings: settings),
                          const SizedBox(height: 30),
                          HomeModeCards(
                            settings: settings,
                            wide: wide,
                            contentWidth: contentWidth,
                          ),
                          const SizedBox(height: 24),
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
