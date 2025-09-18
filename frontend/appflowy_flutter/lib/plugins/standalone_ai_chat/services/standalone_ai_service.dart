import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:appflowy/core/config/ai_config.dart';
import 'package:appflowy/plugins/standalone_ai_chat/models/chat_image.dart';
import 'package:appflowy/plugins/standalone_ai_chat/services/image_service.dart';

/// 独立AI服务，专门为StandaloneAiChatPage提供第三方AI调用
/// 支持DeepSeek、通义千问、豆包等多种AI服务
class StandaloneAiService {
  static final StandaloneAiService _instance = StandaloneAiService._internal();
  factory StandaloneAiService() => _instance;
  StandaloneAiService._internal();

  static StandaloneAiService get instance => _instance;

  final AIConfigService _configService = AIConfigService.instance;
  
  // 当前的HTTP客户端，用于取消请求
  http.Client? _currentClient;

  /// 取消当前的AI请求
  void cancelCurrentRequest() {
    debugPrint('🛑 取消当前AI请求');
    _currentClient?.close();
    _currentClient = null;
  }

  /// 发送消息到AI服务（支持多模态）
  /// 
  /// [message] 用户输入的消息
  /// [provider] AI提供商
  /// [onResponse] 响应回调，支持流式响应
  /// [onError] 错误回调
  /// [images] 可选的图片列表，支持多模态对话
  Future<void> sendMessage({
    required String message,
    required AIProvider provider,
    required Function(String) onResponse,
    required Function(String) onError,
    Function()? onComplete,
    List<ChatImage>? images,
  }) async {
    try {
      print('🚀 开始发送AI请求: $message, 提供商: ${provider.displayName}');
      final config = _configService.getConfigForProvider(provider);
      print('📋 获取到配置: API Base: ${config.apiBase}, Model: ${config.model}');

      switch (provider) {
        case AIProvider.deepseek:
          await _callDeepSeekAPI(message, config, onResponse, onError, onComplete, images);
          break;
        case AIProvider.qwen:
          await _callQwenAPI(message, config, onResponse, onError, onComplete, images);
          break;
        case AIProvider.doubao:
          await _callDoubaoAPI(message, config, onResponse, onError, onComplete, images);
          break;
      }
    } catch (e) {
      print('❌ AI服务发送消息失败: $e');
      onError('发送消息失败: $e');
    }
  }

  /// 调用DeepSeek API
  Future<void> _callDeepSeekAPI(
    String message,
    AIConfig config,
    Function(String) onResponse,
    Function(String) onError,
    Function()? onComplete,
    List<ChatImage>? images,
  ) async {
    try {
      print('🔗 开始调用DeepSeek API');
      _currentClient = http.Client();
      final client = _currentClient!;
      final apiUrl = '${config.apiBase}/chat/completions'; // 添加chat/completions端点
      print('🌐 API URL: $apiUrl');
      print('🔑 API密钥: ${config.apiKey.substring(0, 10)}... (已截断显示)');
      
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}', // 使用完整的API密钥
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      // 构建多模态消息内容
      final messageContent = await _buildMessageContent(message, images);
      
      final requestBody = {
        'model': config.model,  // 使用配置中的模型
        'messages': [
          {'role': 'user', 'content': messageContent}
        ],
        'stream': true,
      };
      
      request.body = jsonEncode(requestBody);
      print('📤 发送请求体: ${jsonEncode(requestBody)}');

      final streamedResponse = await client.send(request);
      print('📥 收到响应状态码: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        print('✅ DeepSeek API响应成功，开始处理流式响应');
        // 处理流式响应
        await _handleStreamedResponse(streamedResponse, onResponse, onError, onComplete);
        print('✅ DeepSeek API流式响应处理完成');
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        print('❌ DeepSeek API调用失败: ${streamedResponse.statusCode}, $responseBody');
        onError('DeepSeek API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
      _currentClient = null;
      print('✅ DeepSeek API调用方法结束');
    } catch (e) {
      print('❌ DeepSeek API调用异常: $e');
      onError('DeepSeek API调用异常: $e');
    }
  }

  /// 调用通义千问API
  Future<void> _callQwenAPI(
    String message,
    AIConfig config,
    Function(String) onResponse,
    Function(String) onError,
    Function()? onComplete,
    List<ChatImage>? images,
  ) async {
    try {
      _currentClient = http.Client();
      final client = _currentClient!;
      // 通义千问使用兼容模式的API端点
      final apiUrl = config.apiBase.contains('compatible-mode') 
          ? '${config.apiBase}/chat/completions'
          : 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
      // 构建多模态消息内容
      final messageContent = await _buildMessageContent(message, images);
      
      // 根据是否使用兼容模式设置不同的请求头和请求体
      final isCompatibleMode = config.apiBase.contains('compatible-mode');
      
      if (isCompatibleMode) {
        // 兼容模式：使用OpenAI格式
        request.headers.addAll({
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        });
        
        request.body = jsonEncode({
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': messageContent}
          ],
          'stream': true,
        });
      } else {
        // 原生模式：使用DashScope格式
        request.headers.addAll({
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
          'X-DashScope-SSE': 'enable',
          'Accept': 'text/event-stream',
        });
        
        request.body = jsonEncode({
          'model': config.model,
          'input': {
            'messages': [
              {'role': 'user', 'content': messageContent}
            ]
          },
          'parameters': {
            'incremental_output': true,
          },
        });
      }

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        await _handleStreamedResponse(streamedResponse, onResponse, onError, onComplete);
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        onError('通义千问API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
      _currentClient = null;
    } catch (e) {
      onError('通义千问API调用异常: $e');
    }
  }

  /// 调用豆包API
  Future<void> _callDoubaoAPI(
    String message,
    AIConfig config,
    Function(String) onResponse,
    Function(String) onError,
    Function()? onComplete,
    List<ChatImage>? images,
  ) async {
    try {
      _currentClient = http.Client();
      final client = _currentClient!;
      final apiUrl = '${config.apiBase}/chat/completions'; // 添加chat/completions端点
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      // 构建多模态消息内容
      final messageContent = await _buildMessageContent(message, images);
      
      request.body = jsonEncode({
        'model': config.model,  // 使用配置中的模型
        'messages': [
          {'role': 'user', 'content': messageContent}
        ],
        'stream': true,
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        print('✅ 豆包API响应成功，开始处理流式响应');
        await _handleStreamedResponse(streamedResponse, onResponse, onError, onComplete);
        print('✅ 豆包API流式响应处理完成');
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        onError('豆包API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
      _currentClient = null;
      print('✅ 豆包API调用方法结束');
    } catch (e) {
      onError('豆包API调用异常: $e');
    }
  }

  /// 构建多模态消息内容
  Future<dynamic> _buildMessageContent(String message, List<ChatImage>? images) async {
    // 如果没有图片，返回简单的文本消息
    if (images == null || images.isEmpty) {
      return message;
    }

    // 有图片的情况下，构建多模态内容数组
    final List<Map<String, dynamic>> content = [];
    
    // 添加文本内容（如果有）
    if (message.trim().isNotEmpty) {
      content.add({
        'type': 'text',
        'text': message,
      });
    }
    
    // 添加图片内容
    final imageService = ChatImageService.instance;
    for (final image in images) {
      try {
        // 获取图片的base64编码
        final base64Data = await imageService.getImageBase64(image);
        if (base64Data != null) {
          content.add({
            'type': 'image_url',
            'image_url': {
              'url': base64Data,
            },
          });
          print('📷 添加图片到消息内容: ${image.name ?? '未知'} (${image.fileSizeFormatted})');
        }
      } catch (e) {
        print('❌ 处理图片失败: ${image.name}, 错误: $e');
        // 如果图片处理失败，添加文本描述
        content.add({
          'type': 'text',
          'text': '[图片加载失败: ${image.name ?? '未知'}]',
        });
      }
    }
    
    // 如果没有成功添加任何内容，返回原始消息
    if (content.isEmpty) {
      return message;
    }
    
    return content;
  }

  /// 处理流式响应
  Future<void> _handleStreamedResponse(
    http.StreamedResponse streamedResponse,
    Function(String) onResponse,
    Function(String) onError,
    Function()? onComplete,
  ) async {
    String fullResponse = '';
    String buffer = '';
    bool isCompleted = false; // 防止重复调用onComplete
    
    try {

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        
        // 保留最后一行（可能不完整）
        buffer = lines.last;
        
        // 处理完整的行
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          print('🔍 处理行: "$line"');
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            print('📋 数据内容: "$data"');
            if (data == '[DONE]' || data.isEmpty) {
              print('✅ 收到流结束信号: "$data"');
              if (!isCompleted) {
                print('🎯 调用onComplete回调');
                isCompleted = true;
                onComplete?.call();
              }
              return;
            }
            
            try {
              final json = jsonDecode(data);
              print('🔄 解析JSON: $json');
              
              // 尝试多种可能的内容路径
              String? content;
              if (json['choices'] != null && json['choices'].isNotEmpty) {
                final choice = json['choices'][0];
                content = choice['delta']?['content'] ?? choice['message']?['content'];
              }
              
              // 检查是否有finish_reason表示结束
              if (json['choices'] != null && json['choices'].isNotEmpty) {
                final finishReason = json['choices'][0]['finish_reason'];
                if (finishReason != null && finishReason != 'null') {
                  print('✅ 收到完成原因: $finishReason');
                  if (content != null && content.isNotEmpty) {
                    fullResponse += content;
                    onResponse(content);
                  }
                  if (!isCompleted) {
                    print('🎯 调用onComplete回调（finish_reason）');
                    isCompleted = true;
                    onComplete?.call();
                  }
                  return; // 流结束
                }
              }
              
              if (content != null && content.isNotEmpty) {
                print('📨 收到内容片段: "$content" (长度: ${content.length})');
                fullResponse += content;
                print('📝 累积响应长度: ${fullResponse.length}');
                onResponse(content); // 只发送新的内容片段，不是完整响应
              }
            } catch (e) {
              print('❌ JSON解析错误: $e, 数据: "$data"');
              // 忽略JSON解析错误，继续处理下一行
              continue;
            }
          }
        }
      }
      
      print('🏁 流式响应循环结束，总响应长度: ${fullResponse.length}');

      // 处理剩余的buffer
      if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
        final data = buffer.substring(6).trim();
        print('📋 处理剩余数据: "$data"');
        if (data != '[DONE]' && data.isNotEmpty) {
          try {
            final json = jsonDecode(data);
            // 尝试多种可能的内容路径
            String? content;
            if (json['choices'] != null && json['choices'].isNotEmpty) {
              final choice = json['choices'][0];
              content = choice['delta']?['content'] ?? choice['message']?['content'];
              
              // 检查是否有finish_reason表示结束
              final finishReason = choice['finish_reason'];
              if (finishReason != null && finishReason != 'null') {
                print('✅ 剩余buffer中收到完成原因: $finishReason');
                if (content != null && content.isNotEmpty) {
                  fullResponse += content;
                  onResponse(content);
                }
                print('🏁 流式响应完成，最终响应长度: ${fullResponse.length}');
                if (!isCompleted) {
                  print('🎯 调用onComplete回调（buffer finish_reason）');
                  isCompleted = true;
                  onComplete?.call();
                }
                return;
              }
            }
            
            if (content != null && content.isNotEmpty) {
              fullResponse += content;
              onResponse(content); // 只发送新的内容片段
            }
          } catch (e) {
            print('❌ 剩余buffer JSON解析错误: $e');
          }
        }
      }

      if (fullResponse.isEmpty) {
        onError('AI响应为空');
      } else {
        print('✅ 流式响应处理完成，总响应长度: ${fullResponse.length}');
      }
      
      // Fallback: 如果还没有调用onComplete，在这里调用
      if (!isCompleted) {
        print('🎯 Fallback调用onComplete回调');
        isCompleted = true;
        onComplete?.call();
      }
    } catch (e) {
      print('❌ 处理流式响应失败: $e');
      onError('处理流式响应失败: $e');
      // 即使出错也要调用onComplete来重置UI状态
      if (!isCompleted) {
        isCompleted = true;
        onComplete?.call();
      }
    }
    print('🏁 _handleStreamedResponse 方法结束');
  }

  /// 检查AI服务可用性
  Future<bool> checkServiceAvailability(AIProvider provider) async {
    try {
      final config = _configService.getConfigForProvider(provider);
      
      // 检查配置是否有效
      if (!config.isValid) {
        return false;
      }

      // 发送测试消息
      bool isAvailable = false;
      await sendMessage(
        message: 'Hello',
        provider: provider,
        onResponse: (response) {
          isAvailable = response.isNotEmpty;
        },
        onError: (error) {
          isAvailable = false;
        },
      );

      return isAvailable;
    } catch (e) {
      return false;
    }
  }

  /// 获取支持的模型列表
  List<String> getSupportedModels(AIProvider provider) {
    switch (provider) {
      case AIProvider.deepseek:
        return ['deepseek-chat', 'deepseek-coder'];
      case AIProvider.qwen:
        return ['qwen-turbo', 'qwen-plus', 'qwen-max'];
      case AIProvider.doubao:
        return ['ep-20241211205710-8dr2h', 'doubao-pro-4k', 'doubao-pro-32k'];
    }
  }

  /// 验证API密钥格式
  bool validateApiKey(AIProvider provider, String apiKey) {
    if (apiKey.isEmpty) return false;

    switch (provider) {
      case AIProvider.deepseek:
        return apiKey.startsWith('sk-') && apiKey.length > 20;
      case AIProvider.qwen:
        return apiKey.length > 20; // 通义千问密钥格式较灵活
      case AIProvider.doubao:
        return apiKey.length > 20; // 豆包密钥格式较灵活
    }
  }

  /// 估算消息token数量（简单估算）
  int estimateTokenCount(String message) {
    // 简单的token估算：中文按字符计算，英文按单词计算
    int chineseChars = 0;
    int englishWords = 0;

    for (int i = 0; i < message.length; i++) {
      final char = message.codeUnitAt(i);
      if (char >= 0x4e00 && char <= 0x9fff) {
        chineseChars++;
      }
    }

    englishWords = message.split(RegExp(r'\s+')).where((word) => 
      word.isNotEmpty && !RegExp(r'[\u4e00-\u9fff]').hasMatch(word)
    ).length;

    // 中文字符 ≈ 1.5 tokens，英文单词 ≈ 1.3 tokens
    return (chineseChars * 1.5 + englishWords * 1.3).round();
  }
}