import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';


class SettingsWorkspaceManagementView extends StatefulWidget {
  const SettingsWorkspaceManagementView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SettingsWorkspaceManagementView> createState() => _SettingsWorkspaceManagementViewState();
}

class _SettingsWorkspaceManagementViewState extends State<SettingsWorkspaceManagementView> {
  bool _onlyOwnerCanCreateTeamWorkspace = true;

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: '空间管理',
      description: '管理您的工作空间设置和配置',
      children: [
        // 创建团队协作区权限设置
        _buildCreatePermissionSection(),
        const VSpace(24),
        // 团队协作区列表
        _buildTeamWorkspaceList(),
      ],
    );
  }

  Widget _buildCreatePermissionSection() {
    return SettingsCategory(
      title: '仅工作空间所有者才能创建团队协作区',
      description: '仅允许工作空间所有者才能创建团队协作区',
      children: [
        Row(
          children: [
            Expanded(
              child: FlowyText(
                '仅工作空间所有者才能创建团队协作区',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Toggle(
              value: _onlyOwnerCanCreateTeamWorkspace,
              onChanged: (value) {
                setState(() {
                  _onlyOwnerCanCreateTeamWorkspace = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamWorkspaceList() {
    return SettingsCategory(
      title: '团队协作区',
      children: [
        _buildTeamWorkspaceTable(),
      ],
    );
  }

  Widget _buildTeamWorkspaceTable() {
    return Column(
      children: [
        // 表格头部
        _buildTableHeader(),
        // 表格内容
        _buildTableRow(
          name: '燕琉',
          status: '1名成员·已加入',
          owner: '周文彬',
          access: '开放式',
          updateTime: '25/7/23',
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: FlowyText(
              '团队协作区',
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 2,
            child: FlowyText(
              '所有者',
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 2,
            child: FlowyText(
              '访问权限',
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                FlowyText(
                  '更新时间',
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w500,
                ),
                const HSpace(4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String name,
    required String status,
    required String owner,
    required String access,
    required String updateTime,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // 团队协作区图标
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.groups,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
                const HSpace(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlowyText(
                      name,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    const VSpace(2),
                    FlowyText(
                      status,
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FlowyText(
                      owner.substring(0, 1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const HSpace(8),
                FlowyText(
                  owner,
                  fontSize: 14,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: FlowyText(
              access,
              fontSize: 14,
            ),
          ),
          Expanded(
            flex: 2,
            child: FlowyText(
              updateTime,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 