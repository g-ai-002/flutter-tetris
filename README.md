# 俄罗斯方块

一个跨 **Android** 与 **Windows** 平台的俄罗斯方块游戏，使用 Flutter 开发。

支持：
- 🧩 经典 7 种方块（I/O/T/S/Z/J/L）
- 🔄 旋转、移动、硬降
- 👻 Ghost piece 落点预览
- 📊 分数系统（消行计分、等级递增、最高分记录）
- ⏸️ 暂停/继续
- ⌨️ 键盘快捷键（方向键移动/旋转、空格硬降、P 暂停、R 重新开始）
- 👆 触屏手势（滑动移动、点击旋转、下滑硬降）
- 🔊 音效与背景音乐（可独立开关）
- 🏆 排行榜/历史记录
- 🎮 多种游戏模式（经典/限时/挑战）
- 🌗 浅色 / 深色主题
- 📱 自适应布局（竖屏/横屏、手机/平板/折叠屏）
- 📝 用户目录下的日志文件（方便排障）

## 下载
最新版本请前往 [Releases](../../releases) 页面下载：
- Windows：`flutter-tetris-x.y.z-windows-x86_64.zip`，解压后运行 `flutter_tetris.exe`
- Android：`flutter-tetris-x.y.z-android-aarch64.apk`，直接安装

最低系统要求：
- Windows 10 及以上
- Android 14（minSdk=34，targetSdk/compileSdk=36，仅打包 arm64-v8a）

## 玩法

1. 启动游戏后自动开始，方块从顶部下落。
2. 使用底部方向按钮控制方块：左移、右移、下移、旋转、硬降。
3. 填满一行即可消除，获得分数。
4. 等级随消除行数提升，下落速度加快。
5. 方块堆到顶部则游戏结束，点击「重新开始」继续。

## 日志

日志写入到用户目录下的 `FlutterTetris/logs/app_YYYYMMDD.log`：
- Windows：`%USERPROFILE%\Documents\FlutterTetris\logs\`
- Android：`/data/data/com.flutter.tetris/app_flutter/FlutterTetris/logs/`

## 本地开发

```bash
flutter pub get
flutter analyze
flutter test
flutter run                  # 桌面 / 模拟器
flutter build apk            # Android
flutter build windows        # Windows（需在 Windows 上）
```

> 项目本地不附带 `windows/` 平台目录；构建 Windows 时由 CI 自动生成。

## 技术栈

- Flutter 3.44.1, Material 3
- provider（状态管理）
- shared_preferences（最高分持久化）
- audioplayers（音效与背景音乐）
- window_manager（Windows 窗口控制）

## 版本历史

- **v0.5.0**：多种游戏模式。经典模式（无限挑战）、限时模式（120 秒内获高分）、挑战模式（最快消除 40 行），模式选择页面，模式特有 UI 信息展示。
- **v0.4.x**：排行榜/历史记录（按分数降序排列、清空历史），重构优化（提取公共布局组件、合并重复代码、提取测试工具、拆分主题方法）。
- **v0.3.x**：音效与背景音乐（程序化生成 WAV），重构优化（提取 StatusOverlay/SoundMenu 独立 widget，消除重复代码）。
- **v0.2.x**：触屏手势操作 + 键盘快捷键。支持滑动移动/点击旋转/下滑硬降，方向键/空格/P/R 键盘操作；重构优化（提取布局组件，精简主题代码）。
- **v0.1.x**：首个版本与重构。经典俄罗斯方块核心玩法、7 种方块、Ghost piece 预览、分数系统、暂停/继续、自适应布局、浅色/深色主题、日志系统、CI/CD 自动出包；提取独立 widget，消除重复代码，补充测试覆盖。

更多详情见 [plan.md](./plan.md)。

## 许可

详见 [LICENSE](./LICENSE)。
