import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy/plugins/homepage/widgets/todo_plan_section.dart';
import 'package:appflowy/plugins/interactive_ai_chat/interactive_ai_chat_page.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'package:appflowy/plugins/standalone_ai_chat/presentation/widgets/ai_input_area.dart';
import 'package:appflowy/plugins/standalone_ai_chat/models/chat_image.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePagePluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    return HomePagePlugin();
  }

  @override
  String get menuName => "主页";

  @override
  FlowySvgData get icon => FlowySvgs.icon_home_s;

  @override
  PluginType get pluginType => PluginType.homepage;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Document;
}

class HomePagePluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
}

class HomePagePlugin extends Plugin {
  @override
  PluginWidgetBuilder get widgetBuilder => HomePagePluginWidgetBuilder();

  @override
  PluginId get id => "homepage";

  @override
  PluginType get pluginType => PluginType.homepage;
}

class HomePagePluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  @override
  String? get viewName => null; // 移除标题栏显示的"主页"

  @override
  Widget get leftBarItem => const SizedBox.shrink(); // 移除左侧栏显示的"主页"

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) => const SizedBox.shrink(); // 移除标签栏显示的"主页"

  @override
  EdgeInsets get contentPadding => const EdgeInsets.fromLTRB(40, 0, 40, 28); // 只移除顶部内边距，保持左右和底部内边距

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) =>
      BlocProvider(
        create: (context) => RecentViewsBloc()..add(const RecentViewsEvent.initial()),
        child: HomePage(userProfile: context.userProfile),
      );

  @override
  List<NavigationItem> get navigationItems => [this];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userProfile});

  final UserProfilePB? userProfile;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeAIConfig();
  }

  /// 初始化AI配置
  Future<void> _initializeAIConfig() async {
    try {
      await AIConfigService.instance.loadConfig();
    } catch (e) {
      debugPrint('主页初始化AI配置失败: $e');
    }
  }

  /// 处理来自AIInputArea的消息发送
  void _handleMessageSent(String message, AIProvider? provider, List<ChatImage>? images) {
    if (message.isEmpty) return;
    
    // 创建独立的AI聊天插件
    try {
      final standaloneAiChatPlugin = makePlugin(
        pluginType: PluginType.standaloneAiChat,
        data: {
          'initialText': message,
          'selectedModelName': provider?.name, // 传递选择的模型名称
          'initialImages': images, // 传递选择的图片
        },
      );

      // 在新标签页中打开独立AI聊天
      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: standaloneAiChatPlugin,
        ),
      );
    } catch (e) {
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开AI聊天时发生错误: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = "上午好";
    } else if (hour < 18) {
      greeting = "下午好";
    } else {
      greeting = "晚上好";
    }

    final userName = widget.userProfile?.name ?? "燕萍";

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 80.0, 0, 32.0),
        child: Column(
          children: [
            // 问候语区域 - 右对齐，与头像一起
            _buildGreetingSection(greeting, userName),
            const SizedBox(height: 50),

            // 问AI区域标题
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/home_ai_icon.png',
                    width: 22,
                    height: 18,
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    "问AI",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF636363),
                    ),
                  ),
                ],
              ),
            ),

            // 问AI区域 - 复用AIInputArea组件
            AIInputArea(
              onMessageSent: _handleMessageSent,
            ),
            const SizedBox(height: 50),

            // 最近访问标题
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    "最近访问",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // 最近访问
            _buildRecentSection(),
            const SizedBox(height: 50),

            // 待办计划标题
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    "待办计划",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // 待办计划
            const TodoPlanSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(String greeting, String userName) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 头像区域
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFECECEC),
                width: 0.59,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/home_avatar.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 问候语文字
          Text(
            "$greeting，$userName～",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRecentSection() {
    return BlocBuilder<RecentViewsBloc, RecentViewsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox(
            height: 132,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 过滤掉可能的无效视图，并限制显示数量
        final validRecentViews = state.views
            .where((sectionView) => sectionView.item.name.isNotEmpty) // 基本验证
            .take(6)
            .toList();

        if (validRecentViews.isEmpty) {
          // 如果没有最近访问的项目，只显示"添加笔记本"卡片
          return Align(
            alignment: Alignment.centerLeft,
            child: _buildAddNotebookCard(),
          );
        }

        return SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: validRecentViews.length + 1, // +1 for the "添加笔记本" card
            itemBuilder: (context, index) {
              if (index == validRecentViews.length) {
                // 最后一个位置显示"添加笔记本"卡片
                return _buildAddNotebookCard();
              }
              
              final recentView = validRecentViews[index];
              return _buildRecentViewCard(recentView.item);
            },
          ),
        );
      },
    );
  }

  void _openInteractiveAIChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InteractiveAIChatPage(),
      ),
    );
  }

  /// 处理添加笔记本点击事件
  void _handleAddNotebook() async {
    try {
      // 获取当前用户和工作空间信息
      final userResult = await UserBackendService.getCurrentUserProfile();
      final workspaceResult = await FolderEventGetCurrentWorkspaceSetting().send();
      
      final userProfile = userResult.fold((user) => user, (error) => null);
      final workspaceId = workspaceResult.fold(
        (setting) => setting.workspaceId,
        (error) => null,
      );
      
      if (userProfile == null || workspaceId == null || workspaceId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取当前用户或工作空间信息'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 使用WorkspaceService创建笔记本视图
      final workspaceService = WorkspaceService(
        workspaceId: workspaceId,
        userId: userProfile.id,
      );

      // 创建Document类型的视图（而不是Notebook类型）
      final result = await workspaceService.createView(
        name: '新笔记本',
        viewSection: ViewSectionPB.Public, // 创建在公共区域，这样在"我的空间"中可见
        layout: ViewLayoutPB.Document, // 使用Document类型，这是稳定可用的类型
        setAsCurrent: true,
      );

      result.fold(
        (view) {
          // 成功创建，打开新创建的视图
          _openView(view);
          
          // 显示成功消息
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('笔记本创建成功'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
          
           // 刷新最近访问列表
           context.read<RecentViewsBloc>().add(RecentViewsEvent.fetchRecentViews());
        },
        (error) {
          // 显示错误消息
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('创建笔记本失败: ${error.msg}'),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建笔记本时发生错误: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 构建最近访问项目的卡片
  Widget _buildRecentViewCard(ViewPB view) {
    return Container(
      width: 132,
      height: 132,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _openView(view),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // 顶部灰色区域
              Positioned(
                top: 1,
                left: 1,
                right: 1,
                child: Container(
                  height: 65,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8D69).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                       child: const Icon(
                         Icons.description,
                         size: 24,
                         color: Color(0xFFFF8D69),
                       ),
                    ),
                  ),
                ),
              ),
              
              // 底部名称区域
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 66,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        view.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建"添加笔记本"卡片
  Widget _buildAddNotebookCard() {
    return Container(
      width: 132,
      height: 132,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: _handleAddNotebook,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8D69).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 24,
                  color: Color(0xFFFF8D69),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "添加笔记本",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 打开视图
  void _openView(ViewPB view) async {
    try {
       // 使用TabsBloc来打开视图
       final plugin = view.plugin();
       context.read<TabsBloc>().add(
         TabsEvent.openPlugin(
           plugin: plugin,
           view: view,
         ),
       );
    } catch (e) {
      // 显示错误消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打开视图时发生错误: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
