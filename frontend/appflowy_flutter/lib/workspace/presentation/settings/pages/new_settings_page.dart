import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/settings/pages/new_settings_left_menu.dart';
import 'package:appflowy/workspace/presentation/settings/pages/new_settings_account_page.dart';

enum NewSettingsPageType {
  account,
  general,
  spaceManagement,
  memberManagement,
  sharePublish,
  notifications,
  storage,
  aboutPony,
}

class NewSettingsPage extends StatefulWidget {
  const NewSettingsPage({super.key});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage> {
  NewSettingsPageType selectedPage = NewSettingsPageType.general;

  void _onPageSelected(NewSettingsPageType page) {
    setState(() {
      selectedPage = page;
    });
  }

  Widget _buildContentPage() {
    switch (selectedPage) {
      case NewSettingsPageType.account:
        return const NewSettingsAccountPage();
      case NewSettingsPageType.general:
        return const Center(child: Text('通用设置'));
      case NewSettingsPageType.spaceManagement:
        return const Center(child: Text('空间管理'));
      case NewSettingsPageType.memberManagement:
        return const Center(child: Text('人员管理'));
      case NewSettingsPageType.sharePublish:
        return const Center(child: Text('共享发布'));
      case NewSettingsPageType.notifications:
        return const Center(child: Text('通知设置'));
      case NewSettingsPageType.storage:
        return const Center(child: Text('存储设置'));
      case NewSettingsPageType.aboutPony:
        return const Center(child: Text('关于小马'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Container(
            width: 1440,
            height: 980,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://lanhu-oss-proxy.lanhuapp.com/SketchPngdfee845111ee625df15c6b61bcd91f9334bea244f143c1ababdab4534e364b5c'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 300, top: 136),
              child: Container(
                width: 1141,
                height: 709,
                child: Row(
                  children: [
                    // 左侧菜单栏
                    NewSettingsLeftMenu(
                      selectedPage: selectedPage,
                      onPageSelected: _onPageSelected,
                    ),
                    // 右侧内容区域
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: _buildContentPage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 关闭按钮
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
