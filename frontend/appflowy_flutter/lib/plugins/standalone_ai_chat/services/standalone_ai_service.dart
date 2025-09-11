import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:appflowy/core/config/ai_config.dart';

/// 独立AI服务，专门为StandaloneAiChatPage提供第三方AI调用
/// 支持DeepSeek、通义千问、豆包等多种AI服务
class StandaloneAiService {
  static final StandaloneAiService _instance = StandaloneAiService._internal();
  factory StandaloneAiService() => _instance;
  StandaloneAiService._internal();

  static StandaloneAiService get instance => _instance;

  final AIConfigService _configService = AIConfigService.instance;

  /// 发送消息到AI服务
  /// 
  /// [message] 用户输入的消息
  /// [provider] AI提供商
  /// [onResponse] 响应回调，支持流式响应
  /// [onError] 错误回调
  Future<void> sendMessage({
    required String message,
    required AIProvider provider,
    required Function(String) onResponse,
    required Function(String) onError,
  }) async {
    try {
      print('🚀 开始发送AI请求: $message, 提供商: ${provider.displayName}');
      final config = _configService.getConfigForProvider(provider);
      print('📋 获取到配置: API Base: ${config.apiBase}, Model: ${config.model}');

      switch (provider) {
        case AIProvider.deepseek:
          await _callDeepSeekAPI(message, config, onResponse, onError);
          break;
        case AIProvider.qwen:
          await _callQwenAPI(message, config, onResponse, onError);
          break;
        case AIProvider.doubao:
          await _callDoubaoAPI(message, config, onResponse, onError);
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
  ) async {
    try {
      print('🔗 开始调用DeepSeek API');
      final client = http.Client();
      final apiUrl = '${config.apiBase}/chat/completions';
      print('🌐 API URL: $apiUrl');
      
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer ${config.apiKey.substring(0, 10)}...', // 只显示前10位，保护API密钥
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      final requestBody = {
        'model': config.model,  // 使用配置中的模型
        'messages': [
          {'role': 'user', 'content': message}
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
        await _handleStreamedResponse(streamedResponse, onResponse, onError);
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        print('❌ DeepSeek API调用失败: ${streamedResponse.statusCode}, $responseBody');
        onError('DeepSeek API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
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
  ) async {
    try {
      final client = http.Client();
      // 通义千问使用兼容模式的API端点
      final apiUrl = config.apiBase.contains('compatible-mode') 
          ? '${config.apiBase}/chat/completions'
          : 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
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
            {'role': 'user', 'content': message}
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
              {'role': 'user', 'content': message}
            ]
          },
          'parameters': {
            'incremental_output': true,
          },
        });
      }

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        await _handleStreamedResponse(streamedResponse, onResponse, onError);
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        onError('通义千问API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
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
  ) async {
    try {
      final client = http.Client();
      final apiUrl = '${config.apiBase}/chat/completions';
      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      
      request.body = jsonEncode({
        'model': config.model,  // 使用配置中的模型
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'stream': true,
      });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        await _handleStreamedResponse(streamedResponse, onResponse, onError);
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        onError('豆包API调用失败: ${streamedResponse.statusCode}, $responseBody');
      }
      
      client.close();
    } catch (e) {
      onError('豆包API调用异常: $e');
    }
  }

  /// 处理流式响应
  Future<void> _handleStreamedResponse(
    http.StreamedResponse streamedResponse,
    Function(String) onResponse,
    Function(String) onError,
  ) async {
    try {
      String fullResponse = '';
      String buffer = '';

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        
        // 保留最后一行（可能不完整）
        buffer = lines.last;
        
        // 处理完整的行
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }
            
            try {
              final json = jsonDecode(data);
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null && content is String) {
                fullResponse += content;
                onResponse(fullResponse);
              }
            } catch (e) {
              // 忽略JSON解析错误，继续处理下一行
              continue;
            }
          }
        }
      }

      // 处理剩余的buffer
      if (buffer.isNotEmpty && buffer.startsWith('data: ')) {
        final data = buffer.substring(6).trim();
        if (data != '[DONE]') {
          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            if (content != null && content is String) {
              fullResponse += content;
              onResponse(fullResponse);
            }
          } catch (e) {
            // 忽略JSON解析错误
          }
        }
      }

      if (fullResponse.isEmpty) {
        onError('AI响应为空');
      }
    } catch (e) {
      onError('处理流式响应失败: $e');
    }
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