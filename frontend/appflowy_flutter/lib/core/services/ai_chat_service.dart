import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/ai_config.dart';

/// AI聊天消息模型
class AIChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final String? id;

  const AIChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.id,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory AIChatMessage.fromJson(Map<String, dynamic> json) => AIChatMessage(
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    timestamp: DateTime.now(),
    id: json['id'],
  );

  AIChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    String? id,
  }) => AIChatMessage(
    role: role ?? this.role,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    id: id ?? this.id,
  );
}

/// AI聊天响应模型
class AIChatResponse {
  final String content;
  final bool isComplete;
  final String? error;
  final Map<String, dynamic>? metadata;

  const AIChatResponse({
    required this.content,
    this.isComplete = true,
    this.error,
    this.metadata,
  });

  bool get hasError => error != null;
}

/// AI聊天服务
class AIChatService {
  static AIChatService? _instance;
  static AIChatService get instance => _instance ??= AIChatService._();
  AIChatService._();

  final AIConfigService _configService = AIConfigService.instance;
  http.Client? _httpClient;

  /// 初始化服务
  Future<void> initialize() async {
    await _configService.loadConfig();
    
    // 创建配置了连接设置的HTTP客户端
    final httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 30);
    httpClient.idleTimeout = const Duration(seconds: 60);
    _httpClient = IOClient(httpClient);
  }

  /// 释放资源
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }

  /// 发送聊天消息
  Future<AIChatResponse> sendMessage({
    required String message,
    List<AIChatMessage>? conversationHistory,
    AIProvider? provider,
  }) async {
    try {
      final targetProvider = provider ?? _configService.currentProvider;
      final config = _configService.getConfigForProvider(targetProvider);

      if (!config.isValid) {
        return AIChatResponse(
          content: '',
          error: '❌ ${targetProvider.displayName} API密钥无效，请检查配置文件',
        );
      }

      final messages = <AIChatMessage>[
        if (conversationHistory != null) ...conversationHistory,
        AIChatMessage(
          role: 'user',
          content: message,
          timestamp: DateTime.now(),
        ),
      ];

      if (config.streamEnabled) {
        return await _sendStreamMessage(config, messages, targetProvider);
      } else {
        return await _sendNormalMessage(config, messages, targetProvider);
      }
    } catch (e) {
      debugPrint('❌ AI聊天服务错误: $e');
      return AIChatResponse(
        content: '',
        error: '发送消息失败: $e',
      );
    }
  }

  /// 发送普通消息
  Future<AIChatResponse> _sendNormalMessage(
    AIConfig config,
    List<AIChatMessage> messages,
    AIProvider provider,
  ) async {
    final headers = _buildHeaders(config, provider);
    final body = _buildRequestBody(config, messages);

    debugPrint('🚀 发送请求到 ${provider.displayName}: ${config.apiBase}/chat/completions');

    // 添加重试机制
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final response = await _httpClient!.post(
          Uri.parse('${config.apiBase}/chat/completions'),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          final content = responseData['choices']?[0]?['message']?['content'] ?? '';
          
          debugPrint('✅ ${provider.displayName} 响应成功');
          
          return AIChatResponse(
            content: content,
            metadata: {
              'provider': provider.displayName,
              'model': config.modelName,
              'usage': responseData['usage'],
            },
          );
        } else {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          final errorMessage = errorData['error']?['message'] ?? '未知错误';
          
          debugPrint('❌ ${provider.displayName} 请求失败: ${response.statusCode} - $errorMessage');
          
          // 如果是服务器错误且还有重试次数，则重试
          if (response.statusCode >= 500 && retryCount < maxRetries - 1) {
            retryCount++;
            debugPrint('🔄 ${provider.displayName} 重试第 $retryCount 次...');
            await Future.delayed(Duration(milliseconds: 1000 * retryCount));
            continue;
          }
          
          return AIChatResponse(
            content: '',
            error: '${provider.displayName} 请求失败: $errorMessage',
          );
        }
      } catch (e) {
        debugPrint('❌ ${provider.displayName} 连接错误: $e');
        
        // 如果是连接错误且还有重试次数，则重试
        if (retryCount < maxRetries - 1) {
          retryCount++;
          debugPrint('🔄 ${provider.displayName} 连接重试第 $retryCount 次...');
          await Future.delayed(Duration(milliseconds: 2000 * retryCount));
          continue;
        }
        
        return AIChatResponse(
          content: '',
          error: '${provider.displayName} 连接失败: ${e.toString()}',
        );
      }
    }
    
    // 如果所有重试都失败了
    return AIChatResponse(
      content: '',
      error: '${provider.displayName} 请求失败，已重试 $maxRetries 次',
    );
  }

  /// 发送流式消息
  Future<AIChatResponse> _sendStreamMessage(
    AIConfig config,
    List<AIChatMessage> messages,
    AIProvider provider,
  ) async {
    final headers = _buildHeaders(config, provider);
    final body = _buildRequestBody(config, messages, stream: true);

    debugPrint('🌊 发送流式请求到 ${provider.displayName}');

    // 添加重试机制
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final request = http.Request('POST', Uri.parse('${config.apiBase}/chat/completions'));
        request.headers.addAll(headers);
        request.body = jsonEncode(body);

        final streamedResponse = await _httpClient!.send(request).timeout(const Duration(seconds: 90));

        if (streamedResponse.statusCode == 200) {
          final responseBuffer = StringBuffer();
          
          await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
            final lines = chunk.split('\n');
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data.trim() == '[DONE]') break;
                
                try {
                  final jsonData = jsonDecode(data);
                  final content = jsonData['choices']?[0]?['delta']?['content'];
                  if (content != null) {
                    responseBuffer.write(content);
                  }
                } catch (e) {
                  // 忽略解析错误，继续处理下一行
                }
              }
            }
          }

          final finalContent = responseBuffer.toString();
          debugPrint('✅ ${provider.displayName} 流式响应完成，长度: ${finalContent.length}');

          return AIChatResponse(
            content: finalContent,
            metadata: {
              'provider': provider.displayName,
              'model': config.modelName,
              'stream': true,
            },
          );
        } else {
          final errorResponse = await streamedResponse.stream.bytesToString();
          debugPrint('❌ ${provider.displayName} 流式请求失败: ${streamedResponse.statusCode} - $errorResponse');
          
          // 如果是服务器错误且还有重试次数，则重试
          if (streamedResponse.statusCode >= 500 && retryCount < maxRetries - 1) {
            retryCount++;
            debugPrint('🔄 ${provider.displayName} 重试第 $retryCount 次...');
            await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // 递增延迟
            continue;
          }
          
          return AIChatResponse(
            content: '',
            error: '${provider.displayName} 流式请求失败: HTTP ${streamedResponse.statusCode}',
          );
        }
      } catch (e) {
        debugPrint('❌ ${provider.displayName} 连接错误: $e');
        
        // 如果是连接错误且还有重试次数，则重试
        if (retryCount < maxRetries - 1) {
          retryCount++;
          debugPrint('🔄 ${provider.displayName} 连接重试第 $retryCount 次...');
          await Future.delayed(Duration(milliseconds: 2000 * retryCount)); // 递增延迟
          continue;
        }
        
        return AIChatResponse(
          content: '',
          error: '${provider.displayName} 连接失败: ${e.toString()}',
        );
      }
    }
    
    // 如果所有重试都失败了
    return AIChatResponse(
      content: '',
      error: '${provider.displayName} 请求失败，已重试 $maxRetries 次',
    );
  }

  /// 构建请求头
  Map<String, String> _buildHeaders(AIConfig config, AIProvider provider) {
    final headers = {
      'Content-Type': 'application/json',
      'User-Agent': 'PonyNotes-AI-Chat/1.0',
    };

    switch (provider) {
      case AIProvider.deepseek:
        headers['Authorization'] = 'Bearer ${config.apiKey}';
        break;
      case AIProvider.qwen:
        headers['Authorization'] = 'Bearer ${config.apiKey}';
        break;
      case AIProvider.doubao:
        headers['Authorization'] = 'Bearer ${config.apiKey}';
        break;
    }

    return headers;
  }

  /// 构建请求体
  Map<String, dynamic> _buildRequestBody(
    AIConfig config,
    List<AIChatMessage> messages, {
    bool stream = false,
  }) {
    return {
      'model': config.modelName,
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
      'stream': stream,
    };
  }

  /// 测试AI连接
  Future<Map<String, dynamic>> testConnection({AIProvider? provider}) async {
    final targetProvider = provider ?? _configService.currentProvider;
    final config = _configService.getConfigForProvider(targetProvider);

    if (!config.isValid) {
      return {
        'success': false,
        'provider': targetProvider.displayName,
        'error': 'API密钥无效',
      };
    }

    try {
      final response = await sendMessage(
        message: '你好，请简单回复"连接成功"来测试API连接。',
        provider: targetProvider,
      );

      return {
        'success': !response.hasError,
        'provider': targetProvider.displayName,
        'error': response.error,
        'response': response.content.substring(0, 100), // 只显示前100个字符
        'metadata': response.metadata,
      };
    } catch (e) {
      return {
        'success': false,
        'provider': targetProvider.displayName,
        'error': e.toString(),
      };
    }
  }

  /// 测试所有可用的AI提供商
  Future<List<Map<String, dynamic>>> testAllProviders() async {
    final results = <Map<String, dynamic>>[];
    final providers = _configService.getAvailableProviders();

    for (final provider in providers) {
      final result = await testConnection(provider: provider);
      results.add(result);
    }

    return results;
  }

  /// 获取服务状态
  Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': _httpClient != null,
      'configStatus': _configService.getConfigStatus(),
    };
  }
}
