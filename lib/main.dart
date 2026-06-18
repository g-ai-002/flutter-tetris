import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/game_page.dart';
import 'providers/game_provider.dart';
import 'services/log_service.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(420, 720),
      minimumSize: Size(360, 520),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConstants.appName,
    );
    windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await LogService.init();
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  await SoundService().init(prefs);
  runApp(TetrisApp(prefs: prefs));
}

class TetrisApp extends StatelessWidget {
  final SharedPreferences prefs;
  const TetrisApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final fontFamily = Platform.isWindows ? 'Microsoft YaHei UI' : null;
    final darkMode = prefs.getBool(AppConstants.prefKeyDarkMode) ?? false;

    return ChangeNotifierProvider(
      create: (_) => GameProvider(prefs),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(fontFamily: fontFamily),
        darkTheme: buildDarkTheme(fontFamily: fontFamily),
        themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN')],
        locale: const Locale('zh', 'CN'),
        home: const GamePage(),
      ),
    );
  }
}
