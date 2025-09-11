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
    this.selectedModelName,
  });

  final UserProfilePB userProfile;
  final String? initialText;
  final AIModelPB? selectedModel;
  final String? selectedModelName;

  @override
  State<StandaloneAiChatPage> createState() => _StandaloneAiChatPageState();
}

class _StandaloneAiChatPageState extends State<StandaloneAiChatPage> {
  bool _isInitialized = false;
  bool _showWelcomePage = true; // 控制是否显示欢迎页面
  StandaloneChatBloc? _chatBloc;
  
  // 存储从欢迎页面传递过来的消息和模型
  String? _pendingMessage;
  AIProvider? _pendingProvider;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _chatBloc?.close();
    super.dispose();
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
    }
  }

  /// 设置选中的模型
  void _setSelectedModel(StandaloneChatBloc chatBloc) {
    if (!mounted) return;
    
    String? modelName;
    
    // 优先使用selectedModelName（从HomePage传递过来的）
    if (widget.selectedModelName != null) {
      modelName = widget.selectedModelName!.toLowerCase();
    } else if (widget.selectedModel != null) {
      modelName = widget.selectedModel!.name.toLowerCase();
    } else {
      return;
    }

    try {
      AIProvider? provider;
      
      if (modelName.contains('deepseek')) {
        provider = AIProvider.deepseek;
      } else if (modelName.contains('qwen') || modelName.contains('通义')) {
        provider = AIProvider.qwen;
      } else if (modelName.contains('doubao') || modelName.contains('豆包')) {
        provider = AIProvider.doubao;
      }

      if (provider != null) {
        chatBloc.add(StandaloneChatEvent.changeProvider(provider: provider));
      }
    } catch (e) {
      debugPrint('设置选中模型失败: $e');
    }
  }

  /// 发送初始消息
  void _sendInitialMessage(StandaloneChatBloc chatBloc) {
    if (!mounted || widget.initialText == null || widget.initialText!.isEmpty) {
      return;
    }

    try {
      chatBloc.add(StandaloneChatEvent.sendMessage(
        message: widget.initialText!,
      ));
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('发送初始消息时出错: $e');
    }
  }

  /// 从欢迎页面切换到聊天界面
  void _switchToChatPage(String message, AIProvider? provider) {
    debugPrint('🔄🔄🔄 _switchToChatPage 被调用！消息: "$message", 提供商: ${provider?.displayName}');
    // 存储要发送的消息和模型
    _pendingMessage = message;
    _pendingProvider = provider;
    
    setState(() {
      _showWelcomePage = false;
    });
    
    // 切换后立即发送消息
    if (_chatBloc != null) {
      _sendPendingMessage();
    }
  }
  
  /// 发送待处理的消息
  void _sendPendingMessage() {
    debugPrint('📤📤📤 _sendPendingMessage 被调用！待发送消息: "$_pendingMessage", 提供商: ${_pendingProvider?.displayName}');
    if (_pendingMessage == null || _pendingMessage!.isEmpty) return;
    
    try {
      // 如果有指定的提供商，先切换提供商
      if (_pendingProvider != null) {
        _chatBloc!.add(StandaloneChatEvent.changeProvider(provider: _pendingProvider!));
      }
      
      // 发送消息
      _chatBloc!.add(StandaloneChatEvent.sendMessage(
        message: _pendingMessage!,
        provider: _pendingProvider,
      ));
      
      // 清空待处理的消息
      _pendingMessage = null;
      _pendingProvider = null;
    } catch (e) {
      debugPrint('发送待处理消息时出错: $e');
    }
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
      create: (context) {
        _chatBloc = StandaloneChatBloc()..add(const StandaloneChatEvent.loadHistory());
        
        // 在BlocProvider创建后处理初始设置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatBloc != null) {
            // 如果有选中的模型，先设置模型
            if (widget.selectedModel != null || widget.selectedModelName != null) {
              _setSelectedModel(_chatBloc!);
            }
            
            // 如果有初始文本，在初始化完成后发送
            if (widget.initialText != null && widget.initialText!.isNotEmpty) {
              _sendInitialMessage(_chatBloc!);
            }
            
            // 如果有待处理的消息（从欢迎页面传递过来的），发送它
            if (_pendingMessage != null) {
              _sendPendingMessage();
            }
          }
        });
        
        return _chatBloc!;
      },
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
