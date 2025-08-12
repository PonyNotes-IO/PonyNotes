import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SidebarUploadButton extends StatefulWidget {
  const SidebarUploadButton({
    super.key,
    this.isHover = false,
  });

  final bool isHover;

  @override
  State<SidebarUploadButton> createState() => _SidebarUploadButtonState();
}

class _SidebarUploadButtonState extends State<SidebarUploadButton> {
  @override
  Widget build(BuildContext context) {
    return _buildUploadIcon(
      context,
      () {
        // TODO: 实现上传功能
        debugPrint('上传按钮被点击');
      },
    );
  }

  Widget _buildUploadIcon(
    BuildContext context,
    VoidCallback onTap,
  ) {
    return SizedBox.square(
      dimension: 28.0,
      child: FlowyButton(
        useIntrinsicWidth: true,
        margin: EdgeInsets.zero,
        text: FlowySvg(
          FlowySvgs.upload_s,
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