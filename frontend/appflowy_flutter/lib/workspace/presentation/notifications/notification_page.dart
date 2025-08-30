import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final List<String> _tabTitles = [
    '@提及通知',
    '剪藏通知',
    '提醒通知',
    '系统通知',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      width: 387,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.backgroundColorScheme.primary,
        border: Border(
          right: BorderSide(
            color: theme.borderColorScheme.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(context),
          // 标签栏
          _buildTabBar(context),
          // 内容区域
          Expanded(
            child: _buildContent(context),
          ),
          // 底部操作栏
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          FlowyText.medium(
            '消息通知',
            fontSize: 20,
            color: theme.textColorScheme.primary,
          ),
          const Spacer(),
          // 这里可以添加更多操作按钮
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _tabTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = index == _selectedTabIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
                _tabController.animateTo(index);
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: index < _tabTitles.length - 1 ? 10 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.fillColorScheme.secondary 
                    : theme.backgroundColorScheme.primary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: theme.borderColorScheme.primary.withOpacity(0.14),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlowyText.medium(
                    title,
                    fontSize: 14,
                    color: theme.textColorScheme.primary,
                  ),
                  if (index == 0) ...[
                    const HSpace(4),
                    // 红色圆点表示未读
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2844),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 铃铛图标
          Container(
            width: 84,
            height: 78,
            decoration: BoxDecoration(
              color: theme.fillColorScheme.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: FlowySvg(
                FlowySvgs.notification_m,
                size: const Size.square(40),
                color: theme.iconColorScheme.secondary,
              ),
            ),
          ),
          const VSpace(30),
          // 提示文字
          FlowyText.regular(
            '你将在这里收到@提及、剪藏、提醒、系统通知',
            fontSize: 14,
            color: theme.textColorScheme.secondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.borderColorScheme.primary.withOpacity(0.4),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const HSpace(8),
          FlowyText.regular(
            '全部标记已读',
            fontSize: 12,
            color: theme.textColorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
