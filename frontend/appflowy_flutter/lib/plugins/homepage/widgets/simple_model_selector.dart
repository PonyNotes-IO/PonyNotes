import 'package:flutter/material.dart';
import 'package:appflowy/core/config/ai_config.dart';

/// 简单的AI模型选择器，专门用于主页
class SimpleModelSelector extends StatefulWidget {
  const SimpleModelSelector({
    super.key,
    this.onModelChanged,
  });

  final Function(String)? onModelChanged;

  @override
  State<SimpleModelSelector> createState() => _SimpleModelSelectorState();
}

class _SimpleModelSelectorState extends State<SimpleModelSelector> {
  String? _selectedModel;
  List<AIProvider> _availableProviders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  /// 加载可用的AI模型
  Future<void> _loadAvailableModels() async {
    try {
      // 确保AI配置已加载
      await AIConfigService.instance.loadConfig();
      
      final providers = AIConfigService.instance.getAvailableProviders();
      
      if (mounted) {
        setState(() {
          _availableProviders = providers;
          _isLoading = false;
          
          // 设置默认选择的模型
          if (providers.isNotEmpty) {
            _selectedModel = providers.first.displayName;
            // 通知父组件默认选择
            widget.onModelChanged?.call(_selectedModel!);
          }
        });
      }
    } catch (e) {
      debugPrint('加载AI模型列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // 使用备用的硬编码列表
          _availableProviders = [AIProvider.deepseek, AIProvider.qwen, AIProvider.doubao];
          _selectedModel = AIProvider.deepseek.displayName;
          widget.onModelChanged?.call(_selectedModel!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: _isLoading
          ? const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedModel,
                hint: const Text(
                  '选择模型',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888888),
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                isDense: true,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                ),
                items: _availableProviders.map((AIProvider provider) {
                  return DropdownMenuItem<String>(
                    value: provider.displayName,
                    child: Text(
                      provider.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedModel) {
                    setState(() {
                      _selectedModel = newValue;
                    });
                    widget.onModelChanged?.call(newValue);
                  }
                },
              ),
            ),
    );
  }
}
