import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
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
        onTap: () => _openFileLibrary(context),
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

  void _openFileLibrary(BuildContext context) {
    try {
      // 创建文件库插件
      final fileLibraryPlugin = makePlugin(
        pluginType: PluginType.fileLibrary,
        data: null,
      );

      // 在新标签页中打开文件库
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: fileLibraryPlugin,
        ),
      );
    } catch (e) {
      _showMessage(context, '打开文件库时发生错误: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
