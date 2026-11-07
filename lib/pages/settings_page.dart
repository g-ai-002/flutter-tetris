import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../theme/block_palette.dart';
import '../utils/constants.dart';
import '../utils/platform_info.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/key_binding_section.dart';
import 'widgets/log_viewer_dialog.dart';
import 'widgets/section_card.dart';
import 'widgets/setting_rows.dart';
import 'widgets/skin_option_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                SectionCard(
                  title: '外观与操作',
                  icon: Icons.palette_outlined,
                  children: [
                    Text('棋盘皮肤', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '方块配色与界面强调色一同切换',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final skin in BlockSkin.values)
                          SkinOptionCard(
                            skin: skin,
                            selected: settings.blockSkin == skin,
                            dark: settings.darkMode,
                            onTap: () => settings.setBlockSkin(skin),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${settings.blockSkin.label} · ${settings.blockSkin.description}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: colors.outline.withValues(alpha: 0.6)),
                    const SizedBox(height: 14),
                    SettingSwitchRow(
                      title: '深色模式',
                      subtitle: '暖墨底色，夜间堆叠更护眼',
                      value: settings.darkMode,
                      onChanged: settings.setDarkMode,
                      switchKey: const ValueKey('switch-dark'),
                    ),
                    const SizedBox(height: 10),
                    SettingSwitchRow(
                      title: '幽灵方块',
                      subtitle: '在落点显示当前位置的轮廓',
                      value: settings.showGhost,
                      onChanged: settings.setShowGhost,
                      switchKey: const ValueKey('switch-ghost'),
                    ),
                    const SizedBox(height: 10),
                    SettingSwitchRow(
                      title: '网格线',
                      subtitle: '显示场地内的浅色网格，便于判断列位',
                      value: settings.showGrid,
                      onChanged: settings.setShowGrid,
                      switchKey: const ValueKey('switch-grid'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const KeyBindingSection(),
                const SizedBox(height: 12),
                SectionCard(
                  title: '音效与反馈',
                  icon: Icons.graphic_eq_rounded,
                  children: [
                    SettingSwitchRow(
                      title: '游戏音效',
                      subtitle: '移动、旋转、消行与终局音效',
                      value: settings.soundEnabled,
                      onChanged: settings.setSoundEnabled,
                      switchKey: const ValueKey('switch-sound'),
                    ),
                    const SizedBox(height: 10),
                    SettingSwitchRow(
                      title: '背景音乐',
                      subtitle: '五声音阶循环，运行时合成，可随时关闭',
                      value: settings.musicEnabled,
                      onChanged: settings.setMusicEnabled,
                      switchKey: const ValueKey('switch-music'),
                    ),
                    const SizedBox(height: 10),
                    SettingSwitchRow(
                      title: '震动反馈',
                      subtitle: '消行与终局时给出不同强度的触感',
                      value: settings.hapticsEnabled,
                      onChanged: settings.setHapticsEnabled,
                      switchKey: const ValueKey('switch-haptics'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '玩法',
                  icon: Icons.sports_esports_outlined,
                  children: [
                    Text(
                      '经典、竞速、计时与每日挑战共享 Guideline 规则：7 包随机器、'
                      'SRS 旋转、幽灵落点与暂存，贴地后有 0.5 秒锁定延迟。'
                      '街机模式按红白机规则：帧表重力、经典计分，无暂存与幽灵。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => showHelpDialog(context),
                      icon: const Icon(Icons.menu_book_outlined, size: 17),
                      label: const Text('查看玩法与键位'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '运行日志',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    FutureBuilder<String>(
                      future: FileSystemService.instance.getLogRootPath(),
                      builder: (context, snapshot) {
                        final path = snapshot.data ?? '';
                        final text = path.isEmpty
                            ? (isDesktopPlatform
                                  ? '正在读取日志目录…'
                                  : '当前平台日志仅保留在内存中')
                            : path;
                        return SelectableText(
                          text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontFamily: 'Consolas',
                            fontFamilyFallback: const ['Menlo', 'monospace'],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => showLogViewerDialog(context),
                          icon: const Icon(Icons.article_outlined, size: 17),
                          label: const Text('查看日志'),
                        ),
                        if (isDesktopPlatform)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final path = await FileSystemService.instance
                                  .getLogRootPath();
                              final ok = await FileSystemService.instance
                                  .openDirectory(path);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? '已打开日志目录' : '无法打开日志目录'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.folder_open, size: 17),
                            label: const Text('打开目录'),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: '关于',
                  icon: Icons.info_outline,
                  children: [
                    const SettingAboutRow(
                      label: '版本',
                      value: 'v${AppConstants.version}',
                    ),
                    const SizedBox(height: 8),
                    const SettingAboutRow(
                      label: '引擎',
                      value: 'Flutter + Flame',
                    ),
                    const SizedBox(height: 8),
                    const SettingAboutRow(
                      label: '平台',
                      value: 'Android / Windows / Web',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '所有玩法均在本地运行，不需要联网；'
                      '音效与背景音乐在运行时合成，仓库不存放音频文件。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
