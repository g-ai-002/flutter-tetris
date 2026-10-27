import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home_page.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'services/history_service.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/sound_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDesktopWindow();

  await initLogging();
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');

  await HistoryService.init();

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
    final fontFamily = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
        ? 'Microsoft YaHei UI'
        : null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => GameProvider(prefs)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(fontFamily: fontFamily),
            darkTheme: buildDarkTheme(fontFamily: fontFamily),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN')],
            locale: const Locale('zh', 'CN'),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
