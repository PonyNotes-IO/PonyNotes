import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarFileLibraryButton extends StatelessWidget {
  const SidebarFileLibraryButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AFGhostIconTextButton.primary(
        text: '文件库', // 临时使用硬编码文本
        mainAxisAlignment: MainAxisAlignment.start,
        size: AFButtonSize.l,
        onTap: () {
          // 测试代码 - 文件库按钮点击逻辑
          debugPrint('文件库按钮被点击了！');
          // TODO: 在这里添加真正的文件库逻辑
        },
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        borderRadius: theme.borderRadius.s,
        iconBuilder: (context, isHover, disabled) => FlowySvg(
          FlowySvgs.icon_file_library_s,
          size: const Size.square(16.0),
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
