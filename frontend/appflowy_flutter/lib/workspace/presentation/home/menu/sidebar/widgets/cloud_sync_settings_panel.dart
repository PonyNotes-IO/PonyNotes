import 'package:flutter/material.dart';

class CloudSyncSettingsPanel extends StatefulWidget {
  const CloudSyncSettingsPanel({
    super.key,
    required this.isEnabled,
    required this.onToggle,
    this.storageTotal = '200G',
    this.maxFileSize = '3GB',
  });

  final bool isEnabled;
  final Function(bool) onToggle;
  final String storageTotal;
  final String maxFileSize;

  @override
  State<CloudSyncSettingsPanel> createState() => _CloudSyncSettingsPanelState();
}

class _CloudSyncSettingsPanelState extends State<CloudSyncSettingsPanel> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题和开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '云同步',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              _buildToggleSwitch(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 存储信息
          Text(
            '你有${widget.storageTotal}免费空间，最大可上传${widget.maxFileSize}文件',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return GestureDetector(
      onTap: _toggleSwitch,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _isEnabled 
            ? const Color(0xFFFF6B6B) // 红色激活状态
            : const Color(0xFFE0E0E0), // 灰色未激活状态
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSwitch() {
    setState(() {
      _isEnabled = !_isEnabled;
    });
    widget.onToggle(_isEnabled);
  }
}
