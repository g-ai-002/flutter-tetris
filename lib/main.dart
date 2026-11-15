import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/game_display.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('Flutter 异常', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('未捕获异常', error, stack);
    return true;
  };

  // 偏好读取与桌面窗口互不依赖，先并行等待；日志与音频推迟到首帧之后，
  // 冷启动不必等磁盘建文件与十几段音频合成。
  final storageFuture = StorageService.instance;
  await setupDesktopWindow();
  final storage = await storageFuture;
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  MusicService.enabled = storage.musicEnabled;

  runApp(TetrisApp(storage: storage));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startBackgroundServices(storage));
  });
}

/// 首帧之后的初始化：沉浸显示、日志落盘与音频合成。
/// 日志服务在初始化前会把日志留在内存缓冲里，随后补写，不会丢启动日志。
Future<void> _startBackgroundServices(StorageService storage) async {
  await enterImmersiveDisplay();
  await initLogging();
  final soundReady = SoundService.init();
  // 音乐与音效共用 SoLoud，等音效载入后再启动，避免重复初始化音频引擎。
  // Web 需要用户手势，首次点击时由 App 的监听器启动。
  if (storage.musicEnabled && !kIsWeb) {
    unawaited(soundReady.then((_) => MusicService.start()));
  }
}
