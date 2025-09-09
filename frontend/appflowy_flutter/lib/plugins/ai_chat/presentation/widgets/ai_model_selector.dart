import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/ai_config.dart';
import '../../../../core/services/ai_chat_service.dart';

/// AI模型选择器组件
class AIModelSelector extends StatefulWidget {
  final AIProvider? selectedProvider;
  final Function(AIProvider)? onProviderChanged;
  final bool showTestButton;
  final VoidCallback? onSettingsPressed;

  const AIModelSelector({
    super.key,
    this.selectedProvider,
    this.onProviderChanged,
    this.showTestButton = false,
    this.onSettingsPressed,
  });

  @override
  State<AIModelSelector> createState() => _AIModelSelectorState();
}

class _AIModelSelectorState extends State<AIModelSelector> {
  final AIConfigService _configService = AIConfigService.instance;
  final AIChatService _chatService = AIChatService.instance;
  
  bool _isTesting = false;
  Map<AIProvider, bool>? _testResults;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await _configService.loadConfig();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableProviders = _configService.getAvailableProviders();
    final currentProvider = widget.selectedProvider ?? _configService.currentProvider;

    if (availableProviders.isEmpty) {
      return _buildNoConfigWidget(theme);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'AI模型选择',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onSettingsPressed != null)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: widget.onSettingsPressed,
                    tooltip: 'AI设置',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 模型选择器
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AIProvider>(
                  value: currentProvider,
                  isExpanded: true,
                  items: availableProviders.map((provider) {
                    final config = _configService.getConfigForProvider(provider);
                    final isValid = config.isValid;
                    
                    return DropdownMenuItem<AIProvider>(
                      value: provider,
                      child: Row(
                        children: [
                          Icon(
                            _getProviderIcon(provider),
                            size: 20,
                            color: isValid ? theme.primaryColor : theme.disabledColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.displayName,
                                  style: TextStyle(
                                    color: isValid ? null : theme.disabledColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  config.modelName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_testResults?[provider] == true)
                            Icon(Icons.check_circle, color: Colors.green[600], size: 16)
                          else if (_testResults?[provider] == false)
                            Icon(Icons.error, color: Colors.red[600], size: 16),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (provider) {
                    if (provider != null) {
                      _configService.setProvider(provider);
                      widget.onProviderChanged?.call(provider);
                      if (mounted) setState(() {});
                    }
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 当前配置信息
            _buildConfigInfo(theme, currentProvider),
            
            if (widget.showTestButton) ...[
              const SizedBox(height: 12),
              _buildTestButtons(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoConfigWidget(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber,
              size: 48,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 12),
            Text(
              '未找到AI配置',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请配置AI API密钥以使用AI功能',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onSettingsPressed,
              icon: const Icon(Icons.settings),
              label: const Text('配置AI设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInfo(ThemeData theme, AIProvider provider) {
    final config = _configService.getConfigForProvider(provider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '配置信息',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: config.isValid ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  config.isValid ? '已配置' : '未配置',
                  style: TextStyle(
                    fontSize: 11,
                    color: config.isValid ? Colors.green[800] : Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('模型', config.modelName, theme),
          _buildInfoRow('API地址', _shortenUrl(config.apiBase), theme),
          _buildInfoRow('最大令牌', '${config.maxTokens}', theme),
          _buildInfoRow('温度', '${config.temperature}', theme),
          _buildInfoRow('流式传输', config.streamEnabled ? '启用' : '禁用', theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isTesting ? null : _testCurrentProvider,
            icon: _isTesting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
            label: Text(_isTesting ? '测试中...' : '测试连接'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isTesting ? null : _testAllProviders,
            icon: const Icon(Icons.playlist_play),
            label: const Text('测试所有'),
          ),
        ),
      ],
    );
  }

  IconData _getProviderIcon(AIProvider provider) {
    switch (provider) {
      case AIProvider.deepseek:
        return Icons.psychology;
      case AIProvider.qwen:
        return Icons.auto_awesome;
      case AIProvider.doubao:
        return Icons.rocket_launch;
    }
  }

  String _shortenUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host;
  }

  Future<void> _testCurrentProvider() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final result = await _chatService.testConnection();
      if (mounted) {
        setState(() {
          _testResults = {_configService.currentProvider: result['success'] == true};
        });
        
        _showTestResult(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResults = {_configService.currentProvider: false};
        });
        _showTestResult({'success': false, 'error': e.toString()});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _testAllProviders() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final results = await _chatService.testAllProviders();
      if (mounted) {
        final testResults = <AIProvider, bool>{};
        for (final result in results) {
          final providerName = result['provider'] as String;
          final provider = AIProvider.values.firstWhere(
            (p) => p.displayName == providerName,
            orElse: () => AIProvider.deepseek,
          );
          testResults[provider] = result['success'] == true;
        }
        
        setState(() {
          _testResults = testResults;
        });
        
        _showAllTestResults(results);
      }
    } catch (e) {
      if (mounted) {
        _showTestResult({'success': false, 'error': e.toString()});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  void _showTestResult(Map<String, dynamic> result) {
    final success = result['success'] == true;
    final provider = result['provider'] ?? 'AI';
    final error = result['error'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
            ? '✅ $provider 连接测试成功'
            : '❌ $provider 连接测试失败${error != null ? ': $error' : ''}',
        ),
        backgroundColor: success ? Colors.green[600] : Colors.red[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAllTestResults(List<Map<String, dynamic>> results) {
    final successCount = results.where((r) => r['success'] == true).length;
    final totalCount = results.length;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('测试完成: $successCount/$totalCount 个提供商连接成功'),
        backgroundColor: successCount > 0 ? Colors.green[600] : Colors.orange[600],
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
