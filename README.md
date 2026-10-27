# 俄罗斯方块

一个跨 **Android**、**Windows** 与 **Web** 平台的俄罗斯方块游戏，使用 Flutter 开发。

支持：
- 🧩 经典 7 种方块（I/O/T/S/Z/J/L）
- 🔄 旋转、移动、硬降
- 👻 Ghost piece 落点预览
- ⏭️ 下一个方块预览
- 📊 分数系统（消行计分、等级递增、最高分记录）
- ⏸️ 暂停/继续
- ⌨️ 键盘快捷键（方向键移动/旋转、空格硬降、P 暂停、R 重新开始）
- 👆 全屏手势（点击/上滑旋转、左右滑动移动、下滑硬降，棋盘以外也能操作）
- 🕹️ 操控方式可切换（手势 + 虚拟按键 / 仅虚拟按键 / 仅手势）
- 🏠 首页与设置页（外观、音效、操控方式集中管理）
- 🔊 音效与背景音乐（可独立开关）
- 🏆 排行榜/历史记录
- 🎮 多种游戏模式（经典/限时/挑战）
- 🌗 浅色 / 深色主题
- 📱 自适应布局（竖屏/横屏、手机/平板/折叠屏）
- 🧭 平台自适应提示（桌面讲键盘按键，移动端/浏览器讲点击与滑动）
- ⚡ 渲染开销：棋盘网格与外边框烘焙成 `Picture`，暂停与结算停掉 Flame 主循环
- 📝 用户目录下的日志文件（方便排障）
- 🌐 Web 版：浏览器内内存日志，发布 tag 自动构建并部署到 GitHub Pages
- 🔥 基于 Flame 引擎的棋盘渲染与消行特效

## 下载
最新版本请前往 [Releases](../../releases) 页面下载：
- Windows：`flutter-tetris-x.y.z-windows-x86_64.zip`，解压后运行 `flutter_tetris.exe`
- Android：`flutter-tetris-x.y.z-android-aarch64.apk`，直接安装
- Web：`flutter-tetris-x.y.z-web.zip`（Gitea Release 归档；GitHub Pages 上可直接在线试玩）

最低系统要求：
- Windows 10 及以上
- Android 15（minSdk=35，targetSdk=37 / compileSdk=37.2，仅打包 arm64-v8a）
- 浏览器：Chrome / Edge / Safari 等现代浏览器

## 在线试玩

GitHub 上每个 `v*` tag 都会额外构建 Web 版并发布到 GitHub Pages，
各版本互不覆盖，历史版本长期保留：

- 版本列表：<https://g-ai-002.github.io/flutter-tetris/>
  （首页顶部是最新正式版本的醒目入口，点开即玩；下方分「正式版本」与
  「调试版本」两列，历史正式版本从新到旧排列）
- 预览版：<https://g-ai-002.github.io/flutter-tetris/debug/>

非 tag 触发（手动运行 `🚀 构建与发布` 工作流）构建出来的站点会发到 `debug/`
目录，方便合并前验证效果；tag 触发时除了更新 `v<版本>/`，还会把 Web 产物
`<仓库名>-<版本>-web.zip` 一并归档到 GitHub Release。

Pages 首次使用需在仓库 Settings → Pages 里把发布来源设为 `gh-pages` 分支的
根目录；之后每次推送 tag 都会自动更新站点（含版本索引页与 `versions.json`）。

## 玩法

1. 启动后进入首页，点击「开始游戏」开始（也可先在首页选择模式）。
2. 操控方式默认三种并存：点击/滑动屏幕、底部方向按钮、键盘快捷键；可在设置中限定为其中一种。
3. 填满一行即可消除，获得分数。
4. 等级随消除行数提升，下落速度加快。
5. 方块堆到顶部则游戏结束，点击「重新开始」继续。

| 平台    | 移动         | 旋转       | 硬降         | 暂停/重开           |
|---------|--------------|------------|--------------|---------------------|
| Windows | ← →          | ↑          | 空格         | P 暂停，R 重开      |
| Web     | ← →          | ↑          | 空格         | P 暂停，R 重开      |
| Android | 左右滑动     | 点击屏幕   | 快速下滑     | 右上角暂停按钮      |

## 日志

日志写入到用户目录下的 `FlutterTetris/logs/app_YYYYMMDD.log`：
- Windows：`%USERPROFILE%\Documents\FlutterTetris\logs\`
- Android：`/data/data/com.flutter.tetris/app_flutter/FlutterTetris/logs/`
- Web：浏览器没有可写目录，日志只保留在内存中，刷新页面即清空

「设置」→「查看日志」可查看最近日志并一键复制。Web 版不显示「日志目录」与
「打开目录」入口，日志查看与复制仍然可用。

## 本地开发

### 环境要求

- Flutter 3.47.7+
- Android SDK 37+（编译 SDK；最低支持 Android 15，仅覆盖最新 3 个 Android 大版本）
- Windows 10+
- 浏览器（Chrome / Edge / Safari 均可运行 Web 版）

```bash
flutter pub get
flutter analyze
flutter test
flutter run                  # 桌面 / 模拟器
flutter run -d chrome        # 浏览器
flutter build apk            # Android
flutter build windows        # Windows（需在 Windows 上）
```

> 项目本地不附带 `windows/` 与 `web/` 平台目录；构建时由 CI 自动生成。
> 本地想构建时先执行 `flutter create --platforms=windows,web --project-name flutter_tetris .`。

构建 Web 版（`--base-href` 需与线上路径一致，否则资源 404）：

```bash
flutter build web --release --base-href /flutter-tetris/v0.8.0/
```

### 平台能力隔离

`dart:io`、`path_provider`、`window_manager` 只出现在 `*_io.dart` 实现中，
调用方统一通过条件导入的文件访问：

| 入口 | IO 实现 | Web 实现 |
|------|---------|----------|
| `services/log_service.dart` | 按天落盘 + 轮转 | 内存环形缓冲 |
| `services/logging_init.dart` | 用日志目录初始化 | 仅初始化内存日志 |
| `services/file_system_service.dart` | 目录解析 + 打开资源管理器 | 返回空路径 / false |
| `services/history_service.dart` | JSON 文件 | SharedPreferences |
| `utils/window_setup.dart` | Windows 窗口尺寸与居中 | 空实现 |

## 技术栈

- Flutter 3.47.7, Material 3（Android / Windows / Web）
- provider（状态管理）
- shared_preferences（最高分与 Web 历史记录）
- audioplayers（音效与背景音乐）
- window_manager（Windows 窗口控制，仅 IO 实现引用）
- 条件导入隔离平台能力：`dart:io` / `path_provider` / `window_manager` 只进 `_io` 实现
- GitHub Pages 多版本站点：每个 tag 一个子目录，根目录自动生成版本索引

## 版本历史

- **v0.8.x（Web 支持轮次，未升版本号）**：新增 Web 平台与条件导入（日志、文件系统、历史记录、窗口初始化）、GitHub Pages 多版本站点与 Gitea Web ZIP 产物；棋盘网格与外边框烘焙为 `Picture`；暂停/结算停掉 Flame 主循环；新增按平台自适应的操作提示。
- **v0.8.x**：画布铺满整页 + 全屏手势；棋盘严格居中并新增外边框。
- **v0.7.1**：渲染性能优化。`GamePage` 移除包住 `Scaffold` 的 `Consumer`，AppBar、横竖屏布局、信息面板与控制区各自订阅，棋盘 `GameWidget` 不再随每次下落/按键重建。
- **v0.7.x**：迁移到 Flame 引擎。棋盘改为固定分辨率 World + 组件化渲染，自动下落与限时倒计时改由 `FlameGame.update` 驱动，新增消行横闪、落块碎屑、结束红闪与相机抖动。
- **v0.6.x**：首页与设置页。新增应用入口首页（开始游戏/选择模式/排行榜/主题切换/设置入口，展示最高分、当前模式与操控方式），设置页集中管理外观、音效与操控方式；新增操控方式切换（手势 + 虚拟按键 / 仅虚拟按键 / 仅手势）与棋盘手势层；界面重构为自适应紧凑布局，移除独立音效菜单；换用 T 形方块自适应启动图标。
- **v0.5.x**：多种游戏模式。经典模式（无限挑战）、限时模式（120 秒内获高分）、挑战模式（最快消除 40 行），模式选择页面，模式特有 UI 信息展示；构建配置整改（对齐姊妹项目基线），移除不稳定的版本号断言用例。
- **v0.4.x**：排行榜/历史记录（按分数降序排列、清空历史），重构优化（提取公共布局组件、合并重复代码、提取测试工具、拆分主题方法）。
- **v0.3.x**：音效与背景音乐（程序化生成 WAV），重构优化（提取 StatusOverlay/SoundMenu 独立 widget，消除重复代码）。
- **v0.1.x – v0.2.x**：早期版本。经典俄罗斯方块核心玩法（7 种方块、下一个方块与 Ghost piece 预览、分数系统、暂停/继续、自适应布局、浅色/深色主题、日志系统、CI/CD 自动出包）；触屏手势与键盘快捷键操作；提取独立 widget，消除重复代码，补充测试覆盖。

更多详情见 [plan.md](./plan.md)。

## 许可

详见 [LICENSE](./LICENSE)。
