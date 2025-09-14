import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

class SettingsWorkspaceManagementView extends StatelessWidget {
  const SettingsWorkspaceManagementView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText(
            '空间管理',
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          const VSpace(16),
          FlowyText(
            '管理您的工作空间设置和配置',
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
          const VSpace(32),
          // 这里可以添加具体的工作空间管理功能
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlowyText(
                    '工作空间信息',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  const VSpace(8),
                  FlowyText(
                    '这里将显示工作空间的详细信息和管理选项',
                    fontSize: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 