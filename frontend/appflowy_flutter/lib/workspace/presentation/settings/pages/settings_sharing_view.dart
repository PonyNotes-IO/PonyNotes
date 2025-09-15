import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
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
      title: '无标题',
      url: 'https://www.iconfont.cn/search/index?',
      publishTime: '2025年6月24日 15:00',
    ),
    _PublishItem(
      title: '无标题', 
      url: 'https://www.iconfont.cn/search/index?',
      publishTime: '2025年6月24日 15:00',
    ),
    _PublishItem(
      title: '无标题',
      url: 'https://www.iconfont.cn/search/index?', 
      publishTime: '2025年6月24日 15:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
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
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 500,
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
      title: '我发布的网址',
      description: '管理您已发布的文档和页面',
      children: [
        if (_publishedItems.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlowySvg(
                    FlowySvgs.share_publish_s,
                    size: Size(48, 48),
                    color: Colors.grey,
                  ),
                  const VSpace(16),
                  FlowyText(
                    '暂无发布内容',
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          )
        else
          ..._publishedItems.map((item) => _buildPublishItem(item)).toList(),
      ],
    );
  }

  Widget _buildPublishItem(_PublishItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // 网站图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.language,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          const HSpace(16),
          // 内容区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlowyText(
                  item.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                const VSpace(4),
                FlowyText(
                  item.url,
                  fontSize: 14,
                  color: Colors.blue,
                  overflow: TextOverflow.ellipsis,
                ),
                const VSpace(8),
                FlowyText(
                  item.publishTime,
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          const HSpace(16),
          // 打开网址按钮
          ElevatedButton(
            onPressed: () {
              // TODO: 实现打开网址功能
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              '打开网址',
              style: TextStyle(fontSize: 14),
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