import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/identity_verification_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/email_binding_dialog.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';

class AccountManagementView extends StatefulWidget {
  const AccountManagementView({
    super.key,
    required this.userProfile,
    required this.changeSelectedPage,
  });

  final UserProfilePB userProfile;
  final Function changeSelectedPage;

  @override
  State<AccountManagementView> createState() => _AccountManagementViewState();
}

class _AccountManagementViewState extends State<AccountManagementView> {
  int selectedPlan = 0; // 0: 免费, 1: 标准, 2: 高级, 3: 专业, 4: 超级会员

  final List<Map<String, dynamic>> plans = [
    {
      'title': '免费账户',
      'price': '¥0',
      'period': '',
      'color': const Color(0xFFFF6B47),
      'tag': '',
      'isPopular': false,
    },
    {
      'title': '标准账户',
      'price': '¥20.00',
      'period': '/月',
      'color': const Color(0xFF4CAF50),
      'tag': '',
      'isPopular': false,
    },
    {
      'title': '高级账户',
      'price': '¥35.00',
      'period': '/月',
      'color': const Color(0xFF2196F3),
      'tag': '',
      'isPopular': false,
    },
    {
      'title': '专业账户',
      'price': '¥45.00',
      'period': '/月',
      'color': const Color(0xFF9C27B0),
      'tag': '',
      'isPopular': false,
    },
    {
      'title': '超级会员',
      'price': '¥24.83',
      'period': '/月',
      'color': const Color(0xFFFF9800),
      'tag': '',
      'isPopular': false,
    },
  ];

  final List<Map<String, dynamic>> benefits = [
    {
      'icon': FlowySvgs.rights_ai_xl,
      'title': '小马AI',
      'color': const Color(0xFFFF9F7A),
    },
    {
      'icon': FlowySvgs.rights_calendar_xl,
      'title': '小马日历',
      'color': const Color(0xFF7FD4A3),
    },
    {
      'icon': FlowySvgs.rights_collect_xl,
      'title': '小马收藏夹',
      'color': const Color(0xFF7AB8FF),
    },
    {
      'icon': FlowySvgs.rights_cs_xl,
      'title': '云端同步',
      'color': const Color(0xFFE07AFF),
    },
    {
      'icon': FlowySvgs.rights_storage_xl,
      'title': '100T空间',
      'color': const Color(0xFFFF7AB8),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return SettingsBody(
      title: "我的账户",
      children: [
        // 账户类型选择区域
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // 账户类型选择
              Row(
                children: plans.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> plan = entry.value;
                  bool isSelected = selectedPlan == index;
                  
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPlan = index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < plans.length - 1 ? theme.spacing.s : 0,
                        ),
                        padding: EdgeInsets.all(theme.spacing.m),
                        decoration: BoxDecoration(
                          color: isSelected ? plan['color'].withOpacity(0.1) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? plan['color'] : theme.borderColorScheme.primary.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(theme.spacing.s),
                        ),
                        child: Column(
                          children: [
                            // 标签
                            if (plan['tag'].isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: plan['color'],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: FlowyText(
                                  plan['tag'],
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            if (plan['isPopular'])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B47),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const FlowyText(
                                  '推荐',
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            const VSpace(8),
                            // 账户类型
                            FlowyText(
                              plan['title'],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textColorScheme.primary,
                            ),
                            const VSpace(4),
                            // 价格
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                FlowyText(
                                  plan['price'],
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textColorScheme.primary,
                                ),
                                if (plan['period'].isNotEmpty)
                                  FlowyText(
                                    plan['period'],
                                    fontSize: 12,
                                    color: theme.textColorScheme.secondary,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const VSpace(32),
              
              // 获赠权益标题
              FlowyText(
                '获赠权益',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColorScheme.primary,
              ),
              
              const VSpace(16),
              
              // 权益图标行
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: benefits.map((benefit) {
                    return Expanded(
                      child: Column(
                        children: [
                          FlowySvg(
                            benefit['icon'],
                            color: benefit['color'],
                            size: const Size.square(40),
                          ),
                          const VSpace(8),
                          FlowyText(
                            benefit['title'],
                            fontSize: 12,
                            color: theme.textColorScheme.secondary,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const VSpace(32),
              
              // 功能列表
              _buildFeatureItem(context, '文档光标颜色', '购买', showArrow: true),
              _buildFeatureItem(context, 'AI使用次数', '今日剩余20次升级', showArrow: true),
              GestureDetector(
                onTap: () => widget.changeSelectedPage(SettingsPage.userProfile),
                child: _buildFeatureItem(context, '个人资料', '', showArrow: true),
              ),
              GestureDetector(
                onTap: () => _showPhoneVerificationDialog(context),
                child: _buildFeatureItem(context, '绑定手机', '修改', showButton: true, buttonText: '修改'),
              ),
              GestureDetector(
                onTap: () => _showEmailVerificationDialog(context),
                child: _buildFeatureItem(context, '邮箱', '修改', showButton: true, buttonText: '修改'),
              ),
              
              const VSpace(32),
              
              // 退出登录按钮
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF6B47),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(theme.spacing.s),
                ),
                child: const Center(
                  child: FlowyText(
                    '退出登录',
                    fontSize: 16,
                    color: Color(0xFFFF6B47),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    String subtitle, {
    bool showArrow = false,
    bool showButton = false,
    String buttonText = '',
  }) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.m),
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              title,
              fontSize: 16,
              color: theme.textColorScheme.primary,
            ),
          ),
          if (subtitle.isNotEmpty && !showButton)
            FlowyText(
              subtitle,
              fontSize: 14,
              color: theme.textColorScheme.secondary,
            ),
          if (showButton)
            FlowyText(
              buttonText,
              fontSize: 14,
              color: theme.textColorScheme.secondary,
            ),
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
    );
  }

  void _showPhoneVerificationDialog(BuildContext context) {
    // 从用户资料中获取手机号，如果没有则使用默认值
    final phoneNumber = widget.userProfile.phoneNumber.isNotEmpty 
        ? widget.userProfile.phoneNumber 
        : '185******70';
        
    showDialog(
      context: context,
      builder: (context) => IdentityVerificationDialog(
        phoneNumber: phoneNumber,
        onVerificationComplete: () {
          // 验证完成后的回调
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('手机验证完成'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EmailBindingDialog(
        onBindingComplete: () {
          // 绑定完成后的回调
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('邮箱绑定完成'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
} 