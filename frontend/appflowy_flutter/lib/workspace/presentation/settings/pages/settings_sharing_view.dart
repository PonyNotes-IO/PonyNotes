import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

class SettingsSharingView extends StatefulWidget {
  const SettingsSharingView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SettingsSharingView> createState() => _SettingsSharingViewState();
}

class _SettingsSharingViewState extends State<SettingsSharingView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['共享', '发布'];

  final List<_PublishItem> _publishedItems = [
    _PublishItem(
      title: '文件标题名称',
      url: 'https://www.iconfont.cn/search/index?',
      publishTime: '2025年6月24日 15:00',
    ),
    _PublishItem(
      title: '文件标题名称', 
      url: 'https://www.iconfont.cn/search/index?',
      publishTime: '2025年6月24日 15:00',
    ),
    _PublishItem(
      title: '文件标题名称',
      url: 'https://www.iconfont.cn/search/index?', 
      publishTime: '2025年6月24日 15:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: '共享发布',
      description: '管理您的文档共享和发布设置',
      children: [
        _buildTabSection(),
        _buildTabContent(),
      ],
    );
  }

  Widget _buildTabSection() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          int index = entry.key;
          String tab = entry.value;
          bool isSelected = _tabController.index == index;
          
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(index);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? null : Border.all(color: Colors.grey[300]!),
              ),
              child: FlowyText(
                tab,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 450,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSharedContent(),
          _buildPublishedContent(),
        ],
      ),
    );
  }

  Widget _buildSharedContent() {
    return SettingsCategory(
      title: '共享设置',
      description: '管理文档的共享权限和协作设置',
      children: [
        Container(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlowySvg(
                  FlowySvgs.share_s,
                  size: Size(48, 48),
                  color: Colors.grey,
                ),
                const VSpace(16),
                FlowyText(
                  '暂无共享内容',
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPublishedContent() {
    return SettingsCategory(
      title: '发布内容',
      description: '管理已发布的文档和分享链接',
      children: [
        // 标题区域
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FlowyText(
                  '文件标题',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                flex: 2,
                child: FlowyText(
                  '发布时间',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                flex: 2,
                child: FlowyText(
                  '访问权限',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // 分隔线
        Container(
          height: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        // 内容列表
        SizedBox(
          height: 280,
          child: ListView.builder(
            itemCount: _publishedItems.length,
            itemBuilder: (context, index) {
              return _buildPublishListItem(_publishedItems[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPublishListItem(_PublishItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 文件标题
          Expanded(
            flex: 3,
            child: FlowyText(
              item.title,
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          // 时间
          Expanded(
            flex: 2,
            child: FlowyText(
              item.publishTime,
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          // 访问权限
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: FlowyText(
                '查看邀请成员',
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.blue[700],
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishItem {
  final String title;
  final String url;
  final String publishTime;

  _PublishItem({
    required this.title,
    required this.url,
    required this.publishTime,
  });
} 