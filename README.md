<h1 align="center" style="border-bottom: none">
    <b>
        <a href="https://www.xiaomabiji.com">小马笔记</a><br>
    </b>
    ⭐️  开源的 Notion 替代方案  ⭐️ <br>
</h1>

<p align="center">
小马笔记是一个AI驱动的工作空间，让您在不失去数据控制权的前提下实现更多目标
</p>

<p align="center">
<a href="https://discord.gg/9Q2xaN37tV"><img src="https://img.shields.io/badge/XiaoMaBiJi-discord-orange"></a>
<a href="https://gitee.com/beijing-grimoire/xiaoma-note"><img src="https://img.shields.io/github/stars/AppFlowy-IO/appflowy.svg?style=flat&logo=github&colorB=deeppink&label=stars"></a>
<a href="https://gitee.com/beijing-grimoire/xiaoma-note"><img src="https://img.shields.io/github/forks/AppFlowy-IO/appflowy.svg"></a>
<a href="https://opensource.org/licenses/AGPL-3.0"><img src="https://img.shields.io/badge/license-AGPL-purple.svg" alt="License: AGPL"></a>
</p>

<p align="center">
    <a href="https://www.xiaomabiji.com"><b>官网</b></a> •
    <a href="https://forum.appflowy.io/"><b>论坛</b></a> •
    <a href="https://discord.gg/9Q2xaN37tV"><b>Discord</b></a> •
    <a href="https://www.reddit.com/r/AppFlowy"><b>Reddit</b></a> •
    <a href="https://twitter.com/appflowy"><b>Twitter</b></a>
</p>

## 📋 项目简介

小马笔记是一个功能强大的开源笔记和知识管理应用，基于 Flutter 和 Rust 构建。它提供了类似 Notion 的功能，但更注重数据隐私、跨平台原生体验和社区驱动的可扩展性。

### 🌟 核心特性

- **📝 富文本编辑器**: 支持 Markdown、数学公式、代码块等多种内容格式
- **🗃️ 数据库功能**: 内置表格、看板、日历等多种数据视图
- **🤖 AI 智能助手**: 集成多种 AI 模型，支持内容生成、改写、总结等功能
- **🔄 实时协作**: 支持多人实时编辑和同步
- **🔍 全文搜索**: 快速查找文档和数据内容
- **📱 跨平台支持**: 支持 Windows、macOS、Linux、iOS、Android
- **🔒 数据安全**: 本地存储优先，完全控制您的数据
- **🎨 自定义主题**: 支持明暗主题切换和个性化定制
- **🔌 插件系统**: 可扩展的插件架构

### 🏗️ 技术架构

小马笔记采用现代化的技术栈，确保高性能和跨平台兼容性：

#### 前端架构
- **Flutter**: 跨平台 UI 框架，提供原生性能体验
- **Dart**: 主要编程语言，用于业务逻辑实现
- **BLoC 模式**: 状态管理和业务逻辑分离
- **Provider**: 依赖注入和状态共享

#### 后端架构
- **Rust**: 高性能系统编程语言，负责核心业务逻辑
- **FFI (Foreign Function Interface)**: Flutter 与 Rust 的桥接层
- **SQLite**: 本地数据存储
- **Collab**: 实时协作引擎

#### AI 功能
- **多模型支持**: GPT-4o、GPT-o3-mini、DeepSeek R1、Claude 3.5 Sonnet
- **本地 AI**: 支持 Ollama 等本地模型
- **智能编辑**: 拼写检查、内容改写、自动总结
- **AI 搜索**: 智能内容检索和推荐

## 🗂️ 项目结构

```
xiaoma-note/
├── frontend/                    # 前端代码
│   ├── appflowy_flutter/       # Flutter 主应用
│   │   ├── lib/               # Dart 源代码
│   │   │   ├── plugins/       # 功能插件
│   │   │   │   ├── document/  # 文档编辑器
│   │   │   │   ├── database/  # 数据库功能
│   │   │   │   └── ai/        # AI 功能
│   │   │   ├── workspace/     # 工作空间管理
│   │   │   └── shared/        # 共享组件
│   │   ├── packages/          # Flutter 包
│   │   ├── android/           # Android 平台代码
│   │   ├── ios/              # iOS 平台代码
│   │   ├── linux/            # Linux 平台代码
│   │   ├── macos/            # macOS 平台代码
│   │   └── windows/          # Windows 平台代码
│   ├── rust-lib/              # Rust 后端库
│   │   ├── flowy-core/       # 核心业务逻辑
│   │   ├── flowy-database/   # 数据库服务
│   │   ├── flowy-document/   # 文档服务
│   │   └── dart-ffi/         # FFI 接口层
│   └── resources/             # 资源文件
│       └── translations/      # 多语言支持
├── doc/                       # 项目文档
└── scripts/                   # 构建脚本
```

## 🚀 支持平台

### 桌面平台
- **Windows** (x64)
- **macOS** (Intel & Apple Silicon)
- **Linux** (x64, ARM64)

### 移动平台
- **iOS** (iPhone & iPad)
- **Android** (API 21+)

### Web 平台
- **浏览器支持** (基于 Tauri 的 Web 版本正在开发中)

## 📦 安装使用

### 用户安装

#### 桌面版下载
- [GitHub Releases](https://gitee.com/beijing-grimoire/xiaoma-note/releases) - 下载最新版本
- [FlatHub](https://flathub.org/apps/io.appflowy.AppFlowy) - Linux 用户推荐
- [Snapcraft](https://snapcraft.io/appflowy) - Ubuntu 用户
- [Sourceforge](https://sourceforge.net/projects/appflowy/) - 镜像下载

#### 移动版下载
- **iOS**: [App Store](https://apps.apple.com/app/appflowy/id6457261352)
- **Android**: [Google Play](https://play.google.com/store/apps/details?id=io.appflowy.appflowy) (需要 Android 10+)

### 开发环境搭建

#### 系统要求
- **Flutter**: 3.27.4+
- **Rust**: 1.87.0+
- **Git**: 最新版本

#### 快速开始

1. **克隆仓库**
```bash
git clone https://gitee.com/beijing-grimoire/xiaoma-note.git
cd xiaoma-note
```

2. **安装依赖**
```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 安装 Flutter
# 请参考 Flutter 官方文档安装指南

# 安装 cargo-make
cargo install cargo-make
```

3. **构建项目**
```bash
cd frontend
# macOS
cargo make --profile development-mac-arm64 appflowy

# Windows
cargo make --profile development-windows-x86 appflowy

# Linux
cargo make --profile development-linux-x86_64 appflowy
```

4. **运行应用**
```bash
cd appflowy_flutter
flutter run
```

## 🔧 开发指南

### 代码结构说明

#### Flutter 前端
- **插件系统**: 每个功能模块都是独立的插件
- **状态管理**: 使用 BLoC 模式管理应用状态
- **主题系统**: 支持自定义主题和多语言
- **路由管理**: 基于 go_router 的声明式路由

#### Rust 后端
- **模块化设计**: 每个功能都是独立的 crate
- **异步处理**: 基于 tokio 的异步运行时
- **数据持久化**: SQLite + 自定义存储引擎
- **协作引擎**: 基于 CRDT 的实时同步

### 主要功能模块

#### 1. 文档编辑器
- 富文本编辑
- Markdown 支持
- 数学公式渲染
- 代码高亮
- 图片和媒体嵌入

#### 2. 数据库功能
- 表格视图
- 看板视图
- 日历视图
- 筛选和排序
- 关联字段

#### 3. AI 功能
- 内容生成
- 智能改写
- 自动总结
- 拼写检查
- 语法优化

#### 4. 协作功能
- 实时同步
- 冲突解决
- 版本历史
- 权限管理

## 🌐 部署方案

### 自托管部署
小马笔记支持完全自托管，您可以：
- 部署私有云服务
- 配置自定义同步服务器
- 集成企业身份认证
- 自定义数据存储位置

### 云服务
- **小马笔记云**: 官方托管服务
- **企业版**: 提供高级功能和技术支持

## 🤝 贡献指南

我们欢迎各种形式的贡献！

### 贡献方式
- **代码贡献**: 修复 bug、添加新功能
- **文档改进**: 完善文档、翻译内容
- **问题反馈**: 报告 bug、提出建议
- **社区支持**: 帮助其他用户解决问题

### 开发流程
1. Fork 项目到您的账户
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

### 代码规范
- **Dart**: 遵循 Flutter 官方代码规范
- **Rust**: 使用 rustfmt 格式化代码
- **提交信息**: 使用清晰的提交信息格式

## 🌍 国际化支持

小马笔记支持多种语言：
- 简体中文
- 繁体中文
- English
- Français
- Deutsch
- 日本語
- 한국어
- Español
- Português
- Русский
- العربية

## 📄 许可证

本项目基于 [AGPL-3.0 许可证](LICENSE) 开源。

## 🙏 致谢

感谢以下优秀的开源项目：
- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Rust](https://www.rust-lang.org/) - 系统编程语言
- [cargo-make](https://github.com/sagiegurari/cargo-make) - 构建工具
- [AppFlowy Editor](https://github.com/AppFlowy-IO/appflowy-editor) - 富文本编辑器

## 📞 联系我们

- **官网**: https://www.xiaomabiji.com
- **邮箱**: support@xiaomabiji.com
- **Discord**: https://discord.gg/9Q2xaN37tV
- **GitHub**: https://gitee.com/beijing-grimoire/xiaoma-note

---

<p align="center">
如果这个项目对您有帮助，请给我们一个 ⭐️ Star！
</p>
