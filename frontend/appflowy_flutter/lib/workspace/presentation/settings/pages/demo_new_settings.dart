import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/settings/pages/new_settings_page.dart';

class DemoNewSettingsRoute extends StatelessWidget {
  const DemoNewSettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小马笔记设置',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'PingFang SC',
      ),
      home: const NewSettingsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// 可以在main.dart中运行这个演示
void main() {
  runApp(const DemoNewSettingsRoute());
}
