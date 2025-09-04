import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_header.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_filter_tabs.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_clip_section.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_content_list.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_detail_panel.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String selectedFilter = '全部'; // 当前选中的筛选标签
  InboxItem? selectedItem; // 当前选中的邮件
  double leftPanelWidth = 0.35; // 左栏宽度比例，默认35%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: selectedItem == null
          ? _buildSingleColumnLayout()
          : _buildTwoColumnLayout(),
    );
  }

  // 单栏布局（无邮件选中）
  Widget _buildSingleColumnLayout() {
    return Column(
      children: [
        // 收件箱头部
        InboxHeader(),
        
        // 筛选标签
        InboxFilterTabs(
          selectedFilter: selectedFilter,
          onFilterChanged: (filter) {
            setState(() {
              selectedFilter = filter;
            });
          },
        ),
        
        // 剪藏链接区域
        const InboxClipSection(),
        
        // 邮件列表
        Expanded(
          child: InboxContentList(
            selectedFilter: selectedFilter,
            onItemSelected: (item) {
              setState(() {
                selectedItem = item;
              });
            },
            selectedItem: selectedItem,
          ),
        ),
      ],
    );
  }

  // 双栏布局（有邮件选中）
  Widget _buildTwoColumnLayout() {
    return Row(
      children: [
        // 左栏：完整的收件箱界面
        SizedBox(
          width: MediaQuery.of(context).size.width * leftPanelWidth,
          child: Column(
            children: [
              // 收件箱头部
              InboxHeader(),
              
              // 筛选标签
              InboxFilterTabs(
                selectedFilter: selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
              
              // 剪藏链接区域
              const InboxClipSection(),
              
              // 邮件列表
              Expanded(
                child: InboxContentList(
                  selectedFilter: selectedFilter,
                  onItemSelected: (item) {
                    setState(() {
                      selectedItem = item;
                    });
                  },
                  selectedItem: selectedItem,
                ),
              ),
            ],
          ),
        ),
        
        // 可拖拽的分割线
        _buildDragHandle(),
        
        // 右栏：邮件详情
        Expanded(
          child: InboxDetailPanel(
            item: selectedItem!,
            onClose: () {
              setState(() {
                selectedItem = null;
              });
            },
          ),
        ),
      ],
    );
  }

  // 可拖拽的分割线
  Widget _buildDragHandle() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final screenWidth = MediaQuery.of(context).size.width;
          final newLeftWidth = leftPanelWidth * screenWidth + details.delta.dx;
          leftPanelWidth = (newLeftWidth / screenWidth).clamp(0.25, 0.7); // 限制在25%-70%之间
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ),
      ),
    );
  }
}
