# 俄罗斯方块 — 项目规划

## 长期目标
- 跨 Android + Windows 双平台的俄罗斯方块游戏
- 精美克制的界面，操作与主流游戏一致
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [x] 经典俄罗斯方块核心玩法（7 种方块、旋转、移动、硬降）
- [x] 分数系统（消行计分、等级递增、最高分记录）
- [x] Ghost piece 预览（硬降落点提示）
- [x] 下一个方块预览
- [x] 暂停/继续
- [x] 游戏结束检测与重新开始
- [x] 日志系统（按日落盘到用户目录 logs/）
- [x] 浅色/深色主题
- [x] 自适应布局（竖屏/横屏、手机/平板/折叠屏）
- [x] 触屏手势操作（滑动移动、点击旋转）
- [x] 键盘快捷键支持（Windows 桌面端）
- [x] 音效与背景音乐
- [ ] 排行榜/历史记录
- [ ] 多种游戏模式（限时、挑战）

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.3.2 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 重构优化存量代码，消除重复，提升可维护性
- **任务**:
  - [x] 提取 portrait/landscape 中重复的 _restartButton/_pausedText 为共享 StatusOverlay widget
  - [x] 提取 game_page.dart 中 _buildSoundMenu 为独立 SoundMenu widget
  - [x] 清理 sound_service.dart 中 WAV 生成的魔法数字
  - [x] 添加 const 构造函数、清理冗余代码
  - [x] 补充测试用例
  - [x] 更新版本号至 0.3.2
  - [x] 更新 README

### v0.3.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 修复 CI 测试失败 — sound_service_test 缺少 FlutterBinding 初始化
- **任务**:
  - [x] 修复 sound_service_test.dart：添加 TestWidgetsFlutterBinding.ensureInitialized()
  - [x] 更新版本号至 0.3.1
  - [x] 更新 README

### v0.3.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 音效与背景音乐
- **任务**:
  - [x] 添加 audioplayers 依赖
  - [x] 实现 SoundService：程序化生成音效（移动/旋转/硬降/消行/升级/游戏结束）
  - [x] 实现背景音乐循环播放
  - [x] 集成音效到 GameProvider 各操作
  - [x] 添加音效/音乐开关 UI 控件
  - [x] 音效偏好持久化（SharedPreferences）
  - [x] 补充测试用例
  - [x] 代码审查与清理
  - [x] 更新 README

### v0.2.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 重构优化存量代码，提升可维护性
- **任务**:
  - [x] 提取 game_page.dart 中横屏/竖屏布局为独立 widget 文件
  - [x] 精简 app_theme.dart 亮/暗主题重复代码
  - [x] 拆分 game_state.dart 中 _lockPiece 长方法
  - [x] 补充测试用例覆盖
  - [x] 代码审查与清理
  - [x] 更新 README

### v0.2.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 触屏手势操作 + 键盘快捷键支持
- **任务**:
  - [x] 触屏手势操作：滑动移动（左右滑动平移方块，下滑硬降）、点击旋转
  - [x] 键盘快捷键支持：方向键移动/旋转、空格硬降、P 暂停、R 重新开始
  - [x] 更新版本号至 0.2.0
  - [x] 补充测试用例
  - [x] 代码审查与清理
  - [x] 更新 README

### v0.1.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 重构优化存量代码，提升可维护性
- **任务**:
  - [x] 提取 NextPiecePainter 到独立文件
  - [x] 提取 ScorePanel、Controls 为独立 widget
  - [x] 消除 GameProvider 中重复的游戏结束处理代码
  - [x] 精简 game_page.dart 布局代码
  - [x] 补充测试用例覆盖
  - [x] 代码审查与清理

### v0.1.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 首个版本：俄罗斯方块最小可用集
- **任务**:
  - [x] 项目脚手架（pubspec/analysis_options/.gitignore）
  - [x] Android 平台文件（manifest、build.gradle、签名、minSdk=34/targetSdk=36/compileSdk=36）
  - [x] 主题（Material 3 浅/深色、Windows YaHei UI）
  - [x] 数据模型 Tetromino（7 种方块、旋转）
  - [x] 游戏状态 GameState（棋盘、碰撞检测、消行、计分）
  - [x] 状态管理 GameProvider（定时下落、操作接口）
  - [x] 界面：游戏面板 + 分数面板 + 下一个预览 + 方向控制按钮
  - [x] Ghost piece 硬降预览
  - [x] 暂停/继续 + 游戏结束/重新开始
  - [x] 自适应布局（竖屏/横屏）
  - [x] 日志服务
  - [x] 单元测试：Tetromino、GameState、Constants
  - [x] GitHub Actions：lint + 单测 + Android APK + Windows ZIP + tag 自动 release
  - [x] README/plan

---

## 设计原则
- **离线优先**：无需网络连接即可游玩。
- **克制设计**：界面简洁，操作直观。
- **可观测**：所有关键操作写入日志文件，方便排障。
- **包体克制**：依赖均为成熟稳定的纯 Dart / Flutter 插件。

## 依赖与版本基线
- Flutter: 3.44.1
- provider: 6.1.5+1
- shared_preferences: 2.5.5
- path_provider: 2.1.5
- path: 1.9.1
- window_manager: 0.5.1
