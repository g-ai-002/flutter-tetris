# 俄罗斯方块

一个跨 **Android** 与 **Windows** 平台的俄罗斯方块游戏，使用 Flutter 开发。

支持：
- 🧩 经典 7 种方块（I/O/T/S/Z/J/L）
- 🔄 旋转、移动、硬降
- 👻 Ghost piece 落点预览
- ⏭️ 下一个方块预览
- 📊 分数系统（消行计分、等级递增、最高分记录）
- ⏸️ 暂停/继续
- ⌨️ 键盘快捷键（方向键移动/旋转、空格硬降、P 暂停、R 重新开始）
- 👆 棋盘手势（点击/上滑旋转、左右滑动移动、下滑硬降）
- 🕹️ 操控方式可切换（手势 + 虚拟按键 / 仅虚拟按键 / 仅手势）
- 🏠 首页与设置页（外观、音效、操控方式集中管理）
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
- Android 15（minSdk=35，targetSdk/compileSdk=37，仅打包 arm64-v8a）

## 玩法

1. 启动后进入首页，点击「开始游戏」开始（也可先在首页选择模式）。
2. 操控方式默认三种并存：点击/滑动棋盘、底部方向按钮、键盘快捷键；可在设置中限定为其中一种。
3. 填满一行即可消除，获得分数。
4. 等级随消除行数提升，下落速度加快。
5. 方块堆到顶部则游戏结束，点击「重新开始」继续。

## 日志

日志写入到用户目录下的 `FlutterTetris/logs/app_YYYYMMDD.log`：
- Windows：`%USERPROFILE%\Documents\FlutterTetris\logs\`
- Android：`/data/data/com.flutter.tetris/app_flutter/FlutterTetris/logs/`

「设置」→「查看日志」可查看最近日志并一键复制。

## 本地开发

### 环境要求

- Flutter 3.47.7+
- Android SDK 37+（编译 SDK；最低支持 Android 15，仅覆盖最新 3 个 Android 大版本）
- Windows 10+

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

- Flutter 3.47.7, Material 3
- provider（状态管理）
- shared_preferences（最高分持久化）
- audioplayers（音效与背景音乐）
- window_manager（Windows 窗口控制）

## 版本历史

- **v0.6.x**：首页与设置页。新增应用入口首页（开始游戏/选择模式/排行榜/主题切换/设置入口，展示最高分、当前模式与操控方式），设置页集中管理外观、音效与操控方式；新增操控方式切换（手势 + 虚拟按键 / 仅虚拟按键 / 仅手势）与棋盘手势层；界面重构为自适应紧凑布局，移除独立音效菜单；换用 T 形方块自适应启动图标。
- **v0.5.x**：多种游戏模式。经典模式（无限挑战）、限时模式（120 秒内获高分）、挑战模式（最快消除 40 行），模式选择页面，模式特有 UI 信息展示；构建配置整改（对齐姊妹项目基线），移除不稳定的版本号断言用例。
- **v0.4.x**：排行榜/历史记录（按分数降序排列、清空历史），重构优化（提取公共布局组件、合并重复代码、提取测试工具、拆分主题方法）。
- **v0.3.x**：音效与背景音乐（程序化生成 WAV），重构优化（提取 StatusOverlay/SoundMenu 独立 widget，消除重复代码）。
- **v0.1.x – v0.2.x**：早期版本。经典俄罗斯方块核心玩法（7 种方块、下一个方块与 Ghost piece 预览、分数系统、暂停/继续、自适应布局、浅色/深色主题、日志系统、CI/CD 自动出包）；触屏手势与键盘快捷键操作；提取独立 widget，消除重复代码，补充测试覆盖。

更多详情见 [plan.md](./plan.md)。

## 许可

详见 [LICENSE](./LICENSE)。
