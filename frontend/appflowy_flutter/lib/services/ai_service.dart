import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Stream<String>? contentStream;
  final bool isStreaming;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.contentStream,
    this.isStreaming = false,
  });

  // 创建流式消息
  Message.streaming({
    required this.contentStream,
    required this.isUser,
    required this.timestamp,
  }) : content = '',
       isStreaming = true;

  // 创建普通消息
  Message.text({
    required this.content,
    required this.isUser,
    required this.timestamp,
  }) : contentStream = null,
       isStreaming = false;
}

class AIService {
  static const Duration _timeout = Duration(seconds: 30);

  /// DeepSeek API调用
  static Future<String> callDeepSeekAPI({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
          'stream': false,
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? '无响应内容';
      } else {
        throw Exception('DeepSeek API错误: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('网络连接错误，请检查网络设置');
    } on HttpException {
      throw Exception('HTTP请求错误');
    } on FormatException {
      throw Exception('响应格式错误');
    } catch (e) {
      throw Exception('DeepSeek调用失败: $e');
    }
  }

  /// 通义千问API调用
  static Future<String> callQwenAPI({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'qwen-turbo',  // 通义千问的模型名称
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
          'stream': false,
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? '无响应内容';
      } else {
        throw Exception('通义千问API错误: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('网络连接错误，请检查网络设置');
    } on HttpException {
      throw Exception('HTTP请求错误');
    } on FormatException {
      throw Exception('响应格式错误');
    } catch (e) {
      throw Exception('通义千问调用失败: $e');
    }
  }

  /// 豆包API调用
  static Future<String> callDoubaoAPI({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
          'stream': false,
          'max_tokens': 2000,
          'temperature': 0.7,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? '无响应内容';
      } else {
        throw Exception('豆包API错误: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('网络连接错误，请检查网络设置');
    } on HttpException {
      throw Exception('HTTP请求错误');
    } on FormatException {
      throw Exception('响应格式错误');
    } catch (e) {
      throw Exception('豆包调用失败: $e');
    }
  }

  /// 通用AI调用方法
  static Future<String> callAI({
    required String modelName,
    required String message,
    required Map<String, String> modelConfig,
  }) async {
    final apiKey = modelConfig['apiKey']!;
    final apiBase = modelConfig['apiBase']!;
    final modelNameFromConfig = modelConfig['modelName']!;

    switch (modelName) {
      case 'DeepSeek R1 V3':
        return await callDeepSeekAPI(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      case '通义千问':
        return await callQwenAPI(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      case '豆包':
        return await callDoubaoAPI(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      default:
        throw Exception('不支持的AI模型: $modelName');
    }
  }

  /// 流式AI调用方法
  static Stream<String> callAIStream({
    required String modelName,
    required String message,
    required Map<String, String> modelConfig,
  }) {
    final apiKey = modelConfig['apiKey']!;
    final apiBase = modelConfig['apiBase']!;
    final modelNameFromConfig = modelConfig['modelName']!;

    switch (modelName) {
      case 'DeepSeek R1 V3':
        return callDeepSeekAPIStream(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      case '通义千问':
        return callQwenAPIStream(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      case '豆包':
        return callDoubaoAPIStream(
          message: message,
          apiKey: apiKey,
          apiBase: apiBase,
          modelName: modelNameFromConfig,
        );
      default:
        throw Exception('不支持的AI模型: $modelName');
    }
  }

  /// DeepSeek流式API调用
  static Stream<String> callDeepSeekAPIStream({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async* {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      
      request.body = jsonEncode({
        'model': modelName,
        'messages': [
          {
            'role': 'user',
            'content': message,
          }
        ],
        'stream': true,
        'max_tokens': 2000,
        'temperature': 0.7,
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ') && !line.contains('[DONE]')) {
              final jsonStr = line.substring(6);
              try {
                final data = jsonDecode(jsonStr);
                final content = data['choices']?[0]?['delta']?['content'];
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              } catch (e) {
                // 忽略解析错误，继续处理下一行
              }
            }
          }
        }
      } else {
        throw Exception('DeepSeek流式API错误: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      throw Exception('DeepSeek流式调用失败: $e');
    }
  }

  /// 通义千问流式API调用
  static Stream<String> callQwenAPIStream({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async* {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      
      request.body = jsonEncode({
        'model': 'qwen-turbo',
        'messages': [
          {
            'role': 'user',
            'content': message,
          }
        ],
        'stream': true,
        'max_tokens': 2000,
        'temperature': 0.7,
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ') && !line.contains('[DONE]')) {
              final jsonStr = line.substring(6);
              try {
                final data = jsonDecode(jsonStr);
                final content = data['choices']?[0]?['delta']?['content'];
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              } catch (e) {
                // 忽略解析错误，继续处理下一行
              }
            }
          }
        }
      } else {
        throw Exception('通义千问流式API错误: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      throw Exception('通义千问流式调用失败: $e');
    }
  }

  /// 豆包流式API调用
  static Stream<String> callDoubaoAPIStream({
    required String message,
    required String apiKey,
    required String apiBase,
    required String modelName,
  }) async* {
    try {
      final url = Uri.parse('$apiBase/chat/completions');
      
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      
      request.body = jsonEncode({
        'model': modelName,
        'messages': [
          {
            'role': 'user',
            'content': message,
          }
        ],
        'stream': true,
        'max_tokens': 2000,
        'temperature': 0.7,
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ') && !line.contains('[DONE]')) {
              final jsonStr = line.substring(6);
              try {
                final data = jsonDecode(jsonStr);
                final content = data['choices']?[0]?['delta']?['content'];
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              } catch (e) {
                // 忽略解析错误，继续处理下一行
              }
            }
          }
        }
      } else {
        throw Exception('豆包流式API错误: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      throw Exception('豆包流式调用失败: $e');
    }
  }
}
