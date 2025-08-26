import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/import_page/import_page_plugin.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class SidebarImportButton extends StatelessWidget {
  const SidebarImportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyHover(
      style: HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary),
      child: GestureDetector(
        onTap: () => _openImportPage(context),
        child: SizedBox(
          height: 22,
          child: Row(
            children: [
              const HSpace(8),
              FlowySvg(
                FlowySvgs.import_s,
                size: const Size.square(16),
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const HSpace(8),
              Expanded(
                child: FlowyText.regular(
                  "导入或者迁移",
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openImportPage(BuildContext context) {
    final plugin = makePlugin(
      pluginType: PluginType.importPage,
      data: null,
    );
    
    getIt<TabsBloc>().add(
      TabsEvent.openPlugin(plugin: plugin),
    );
  }
}
