import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

class SettingsSharingView extends StatelessWidget {
  const SettingsSharingView({
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
            '共享发布',
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          const VSpace(16),
          FlowyText(
            '管理文档和内容的共享发布设置',
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
          const VSpace(32),
          // 这里可以添加具体的共享发布功能
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FlowyText(
                    '发布设置',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  const VSpace(8),
                  FlowyText(
                    '这里将显示文档共享和发布的相关设置选项',
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