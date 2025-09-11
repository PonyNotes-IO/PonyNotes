import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'application/standalone_chat_bloc.dart';
import 'presentation/ai_welcome_page.dart';
import 'presentation/standalone_chat_page.dart';

class StandaloneAiChatPage extends StatefulWidget {
  const StandaloneAiChatPage({
    super.key,
    required this.userProfile,
    this.initialText,
    this.selectedModel,
  });

  final UserProfilePB userProfile;
  final String? initialText;
  final AIModelPB? selectedModel;

  @override
  State<StandaloneAiChatPage> createState() => _StandaloneAiChatPageState();
}

class _StandaloneAiChatPageState extends State<StandaloneAiChatPage> {
  bool _isInitialized = false;
  bool _showWelcomePage = true; // 控制是否显示欢迎页面

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// 专为独立AI聊天界面设计的初始化逻辑
  Future<void> _initializeChat() async {
    // 初始化AI配置
    await AIConfigService.instance.loadConfig();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        // 如果有初始文本，直接切换到聊天界面
        _showWelcomePage = widget.initialText == null || widget.initialText!.isEmpty;
      });
      
      // 如果有选中的模型，先设置模型
      if (widget.selectedModel != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _setSelectedModel();
        });
      }
      
      // 如果有初始文本，在初始化完成后发送
      if (widget.initialText != null && widget.initialText!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendInitialMessage();
        });
      }
    }
  }

  /// 设置选中的模型
  void _setSelectedModel() {
    if (!mounted || widget.selectedModel == null) {
      return;
    }

    try {
      // 从AIModelPB转换到AIProvider
      final providerName = widget.selectedModel!.name.toLowerCase();
      AIProvider? provider;
      
      if (providerName.contains('deepseek')) {
        provider = AIProvider.deepseek;
      } else if (providerName.contains('qwen') || providerName.contains('通义')) {
        provider = AIProvider.qwen;
      } else if (providerName.contains('doubao') || providerName.contains('豆包')) {
        provider = AIProvider.doubao;
      }

      if (provider != null) {
        final chatBloc = context.read<StandaloneChatBloc>();
        chatBloc.add(StandaloneChatEvent.changeProvider(provider: provider));
      }
    } catch (e) {
      debugPrint('设置选中模型失败: $e');
    }
  }

  /// 发送初始消息
  void _sendInitialMessage() {
    if (!mounted || widget.initialText == null || widget.initialText!.isEmpty) {
      return;
    }

    try {
      final chatBloc = context.read<StandaloneChatBloc>();
      chatBloc.add(StandaloneChatEvent.sendMessage(
        message: widget.initialText!,
      ));
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('发送初始消息时出错: $e');
    }
  }

  /// 从欢迎页面切换到聊天界面
  void _switchToChatPage() {
    setState(() {
      _showWelcomePage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BlocProvider(
      create: (_) => StandaloneChatBloc()..add(const StandaloneChatEvent.loadHistory()),
      child: Builder(
        builder: (context) {
          // 根据状态显示欢迎页面或聊天页面
          if (_showWelcomePage) {
            return AIWelcomePage(
              onMessageSent: _switchToChatPage,
            );
          }

          return StandaloneChatPageView(
            userProfile: widget.userProfile,
          );
        },
      ),
    );
  }
}
