import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra/size.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxItemCell extends StatelessWidget {
  const InboxItemCell({
    super.key,
    required this.item,
    required this.onMarkAsRead,
    required this.onToggleStar,
    required this.onToggleImportant,
  });

  final InboxItem item;
  final VoidCallback onMarkAsRead;
  final VoidCallback onToggleStar;
  final VoidCallback onToggleImportant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    // 未读指示器
                    if (!item.isRead)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    // 标题
                    Expanded(
                      child: FlowyText(
                        item.title,
                        fontSize: FontSizes.s14,
                        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 重要标记
                    if (item.isImportant)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: FlowySvg(
                          FlowySvgs.star_s,
                          size: const Size.square(12),
                          color: Colors.red,
                        ),
                      ),
                  ],
                ),
                const VSpace(4),
                // 描述
                FlowyText(
                  item.description,
                  fontSize: FontSizes.s12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const VSpace(4),
                // 底部信息行
                Row(
                  children: [
                    // 日期
                    FlowyText(
                      item.date,
                      fontSize: FontSizes.s11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    // 来源标签
                    if (item.source.isNotEmpty) ...[
                      const HSpace(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FlowyText(
                          item.source,
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // 收藏状态
                    if (item.isStarred)
                      FlowySvg(
                        FlowySvgs.star_s,
                        size: const Size.square(12),
                        color: Colors.orange,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const HSpace(8),
          // 操作按钮
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标记已读/未读按钮
              FlowyIconButton(
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                width: 24,
                onPressed: onMarkAsRead,
                iconPadding: const EdgeInsets.all(2),
                icon: FlowySvg(
                  item.isRead ? FlowySvgs.uncheck_s : FlowySvgs.check_s,
                  size: const Size.square(14),
                ),
                tooltipText: item.isRead ? '标记为未读' : '标记为已读',
              ),
              const VSpace(4),
              // 收藏按钮
              FlowyIconButton(
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                width: 24,
                onPressed: onToggleStar,
                iconPadding: const EdgeInsets.all(2),
                icon: FlowySvg(
                  item.isStarred ? FlowySvgs.star_s : FlowySvgs.unfavorite_s,
                  size: const Size.square(14),
                  color: item.isStarred ? Colors.orange : null,
                ),
                tooltipText: item.isStarred ? '取消收藏' : '添加收藏',
              ),
              const VSpace(4),
              // 重要性按钮
              FlowyIconButton(
                iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                width: 24,
                onPressed: onToggleImportant,
                iconPadding: const EdgeInsets.all(2),
                icon: FlowySvg(
                  FlowySvgs.star_s,
                  size: const Size.square(14),
                  color: item.isImportant ? Colors.red : null,
                ),
                tooltipText: item.isImportant ? '取消重要' : '标记重要',
              ),
            ],
          ),
        ],
      ),
    );
  }
} 