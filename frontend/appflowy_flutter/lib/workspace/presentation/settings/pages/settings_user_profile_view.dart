import 'dart:io';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsUserProfileView extends StatefulWidget {
  const SettingsUserProfileView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SettingsUserProfileView> createState() => _SettingsUserProfileViewState();
}

class _SettingsUserProfileViewState extends State<SettingsUserProfileView> {
  late String _name;
  late String _avatarUrl;

  @override
  void initState() {
    super.initState();
    _name = widget.userProfile.name;
    _avatarUrl = widget.userProfile.iconUrl;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: "我的账户",
      autoSeparate: false,
      children: [
        SettingsCategory(
          title: "个人资料",
          children: [
            const SizedBox(height: 20),
            // 头像部分
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadAvatar,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: ClipOval(
                        child: _avatarUrl.isNotEmpty
                            ? _buildNetworkAvatar(_avatarUrl)
                            : _buildDefaultAvatar(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "上传图片",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 用户名输入
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    "我的名称",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: SettingsInputField(
                    value: _name,
                    placeholder: "我的名称",
                    onSave: (value) {
                      setState(() {
                        _name = value;
                      });
                      // TODO: 保存到后端
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkAvatar(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultAvatar();
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.orange,
      ),
    );
  }

  void _uploadAvatar() async {
    final result = await getIt<FilePickerService>().pickFiles(
      dialogTitle: '',
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      setState(() {
        _avatarUrl = file.path;
      });
      // TODO: 上传到后端
    }
  }
} 