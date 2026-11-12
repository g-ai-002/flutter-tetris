import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 三星评价，用于关卡选择与结算弹窗。
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.stars, this.size = 16, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? appGold : outline,
          ),
      ],
    );
  }
}
