import 'package:flutter/material.dart';

import '../../providers/settings_provider.dart';
import '../../utils/formatters.dart';
import 'section_card.dart';
import 'stat_value.dart';

/// 累计对局、消行与得分。
class RecordsSummaryCard extends StatelessWidget {
  const RecordsSummaryCard({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '累计',
      icon: Icons.insights_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: StatValue(
                label: '对局',
                value: '${settings.gamesPlayed}',
                suffix: '局',
                center: true,
                valueStyle: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: StatValue(
                label: '累计消行',
                value: formatThousands(settings.totalLines),
                suffix: '行',
                center: true,
                valueStyle: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: StatValue(
                label: '累计得分',
                value: formatThousands(settings.totalScore),
                suffix: '分',
                center: true,
                valueStyle: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
