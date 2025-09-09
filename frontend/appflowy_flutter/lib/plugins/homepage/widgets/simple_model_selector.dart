import 'package:flutter/material.dart';

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
  String _selectedModel = 'DeepSeek-R1-V3';

  final List<String> _models = [
    'DeepSeek-R1-V3',
    '豆包',
    '通义千问',
  ];

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
      child: DropdownButtonHideUnderline(
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
          items: _models.map((String model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Text(
                model,
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
