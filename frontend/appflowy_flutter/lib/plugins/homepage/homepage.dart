import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy/plugins/homepage/widgets/simple_model_selector.dart';
import 'package:appflowy/plugins/interactive_ai_chat/interactive_ai_chat_page.dart';
import 'package:appflowy/core/config/ai_config.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';

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
      HomePage(userProfile: context.userProfile);

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
  final TextEditingController _aiInputController = TextEditingController();
  final FocusNode _aiInputFocusNode = FocusNode();
  String? _selectedModel; // 存储选择的模型

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

  @override
  void dispose() {
    _aiInputController.dispose();
    _aiInputFocusNode.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final text = _aiInputController.text.trim();
    if (text.isEmpty) return;

    // 清空输入框
    _aiInputController.clear();
    
    // 创建独立的AI聊天插件
    try {
      final standaloneAiChatPlugin = makePlugin(
        pluginType: PluginType.standaloneAiChat,
        data: {
          'initialText': text,
          'selectedModelName': _selectedModel, // 传递选择的模型名称（可能为空）
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
                  const Spacer(),
                  // AI聊天按钮
                  ElevatedButton.icon(
                    onPressed: _openInteractiveAIChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('AI聊天'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // 问AI区域
            _buildAISection(),
            const SizedBox(height: 50),

            // 最近访问标题
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Color(0xFF636363),
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    "最近访问",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF636363),
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
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF636363),
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    "待办计划",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF636363),
                    ),
                  ),
                ],
              ),
            ),

            // 待办计划
            _buildTodoSection(),
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

  Widget _buildAISection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI输入框
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFFE9E9E9),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _aiInputController,
              focusNode: _aiInputFocusNode,
              maxLines: null,
              minLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSendMessage(),
              decoration: const InputDecoration(
                hintText: "在小马笔记可以问或找到每一件事…",
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.0),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 功能按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 选择模型下拉框
              SimpleModelSelector(
                onModelChanged: (model) {
                  setState(() {
                    _selectedModel = model;
                  });
                  debugPrint('选择了模型: $model');
                },
              ),
              
              // 右侧功能按钮
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.image_outlined,
                    onTap: () {
                      // 处理图片功能
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.language,
                    onTap: () {
                      // 处理语言功能
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.attach_file_outlined,
                    onTap: () {
                      // 处理附件功能
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildActionButton(
                    icon: Icons.more_horiz,
                    onTap: () {
                      // 处理更多功能
                    },
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFD8D8D8),
                  ),
                  const SizedBox(width: 20),
                  // 发送按钮
                  InkWell(
                    onTap: _handleSendMessage,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8D69), Color(0xFFFF8D69)],
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 25,
          color: const Color(0xFF636363),
        ),
      ),
    );
  }

  Widget _buildRecentSection() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _handleAddNotebook,
        child: Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: const Color(0xFFE9E9E9),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // 顶部灰色区域
              Positioned(
                top: 1,
                left: 1,
                child: Container(
                  width: 130,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                  ),
                ),
              ),
              // 内容区域 - 左对齐显示图标和文字
              Positioned(
                top: 60,
                left: 17,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 添加图标
                    const Icon(
                      Icons.add,
                      size: 25,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(height: 18),
                    // 文字
                    const Text(
                      "添加笔记本",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoSection() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 266,
        maxHeight: 320,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: const Color(0xFFE9E9E9),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日历部分
            Expanded(
              flex: 1,
              child: _buildCalendarSection(),
            ),
            // 分割线
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              color: const Color(0xFFE9E9E9),
            ),
            // 待办列表部分
            Expanded(
              flex: 2,
              child: _buildTodoList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      children: [
        // 图标
        Container(
          width: 58,
          height: 51,
          decoration: const BoxDecoration(
            color: Color(0xFFECD4CC),
          ),
          child: const Center(
            child: Icon(
              Icons.calendar_today,
              size: 40,
              color: Color(0xFF888888),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 标题
        const Text(
          "用日历连接你的生活",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 12),
        // 描述
        const Text(
          "创建待办计划，创建日记，记录你的每个点滴故事.....",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF888888),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 35),
        // 链接按钮
        GestureDetector(
          onTap: () {
            _openCalendar();
          },
          child: const Text(
            "链接我的日历",
            style: TextStyle(
              color: Color(0xFFFF8D69),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：待办标题和日期
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "待办",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 今天
                    const Text(
                      "今天",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const Text(
                      "7月11日",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 周六
                    const Text(
                      "周六",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const Text(
                      "7月12日",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              // 中间：竖线
              Container(
                width: 18,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 69),
                    Container(
                      width: 2,
                      height: 51,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 31),
                    Container(
                      width: 2,
                      height: 51,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧：时间和事件
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 68),
                    // 今天的事件
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 35,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "8:00",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "11:00",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "起床与张总开会",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "读研分享会",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // 周六的事件
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 35,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "17:00",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "19:00",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "喝茶",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "年会",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF888888),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCalendar() {
    try {
      final calendarPlugin = makePlugin(
        pluginType: PluginType.calendar,
        data: null,
      );

      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: calendarPlugin,
        ),
      );
    } catch (e) {
      // 处理错误
    }
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
          // 显示创建成功消息
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('笔记本创建成功！'),
                duration: Duration(seconds: 2),
              ),
            );
          }
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
}