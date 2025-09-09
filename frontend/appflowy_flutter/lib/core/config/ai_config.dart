import 'dart:io';
import 'package:flutter/foundation.dart';

/// AI模型提供商枚举
enum AIProvider {
  deepseek('deepseek', 'DeepSeek'),
  qwen('qwen', '通义千问'),
  doubao('doubao', '豆包');

  const AIProvider(this.id, this.displayName);
  final String id;
  final String displayName;

  static AIProvider fromString(String value) {
    return AIProvider.values.firstWhere(
      (provider) => provider.id == value,
      orElse: () => AIProvider.deepseek,
    );
  }
}

/// AI配置模型
class AIConfig {
  final String apiKey;
  final String apiBase;
  final String modelName;
  final int maxTokens;
  final double temperature;
  final bool streamEnabled;

  const AIConfig({
    required this.apiKey,
    required this.apiBase,
    required this.modelName,
    this.maxTokens = 4096,
    this.temperature = 0.7,
    this.streamEnabled = true,
  });

  bool get isValid => apiKey.isNotEmpty && apiKey != 'your_${_getProviderKey()}_api_key_here';

  String _getProviderKey() {
    if (apiBase.contains('deepseek')) return 'deepseek';
    if (apiBase.contains('dashscope')) return 'qwen';
    if (apiBase.contains('volces')) return 'doubao';
    return 'unknown';
  }

  AIConfig copyWith({
    String? apiKey,
    String? apiBase,
    String? modelName,
    int? maxTokens,
    double? temperature,
    bool? streamEnabled,
  }) {
    return AIConfig(
      apiKey: apiKey ?? this.apiKey,
      apiBase: apiBase ?? this.apiBase,
      modelName: modelName ?? this.modelName,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      streamEnabled: streamEnabled ?? this.streamEnabled,
    );
  }
}

/// AI配置管理服务
class AIConfigService {
  static AIConfigService? _instance;
  static AIConfigService get instance => _instance ??= AIConfigService._();
  AIConfigService._();

  Map<String, String> _envVars = {};
  bool _isLoaded = false;
  AIProvider _currentProvider = AIProvider.deepseek;

  /// 加载AI配置
  Future<void> loadConfig() async {
    if (_isLoaded) return;

    try {
      final configFile = File('.env.ai');
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        _parseEnvContent(content);
        _isLoaded = true;
        
        // 设置默认提供商
        final defaultModel = _envVars['AI_DEFAULT_MODEL'] ?? 'deepseek';
        _currentProvider = AIProvider.fromString(defaultModel);
        
        debugPrint('✅ AI配置加载成功，当前提供商: ${_currentProvider.displayName}');
      } else {
        debugPrint('⚠️  AI配置文件不存在: .env.ai');
        debugPrint('📝 请复制 ai_config_example.env 为 .env.ai 并配置API密钥');
      }
    } catch (e) {
      debugPrint('❌ 加载AI配置失败: $e');
    }
  }

  /// 解析环境变量内容
  void _parseEnvContent(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      
      final parts = trimmed.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        _envVars[key] = value;
      }
    }
  }

  /// 获取当前AI提供商
  AIProvider get currentProvider => _currentProvider;

  /// 设置当前AI提供商
  void setProvider(AIProvider provider) {
    _currentProvider = provider;
    debugPrint('🔄 切换AI提供商为: ${provider.displayName}');
  }

  /// 获取当前提供商的配置
  AIConfig getCurrentConfig() {
    final provider = _currentProvider;
    switch (provider) {
      case AIProvider.deepseek:
        return AIConfig(
          apiKey: _envVars['AI_DEEPSEEK_API_KEY'] ?? '',
          apiBase: _envVars['AI_DEEPSEEK_API_BASE'] ?? 'https://api.deepseek.com',
          modelName: _envVars['AI_DEEPSEEK_MODEL_NAME'] ?? 'deepseek-reasoner',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
      case AIProvider.qwen:
        return AIConfig(
          apiKey: _envVars['AI_QWEN_API_KEY'] ?? '',
          apiBase: _envVars['AI_QWEN_API_BASE'] ?? 'https://dashscope.aliyuncs.com/compatible-mode/v1',
          modelName: _envVars['AI_QWEN_MODEL_NAME'] ?? 'qwen-turbo',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
      case AIProvider.doubao:
        return AIConfig(
          apiKey: _envVars['AI_DOUBAO_API_KEY'] ?? '',
          apiBase: _envVars['AI_DOUBAO_API_BASE'] ?? 'https://ark.cn-beijing.volces.com/api/v3',
          modelName: _envVars['AI_DOUBAO_MODEL_NAME'] ?? 'doubao-pro-4k',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
    }
  }

  /// 获取指定提供商的配置
  AIConfig getConfigForProvider(AIProvider provider) {
    switch (provider) {
      case AIProvider.deepseek:
        return AIConfig(
          apiKey: _envVars['AI_DEEPSEEK_API_KEY'] ?? '',
          apiBase: _envVars['AI_DEEPSEEK_API_BASE'] ?? 'https://api.deepseek.com',
          modelName: _envVars['AI_DEEPSEEK_MODEL_NAME'] ?? 'deepseek-reasoner',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
      case AIProvider.qwen:
        return AIConfig(
          apiKey: _envVars['AI_QWEN_API_KEY'] ?? '',
          apiBase: _envVars['AI_QWEN_API_BASE'] ?? 'https://dashscope.aliyuncs.com/compatible-mode/v1',
          modelName: _envVars['AI_QWEN_MODEL_NAME'] ?? 'qwen-turbo',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
      case AIProvider.doubao:
        return AIConfig(
          apiKey: _envVars['AI_DOUBAO_API_KEY'] ?? '',
          apiBase: _envVars['AI_DOUBAO_API_BASE'] ?? 'https://ark.cn-beijing.volces.com/api/v3',
          modelName: _envVars['AI_DOUBAO_MODEL_NAME'] ?? 'doubao-pro-4k',
          maxTokens: int.tryParse(_envVars['AI_CHAT_MAX_TOKENS'] ?? '4096') ?? 4096,
          temperature: double.tryParse(_envVars['AI_CHAT_TEMPERATURE'] ?? '0.7') ?? 0.7,
          streamEnabled: _envVars['AI_CHAT_STREAM_ENABLED']?.toLowerCase() == 'true',
        );
    }
  }

  /// 获取所有可用的提供商
  List<AIProvider> getAvailableProviders() {
    return AIProvider.values.where((provider) {
      final config = getConfigForProvider(provider);
      return config.isValid;
    }).toList();
  }

  /// 检查是否有可用的AI配置
  bool get hasValidConfig {
    return getAvailableProviders().isNotEmpty;
  }

  /// 获取配置状态信息
  Map<String, dynamic> getConfigStatus() {
    final availableProviders = getAvailableProviders();
    return {
      'isLoaded': _isLoaded,
      'hasValidConfig': hasValidConfig,
      'currentProvider': _currentProvider.displayName,
      'availableProviders': availableProviders.map((p) => p.displayName).toList(),
      'totalProviders': AIProvider.values.length,
    };
  }

  /// 重新加载配置
  Future<void> reloadConfig() async {
    _isLoaded = false;
    _envVars.clear();
    await loadConfig();
  }
}
