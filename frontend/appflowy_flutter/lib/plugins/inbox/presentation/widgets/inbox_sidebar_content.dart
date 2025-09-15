import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/inbox/application/inbox_bloc.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_search_bar.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_filter_tabs.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_item_cell.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';

// 收件箱侧边栏内容组件
class InboxSidebarContent extends StatefulWidget {
  const InboxSidebarContent({
    super.key,
    this.selectedItem,
    this.onItemSelected,
  });

  final InboxItem? selectedItem;
  final Function(InboxItem)? onItemSelected;

  @override
  State<InboxSidebarContent> createState() => _InboxSidebarContentState();
}

class _InboxSidebarContentState extends State<InboxSidebarContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxBloc, InboxState>(
      builder: (context, state) {
        return Column(
          children: [
            // 搜索栏
            if (state.items.isNotEmpty)
              InboxSearchBar(
                onChanged: (query) {
                  context.read<InboxBloc>().add(InboxEvent.search(query));
                },
              ),
            // 筛选标签
            if (state.items.isNotEmpty)
              InboxFilterTabs(
                selectedFilter: state.selectedFilter,
                onFilterChanged: (filter) {
                  context.read<InboxBloc>().add(InboxEvent.filterChanged(filter));
                },
              ),
            // 列表内容
            Expanded(
              child: state.items.isEmpty && !state.isLoading
                  ? _buildEmptyState(context)
                  : _buildInboxList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Icon(
          Icons.inbox_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          '收件箱为空',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '暂时没有任何内容',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildInboxList(BuildContext context, InboxState state) {
    // 使用过滤后的项目列表
    final displayItems = state.filteredItems;
    
    // 如果搜索结果为空，显示无结果状态
    if (displayItems.isEmpty && state.searchQuery.isNotEmpty) {
      return _buildNoSearchResults(context);
    }
    
    // 如果正在加载，显示加载状态
    if (state.isLoading && displayItems.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController,
      barSize: 6.0,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 0), // 左边距16px，右边距8px
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          final isSelected = widget.selectedItem?.id == item.id;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : null,
            ),
            child: InkWell(
              onTap: () {
                widget.onItemSelected?.call(item);
              },
              borderRadius: BorderRadius.circular(8),
              child: InboxItemCell(
                item: item,
                onMarkAsRead: () => _markAsRead(context, item.id),
                onToggleStar: () => _toggleStar(context, item.id),
                onToggleImportant: () => _toggleImportant(context, item.id),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Icon(
          Icons.search_off_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        Text(
          '未找到匹配结果',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '尝试使用不同的关键词',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  void _markAsRead(BuildContext context, String itemId) {
    context.read<InboxBloc>().add(InboxEvent.markAsRead(itemId));
  }

  void _toggleStar(BuildContext context, String itemId) {
    context.read<InboxBloc>().add(InboxEvent.toggleStar(itemId));
  }

  void _toggleImportant(BuildContext context, String itemId) {
    context.read<InboxBloc>().add(InboxEvent.toggleImportant(itemId));
  }
} 