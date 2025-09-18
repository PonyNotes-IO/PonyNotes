import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'application/standalone_chat_bloc.dart';
import 'models/chat_image.dart';
import 'presentation/ai_welcome_page.dart';
import 'presentation/standalone_chat_page.dart';

class StandaloneAiChatPage extends StatefulWidget {
  const StandaloneAiChatPage({
    super.key,
    required this.userProfile,
    this.initialText,
    this.selectedModel,
    this.selectedModelName,
    this.selectedProvider,
    this.initialImages,
  });

  final UserProfilePB userProfile;
  final String? initialText;
  final AIModelPB? selectedModel;
  final String? selectedModelName;
  final AIProvider? selectedProvider;
  final List<dynamic>? initialImages;

  @override
  State<StandaloneAiChatPage> createState() => _StandaloneAiChatPageState();
}

class _StandaloneAiChatPageState extends State<StandaloneAiChatPage> {
  bool _isInitialized = false;
  bool _showWelcomePage = true; // 控制是否显示欢迎页面
  StandaloneChatBloc? _chatBloc;
  
  // 存储从欢迎页面传递过来的消息、模型和图片
  String? _pendingMessage;
  AIProvider? _pendingProvider;
  List<ChatImage>? _pendingImages;

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
        // 如果有初始文本或图片，直接切换到聊天界面
        final hasInitialText = widget.initialText != null && widget.initialText!.isNotEmpty;
        final hasInitialImages = widget.initialImages != null && widget.initialImages!.isNotEmpty;
        
        debugPrint('🔍 初始化页面状态检查:');
        debugPrint('  - initialText: "${widget.initialText}"');
        debugPrint('  - initialImages: ${widget.initialImages}');
        debugPrint('  - hasInitialText: $hasInitialText');
        debugPrint('  - hasInitialImages: $hasInitialImages');
        
        _showWelcomePage = !hasInitialText && !hasInitialImages;
        debugPrint('  - _showWelcomePage: $_showWelcomePage');
      });
    }
  }

  /// 设置选中的模型
  void _setSelectedModel(StandaloneChatBloc chatBloc) {
    if (!mounted) return;
    
    AIProvider? provider;
    
    // 优先使用从主页传递过来的selectedProvider
    if (widget.selectedProvider != null) {
      provider = widget.selectedProvider;
      debugPrint('🎯 使用传递过来的提供商: ${provider!.displayName}');
    } else {
      // 回退到原有的逻辑
      String? modelName;
      
      // 优先使用selectedModelName（从HomePage传递过来的）
      if (widget.selectedModelName != null && widget.selectedModelName!.isNotEmpty) {
        modelName = widget.selectedModelName!;
      } else if (widget.selectedModel != null) {
        modelName = widget.selectedModel!.name;
      } else {
        return;
      }

      // 通过显示名称直接匹配
      for (final p in AIProvider.values) {
        if (p.displayName == modelName) {
          provider = p;
          break;
        }
      }
      
      // 如果直接匹配失败，使用模糊匹配
      if (provider == null) {
        final lowerName = modelName.toLowerCase();
        if (lowerName.contains('deepseek')) {
          provider = AIProvider.deepseek;
        } else if (lowerName.contains('qwen') || lowerName.contains('通义')) {
          provider = AIProvider.qwen;
        } else if (lowerName.contains('doubao') || lowerName.contains('豆包')) {
          provider = AIProvider.doubao;
        }
      }
    }

    try {

      if (provider != null) {
        debugPrint('✅ 设置AI提供商为: ${provider.displayName}');
        chatBloc.add(StandaloneChatEvent.changeProvider(provider: provider));
      } else {
        final modelInfo = widget.selectedModelName ?? widget.selectedModel?.name ?? 'unknown';
        debugPrint('⚠️ 无法识别模型: $modelInfo，使用默认提供商');
      }
    } catch (e) {
      debugPrint('❌ 设置选中模型失败: $e');
    }
  }

  /// 发送初始消息
  void _sendInitialMessage(StandaloneChatBloc chatBloc) {
    final hasText = widget.initialText != null && widget.initialText!.isNotEmpty;
    final hasImages = widget.initialImages != null && widget.initialImages!.isNotEmpty;
    
    if (!mounted || (!hasText && !hasImages)) {
      return;
    }

    try {
      // 转换初始图片
      final images = <ChatImage>[];
      if (hasImages) {
        for (final imageData in widget.initialImages!) {
          if (imageData is ChatImage) {
            images.add(imageData);
          }
        }
      }

      if (images.isNotEmpty) {
        debugPrint('📤📷 发送带图片的初始消息: 文本="${widget.initialText ?? ""}", 图片数量=${images.length}');
        chatBloc.add(StandaloneChatEvent.sendMessageWithImages(
          message: widget.initialText ?? '',
          images: images,
        ));
      } else if (hasText) {
        debugPrint('📤 发送初始消息: ${widget.initialText}');
        chatBloc.add(StandaloneChatEvent.sendMessage(
          message: widget.initialText!,
        ));
      }
    } catch (e) {
      // 静默处理错误，不影响用户体验
      debugPrint('❌ 发送初始消息时出错: $e');
    }
  }

  /// 从欢迎页面切换到聊天界面
  void _switchToChatPage(String message, AIProvider? provider, List<ChatImage>? images) {
    debugPrint('🔄🔄🔄 _switchToChatPage 被调用！消息: "$message", 提供商: ${provider?.displayName}, 图片数量: ${images?.length ?? 0}');
    // 存储要发送的消息、模型和图片
    _pendingMessage = message;
    _pendingProvider = provider;
    _pendingImages = images;
    
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
    debugPrint('📤📤📤 _sendPendingMessage 被调用！待发送消息: "$_pendingMessage", 提供商: ${_pendingProvider?.displayName}, 图片数量: ${_pendingImages?.length ?? 0}');
    final hasMessage = _pendingMessage != null && _pendingMessage!.isNotEmpty;
    final hasImages = _pendingImages != null && _pendingImages!.isNotEmpty;
    
    if (!hasMessage && !hasImages) return;
    
    try {
      // 如果有指定的提供商，先切换提供商
      if (_pendingProvider != null) {
        _chatBloc!.add(StandaloneChatEvent.changeProvider(provider: _pendingProvider!));
      }
      
      // 发送消息（带图片或不带图片）
      if (hasImages) {
        _chatBloc!.add(StandaloneChatEvent.sendMessageWithImages(
          message: _pendingMessage ?? '',
          images: _pendingImages!,
        ));
      } else {
        _chatBloc!.add(StandaloneChatEvent.sendMessage(
          message: _pendingMessage!,
          provider: _pendingProvider,
        ));
      }
      
      // 清空待处理的消息、提供商和图片
      _pendingMessage = null;
      _pendingProvider = null;
      _pendingImages = null;
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
            
            // 如果有初始文本或图片，在初始化完成后发送
            final hasInitialText = widget.initialText != null && widget.initialText!.isNotEmpty;
            final hasInitialImages = widget.initialImages != null && widget.initialImages!.isNotEmpty;
            if (hasInitialText || hasInitialImages) {
              _sendInitialMessage(_chatBloc!);
            }
            
            // 如果有待处理的消息或图片（从欢迎页面传递过来的），发送它
            if (_pendingMessage != null || _pendingImages != null) {
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
