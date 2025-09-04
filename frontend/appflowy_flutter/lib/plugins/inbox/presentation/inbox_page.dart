import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_header.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_filter_tabs.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_clip_section.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_content_list.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String selectedFilter = '全部'; // 当前选中的筛选标签

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
          
          // 内容列表
          Expanded(
            child: InboxContentList(
              selectedFilter: selectedFilter,
            ),
          ),
        ],
      ),
    );
  }
}
