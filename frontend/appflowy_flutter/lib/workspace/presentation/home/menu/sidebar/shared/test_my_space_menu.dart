import 'package:flutter/material.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'sidebar_my_space_menu.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的空间菜单测试',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MySpaceMenuTestPage(),
    );
  }
}

class MySpaceMenuTestPage extends StatelessWidget {
  const MySpaceMenuTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的空间菜单测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // 左侧边栏
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 应用标题
                    Row(
                      children: [
                        Icon(Icons.home, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '小马笔记',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // 主导航菜单
                    _NavigationItem(
                      icon: Icons.dashboard,
                      title: '主页',
                      isSelected: true,
                    ),
                    _NavigationItem(
                      icon: Icons.chat_bubble_outline,
                      title: '问AI',
                    ),
                    _NavigationItem(
                      icon: Icons.calendar_today,
                      title: '日历',
                    ),
                    _NavigationItem(
                      icon: Icons.inbox,
                      title: '收件箱',
                    ),
                    _NavigationItem(
                      icon: Icons.integration_instructions,
                      title: '集成',
                    ),
                    _NavigationItem(
                      icon: Icons.star_border,
                      title: '最爱',
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 我的空间菜单
                    SidebarMySpaceMenu(),
                    
                    SizedBox(height: 24),
                    
                    // 底部菜单
                    _NavigationItem(
                      icon: Icons.people,
                      title: '我的团队',
                    ),
                    _NavigationItem(
                      icon: Icons.share,
                      title: '共享',
                    ),
                    _NavigationItem(
                      icon: Icons.publish,
                      title: '发布',
                    ),
                    _NavigationItem(
                      icon: Icons.folder,
                      title: '文件库',
                    ),
                    _NavigationItem(
                      icon: Icons.dashboard_customize,
                      title: '模版',
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 右侧内容区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '测试说明',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '左侧是我的空间菜单测试区域，请测试以下功能：',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  _TestInstruction(
                    title: '1. 主菜单展开/收起',
                    description: '点击左侧箭头或"我的空间"标题可以展开/收起整个菜单',
                  ),
                  _TestInstruction(
                    title: '2. 全局展开/收起',
                    description: '点击右侧箭头可以展开/收起所有子项目',
                  ),
                  _TestInstruction(
                    title: '3. 单个项目展开/收起',
                    description: '点击单个项目的箭头可以展开/收起该项目',
                  ),
                  _TestInstruction(
                    title: '4. 添加新项目',
                    description: '点击"+"按钮可以添加新的文件夹、笔记本或笔记',
                  ),
                  SizedBox(height: 16),
                  Text(
                    '注意：现在只有一个"我的空间"标题，下面直接是子菜单项，没有重复的菜单。',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange,
                    ),
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

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;

  const _NavigationItem({
    required this.icon,
    required this.title,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tileColor: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
    );
  }
}

class _TestInstruction extends StatelessWidget {
  final String title;
  final String description;

  const _TestInstruction({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
