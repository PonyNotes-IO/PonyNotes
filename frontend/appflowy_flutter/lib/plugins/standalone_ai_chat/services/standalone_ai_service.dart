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
      final config = _configService.getConfigForProvider(provider);
      if (config == null) {
        onError('AI配置未找到，请先配置${provider.displayName}');
        return;
      }

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
        default:
          onError('不支持的AI提供商: ${provider.displayName}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model ?? 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'stream': true,
        }),
      );

      if (response.statusCode == 200) {
        // 处理流式响应
        await _handleStreamResponse(response, onResponse, onError);
      } else {
        onError('DeepSeek API调用失败: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
          'X-DashScope-SSE': 'enable',
        },
        body: jsonEncode({
          'model': config.model ?? 'qwen-turbo',
          'input': {
            'messages': [
              {'role': 'user', 'content': message}
            ]
          },
          'parameters': {
            'incremental_output': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        await _handleStreamResponse(response, onResponse, onError);
      } else {
        onError('通义千问API调用失败: ${response.statusCode}');
      }
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
      final response = await http.post(
        Uri.parse('https://ark.cn-beijing.volces.com/api/v3/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model ?? 'ep-20241211205710-8dr2h',
          'messages': [
            {'role': 'user', 'content': message}
          ],
          'stream': true,
        }),
      );

      if (response.statusCode == 200) {
        await _handleStreamResponse(response, onResponse, onError);
      } else {
        onError('豆包API调用失败: ${response.statusCode}');
      }
    } catch (e) {
      onError('豆包API调用异常: $e');
    }
  }

  /// 处理流式响应
  Future<void> _handleStreamResponse(
    http.Response response,
    Function(String) onResponse,
    Function(String) onError,
  ) async {
    try {
      final lines = response.body.split('\n');
      String fullResponse = '';

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          
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

      if (fullResponse.isEmpty) {
        // 如果没有流式数据，尝试解析完整响应
        try {
          final json = jsonDecode(response.body);
          final content = json['choices']?[0]?['message']?['content'];
          if (content != null && content is String) {
            onResponse(content);
          } else {
            onError('AI响应格式错误');
          }
        } catch (e) {
          onError('解析AI响应失败: $e');
        }
      }
    } catch (e) {
      onError('处理流式响应失败: $e');
    }
  }

  /// 检查AI服务可用性
  Future<bool> checkServiceAvailability(AIProvider provider) async {
    try {
      final config = _configService.getConfigForProvider(provider);
      if (config == null) return false;

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
      default:
        return [];
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
      default:
        return false;
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