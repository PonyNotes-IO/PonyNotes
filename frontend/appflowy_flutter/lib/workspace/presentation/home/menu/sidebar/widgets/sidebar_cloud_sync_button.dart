import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/widgets/cloud_sync_settings_panel.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SidebarCloudSyncButton extends StatefulWidget {
  const SidebarCloudSyncButton({
    super.key,
    this.isHover = false,
  });

  final bool isHover;

  @override
  State<SidebarCloudSyncButton> createState() => _SidebarCloudSyncButtonState();
}

class _SidebarCloudSyncButtonState extends State<SidebarCloudSyncButton> {
  bool _isCloudSyncEnabled = false; // 云同步开关状态
  final GlobalKey _buttonKey = GlobalKey(); // 用于获取按钮位置

  @override
  Widget build(BuildContext context) {
    return _buildCloudSyncIcon(
      context,
      () => _showCloudSyncSettings(context),
    );
  }

  void _showCloudSyncSettings(BuildContext context) {
    // 获取按钮的位置信息
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: buttonPosition.dx, // 与按钮左对齐
              top: buttonPosition.dy + buttonSize.height, // 紧贴按钮下方
              child: Material(
                color: Colors.transparent,
                child: CloudSyncSettingsPanel(
                  isEnabled: _isCloudSyncEnabled,
                  onToggle: (enabled) {
                    setState(() {
                      _isCloudSyncEnabled = enabled;
                    });
                    debugPrint('云同步状态: ${enabled ? "已启用" : "已禁用"}');
                    Navigator.of(context).pop(); // 点击开关后关闭面板
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloudSyncIcon(
    BuildContext context,
    VoidCallback onTap,
  ) {
    return SizedBox.square(
      key: _buttonKey, // 添加key用于获取位置
      dimension: 28.0,
      child: FlowyButton(
        useIntrinsicWidth: true,
        margin: EdgeInsets.zero,
        text: FlowySvg(
          FlowySvgs.cloud_sync_m,
          color: widget.isHover
              ? Theme.of(context).colorScheme.onSurface
              : null,
          opacity: 0.7,
        ),
        onTap: onTap,
      ),
    );
  }
} 