import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/plugins/inbox/application/inbox_bloc.dart';
import 'package:appflowy/plugins/inbox/application/inbox_service.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_sidebar_content.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_toolbar.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_document_view.dart';

// 主收件箱面板骨架 - 包含侧边栏和主界面
class InboxMainPanel extends StatefulWidget {
  @override
  State<InboxMainPanel> createState() => _InboxMainPanelState();
}

class _InboxMainPanelState extends State<InboxMainPanel> {
  InboxItem? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InboxBloc(
        inboxService: InboxService(),
      )..add(const InboxEvent.initial()),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Row(
          children: [
            // 左侧收件箱侧边栏
            Container(
              width: 360,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  // 顶部工具栏
                  Container(
                    height: 50,
                    padding: EdgeInsets.zero,
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
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '收件箱',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 侧边栏内容
                  Expanded(
                    child: _buildExpandedSidebar(),
                  ),
                ],
              ),
            ),
            // 右侧主界面区域
            Expanded(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Theme.of(context).colorScheme.surface,
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSidebar() {
    return InboxSidebarContent(
      selectedItem: _selectedItem,
      onItemSelected: (item) {
        setState(() {
          _selectedItem = item;
        });
      },
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<InboxBloc, InboxState>(
      builder: (context, state) {
        // 如果收件箱为空，显示空白
        if (state.items.isEmpty && !state.isLoading) {
          return const SizedBox.shrink();
        }
        
        // 构建主界面内容
        return Column(
          children: [
            // 工具栏 - 只在有内容时显示
            if (state.items.isNotEmpty)
              InboxToolbar(),
            // 主内容区域
            Expanded(
              child: _selectedItem == null 
                  ? const SizedBox.shrink() // 没有选中项目时显示空白
                  : _buildSelectedItemContent(context, _selectedItem!),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSelectedItemContent(BuildContext context, InboxItem item) {
    return InboxDocumentView(item: item);
  }
} 