import 'dart:async';

import 'package:flutter/foundation.dart';

/// 按住连续触发的统一调度：先立即触发一次，再按固定间隔重复。
///
/// 键盘与手柄的重复事件由平台负责，触控按钮与手柄长按则共用这里的节拍，
/// 避免三处各写一套定时器导致起手延迟与频率不一致。
class ActionRepeat {
  ActionRepeat({required this.onRepeat});

  final VoidCallback onRepeat;

  Timer? _delay;
  Timer? _timer;

  bool get isRunning => _delay != null || _timer != null;

  /// 开始连发。[interval] 为零时只触发一次。
  void start({
    Duration interval = const Duration(milliseconds: 70),
    Duration initialDelay = Duration.zero,
  }) {
    stop();
    onRepeat();
    if (interval <= Duration.zero) return;
    if (initialDelay > Duration.zero) {
      _delay = Timer(initialDelay, () => _begin(interval));
    } else {
      _begin(interval);
    }
  }

  void _begin(Duration interval) {
    _delay = null;
    _timer = Timer.periodic(interval, (_) => onRepeat());
  }

  void stop() {
    _delay?.cancel();
    _delay = null;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
