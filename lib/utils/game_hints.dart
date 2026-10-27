import 'platform_info.dart';

/// 各界面展示的玩法提示：桌面端讲键盘，移动端/浏览器讲触屏。
class GameHints {
  GameHints._();

  /// 首页底部的一句话提示。
  static String get home => isDesktopPlatform
      ? '方向键移动与旋转，空格硬降，P 暂停'
      : '点击屏幕旋转，左右滑动移动，下滑硬降';

  /// 游戏画面中的开局提示。
  static String get inGame => isDesktopPlatform
      ? '← → 移动 · ↑ 旋转 · 空格硬降 · P 暂停 · R 重开'
      : '点击旋转 · 左右滑动移动 · 下滑硬降';

  /// 设置页：移动与旋转。
  static String get movement => isDesktopPlatform
      ? '← → 左右移动，↑ 顺时针旋转，↓ 加速下落'
      : '点击屏幕旋转，左右滑动移动';

  /// 设置页：硬降。
  static String get hardDrop => isDesktopPlatform
      ? '空格把当前方块直接落到底部'
      : '快速下滑把当前方块直接落到底部';

  /// 设置页：暂停与重开。
  static String get pause => isDesktopPlatform
      ? 'P 暂停或继续，结束后按 R 重新开始'
      : '点右上角暂停按钮，结束后点「重新开始」';
}
