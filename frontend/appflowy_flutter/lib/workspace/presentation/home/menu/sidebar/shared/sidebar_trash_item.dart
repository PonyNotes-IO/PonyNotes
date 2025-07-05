import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarTrashItem extends StatelessWidget {
  const SidebarTrashItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: FlowyHover(
        style: HoverStyle(
          hoverColor: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: FlowyButton(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          leftIcon: FlowySvg(
            FlowySvgs.icon_delete_s,
            size: const Size.square(16.0),
            color: Theme.of(context).iconTheme.color,
          ),
          leftIconSize: const Size.square(16.0),
          iconPadding: 10.0,
          text: FlowyText.medium(
            LocaleKeys.trash_text.tr(),
            fontSize: 12,
          ),
          onTap: () {
            getIt<MenuSharedState>().latestOpenView = null;
            getIt<TabsBloc>().add(
              TabsEvent.openPlugin(
                plugin: makePlugin(pluginType: PluginType.trash),
              ),
            );
          },
        ),
      ),
    );
  }
}
