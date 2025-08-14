import 'package:appflowy/generated/flowy_svgs.g.dart';
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
  @override
  Widget build(BuildContext context) {
    return _buildCloudSyncIcon(
      context,
      () {
        // TODO: 实现云同步功能
        debugPrint('云同步按钮被点击');
      },
    );
  }

  Widget _buildCloudSyncIcon(
    BuildContext context,
    VoidCallback onTap,
  ) {
    return SizedBox.square(
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