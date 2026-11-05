/// 每日挑战：本地日期决定种子，同一天的所有对局共用同一副牌。
library;

import '../utils/formatters.dart';

class DailyChallenge {
  const DailyChallenge({required this.date, required this.seed});

  /// 本地日期（当天 00:00）。
  final DateTime date;
  final int seed;

  /// 战报里带上的标签。
  static const String shareTag = '#俄罗斯方块每日挑战';

  /// 由任意时间点的本地日期构造当天挑战。
  factory DailyChallenge.forDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final key = day.year * 10000 + day.month * 100 + day.day;
    return DailyChallenge(date: day, seed: _mixSeed(key));
  }

  static DailyChallenge today([DateTime? now]) =>
      DailyChallenge.forDate(now ?? DateTime.now());

  /// 最近 [count] 天，含今天，按日期从新到旧。
  static List<DailyChallenge> recent(int count, {DateTime? now}) {
    final today = DailyChallenge.today(now);
    return [
      for (var i = 0; i < count; i++)
        DailyChallenge.forDate(
          DateTime(today.date.year, today.date.month, today.date.day - i),
        ),
    ];
  }

  /// `yyyyMMdd`，作为本地纪录的键。
  String get key => formatDateKey(date);

  /// `11 月 5 日`
  String get label => '${date.month} 月 ${date.day} 日';

  /// `周四`
  String get weekdayLabel =>
      const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1];

  /// 距离下一次刷新（本地零点）还有多久。
  Duration refreshIn(DateTime now) {
    final next = DateTime(date.year, date.month, date.day + 1);
    final left = next.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// 分享到聊天窗口的战报文本。
  String shareText({
    required int score,
    required int lines,
    required int level,
  }) {
    return [
      '俄罗斯方块 · 每日挑战 ${date.month} 月 ${date.day} 日',
      '得分 ${formatThousands(score)} · 消行 $lines · 等级 $level',
      '同一天同一副牌，来试试能不能超过我？',
      shareTag,
    ].join('\n');
  }

  /// 日期与种子的混淆：让相邻日期的种子没有可见规律。
  ///
  /// 只用整数乘法与取模，中间值不超过 2^47，
  /// 保证 VM 与 Web 得到完全相同的种子。
  static int _mixSeed(int value) {
    const modulus = 2147483647;
    var x = value % modulus;
    x = (x * 48271) % modulus;
    x = (x * 16807 + 11) % modulus;
    x = (x * 69621) % modulus;
    return x == 0 ? 1 : x;
  }
}
