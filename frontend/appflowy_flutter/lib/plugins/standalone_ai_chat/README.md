# 小马笔记AI聊天模块

本模块实现了基于设计图的AI聊天界面，提供了欢迎页面和聊天功能的无缝集成。

## 功能特性

### 🎨 UI设计
- **欢迎页面**: 完全基于设计图实现，包含AI头像、欢迎文本和输入区域
- **响应式设计**: 适配不同屏幕尺寸
- **主题一致性**: 使用统一的颜色、字体和尺寸规范

### 💬 聊天功能
- **消息发送**: 支持文本输入和发送
- **状态切换**: 从欢迎页面到聊天界面的平滑切换
- **AI集成**: 与现有的AI聊天BLoC完全兼容

### 🛠 技术架构
- **模块化设计**: 独立的插件架构，易于维护和扩展
- **BLoC模式**: 使用现有的ChatBloc进行状态管理
- **主题系统**: 集中化的主题配置，易于定制

## 文件结构

```
lib/plugins/standalone_ai_chat/
├── standalone_ai_chat_page.dart          # 主页面组件
├── presentation/
│   ├── ai_welcome_page.dart              # AI欢迎页面
│   ├── ai_welcome_theme.dart             # 主题配置
│   └── widgets/
│       ├── ai_welcome_header.dart        # 欢迎页面头部
│       └── ai_input_area.dart            # 输入交互区域
└── README.md                             # 本文档
```

## 核心组件

### StandaloneAiChatPage
- **作用**: 主入口组件，管理欢迎页面和聊天页面的切换
- **状态管理**: 内部状态控制页面显示
- **集成**: 与现有AI聊天功能完全兼容

### AIWelcomePage
- **作用**: AI聊天欢迎界面
- **设计**: 100%还原设计图
- **交互**: 支持消息输入和发送回调

### AIWelcomeTheme
- **作用**: 统一的主题配置
- **覆盖**: 颜色、字体、尺寸、样式等
- **基准**: 基于设计图CSS精确配置

## 设计图映射

| 设计图元素 | Flutter组件 | 说明 |
|-----------|-------------|------|
| block_1 | AIWelcomeHeader | AI头像和欢迎文本 |
| text_15 | titleStyle | 主标题样式 |
| text_16 | subtitleStyle | 副标题样式 |
| block_3 | AIInputArea | 输入交互区域 |
| text_17 | placeholderStyle | 占位文本样式 |
| group_2 | 工具栏布局 | 模型选择和功能按钮 |
| label_9 | 发送按钮 | 消息发送触发器 |

## 使用方法

### 基本用法
```dart
import 'package:appflowy/plugins/standalone_ai_chat/standalone_ai_chat_page.dart';

// 在需要的地方使用
StandaloneAiChatPage(
  userProfile: userProfile,
)
```

### 自定义主题
```dart
import 'package:appflowy/plugins/standalone_ai_chat/presentation/ai_welcome_theme.dart';

// 使用主题常量
Container(
  decoration: AIWelcomeTheme.inputContainerDecoration,
  child: Text(
    'Hello',
    style: AIWelcomeTheme.titleStyle,
  ),
)
```

## 技术要点

### 1. 状态管理
- 使用内部StatefulWidget管理页面切换
- 与现有ChatBloc无缝集成
- 支持消息发送后的状态同步

### 2. 布局适配
- 基于设计图的精确像素布局
- 支持不同屏幕尺寸的适配
- 响应式边距和尺寸调整

### 3. 主题一致性
- 集中化的主题配置
- 基于设计图的颜色和字体定义
- 易于维护和修改的样式系统

### 4. 性能优化
- 按需加载图片资源
- 高效的Widget重建策略
- 内存占用优化

## 兼容性

- ✅ Flutter 3.x
- ✅ AppFlowy现有架构
- ✅ AI聊天BLoC系统
- ✅ 多平台支持(Desktop, Mobile)

## 后续改进

### 短期目标
- [ ] 添加消息历史记录支持
- [ ] 实现更多工具栏功能
- [ ] 添加键盘快捷键支持

### 长期目标
- [ ] 支持多模态输入(语音、图片)
- [ ] 添加聊天记录搜索
- [ ] 实现个性化主题定制

## 注意事项

1. **依赖管理**: 确保相关的AI聊天依赖包已正确配置
2. **BLoC注入**: 需要在Widget树中正确注入ChatBloc
3. **资源加载**: 网络图片需要网络权限配置
4. **主题兼容**: 与全局主题系统保持一致

---

*本模块完全基于设计图实现，确保了UI的高度还原和功能的完整性。*
