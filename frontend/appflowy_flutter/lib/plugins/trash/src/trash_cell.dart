import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/trash.pb.dart';
import 'package:flutter/material.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:flowy_infra/size.dart';

import 'sizes.dart';

class TrashCell extends StatelessWidget {
  const TrashCell({
    super.key,
    required this.object,
    required this.onRestore,
    required this.onDelete,
  });

  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final TrashPB object;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0), // 为右侧操作按钮添加8px右边距
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowyText(
                  object.name.isEmpty
                      ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
                      : object.name,
                  fontSize: FontSizes.s14,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                const VSpace(4),
                FlowyText(
                  dateFormatter(object.modifiedTime),
                  fontSize: FontSizes.s12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const HSpace(2),
          FlowyIconButton(
            iconColorOnHover: Theme.of(context).colorScheme.onSurface,
            width: TrashSizes.actionIconWidth,
            onPressed: onRestore,
            iconPadding: const EdgeInsets.all(3),
            icon: const FlowySvg(FlowySvgs.reset_m),
          ),
          const HSpace(2),
          FlowyIconButton(
            iconColorOnHover: Theme.of(context).colorScheme.onSurface,
            width: TrashSizes.actionIconWidth,
            onPressed: onDelete,
            iconPadding: const EdgeInsets.all(3),
            icon: const FlowySvg(FlowySvgs.delete_m),
          ),
        ],
      ),
    );
  }

  String dateFormatter($fixnum.Int64 inputTimestamps) {
    final outputFormat = DateFormat('yyyy/MM/dd');
    final date =
        DateTime.fromMillisecondsSinceEpoch(inputTimestamps.toInt() * 1000);
    final outputDate = outputFormat.format(date);
    return outputDate;
  }
}
