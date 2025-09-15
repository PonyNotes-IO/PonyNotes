import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/inbox/application/inbox_bloc.dart';
import 'package:appflowy/plugins/inbox/domain/models/sort_option.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

// 收件箱工具栏组件
class InboxToolbar extends StatelessWidget {
  const InboxToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 排序选择器
          BlocBuilder<InboxBloc, InboxState>(
            builder: (context, state) {
              return _buildSortDropdown(context, state.sortOption);
            },
          ),
          const Spacer(),
          // 标记所有为已读按钮
          FlowyIconButton(
            iconColorOnHover: Theme.of(context).colorScheme.primary,
            width: 32,
            onPressed: () => _showMarkAllAsReadDialog(context),
            iconPadding: const EdgeInsets.all(4),
                          icon: const FlowySvg(FlowySvgs.notification_markasread_s),
            tooltipText: '标记所有为已读',
          ),
          const HSpace(16),
          // 更多操作按钮
          FlowyIconButton(
            iconColorOnHover: Theme.of(context).colorScheme.onSurface,
            width: 32,
            onPressed: () => _showMoreOptions(context),
            iconPadding: const EdgeInsets.all(4),
            icon: const FlowySvg(FlowySvgs.three_dots_s),
            tooltipText: '更多操作',
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context, SortOption currentSort) {
    return PopupMenuButton<SortOption>(
      initialValue: currentSort,
      onSelected: (sortOption) {
        context.read<InboxBloc>().add(InboxEvent.sortChanged(sortOption));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SortOption.updatedDate,
          child: Text('按更新时间'),
        ),
        const PopupMenuItem(
          value: SortOption.createdDate,
          child: Text('按创建时间'),
        ),
        const PopupMenuItem(
          value: SortOption.title,
          child: Text('按标题'),
        ),
        const PopupMenuItem(
                      value: SortOption.priority,
          child: Text('按重要性'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSortText(currentSort),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const HSpace(4),
            const FlowySvg(
              FlowySvgs.drop_menu_show_s,
              size: Size.square(12),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortText(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.updatedDate:
        return '按更新时间';
      case SortOption.createdDate:
        return '按创建时间';
      case SortOption.title:
        return '按标题';
                case SortOption.priority:
        return '按重要性';
    }
  }

  void _showMarkAllAsReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('标记所有为已读'),
        content: const Text('确定要将所有项目标记为已读吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<InboxBloc>().add(const InboxEvent.markAllAsRead());
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ 已将所有项目标记为已读'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FlowySvg(FlowySvgs.reload_s),
              title: const Text('刷新'),
              onTap: () {
                context.read<InboxBloc>().add(const InboxEvent.loadItems());
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const FlowySvg(FlowySvgs.settings_s),
              title: const Text('设置'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: 打开设置页面
              },
            ),
          ],
        ),
      ),
    );
  }
} 