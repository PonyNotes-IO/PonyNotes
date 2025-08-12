import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:get_it/get_it.dart';

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

    final userName = widget.userProfile?.name ?? "用户";

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // 问候语 - 居中显示
            Center(child: _buildGreeting(greeting, userName)),
            const SizedBox(height: 32),

            // 三个区域并排展示
            Column(
              children: [
                // 问AI区域
                _buildAISection(),
                const SizedBox(height: 24),

                // 最近访问
                _buildRecentSection(),
                const SizedBox(height: 24),

                // 待办计划
                _buildTodoSection(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String greeting, String userName) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlowySvg(
            FlowySvgs.app_logo_xl,
            size: Size.square(60),
            blendMode: null,
          ),
          const SizedBox(width: 16), // logo和文字之间的间距
          Text(
            "$greeting, $userName~",
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISection() {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade50 : const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isLightMode ? Colors.grey.shade200 : const Color(0xFF3A3D42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FlowySvg(
                FlowySvgs.icon_ai_s,
                size: Size.square(20),
              ),
              const SizedBox(width: 8.0),
              const Text(
                "问AI",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: () {
              _openAIChat();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isLightMode ? Colors.white : const Color(0xFF36393F),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isLightMode ? Colors.grey.shade300 : const Color(0xFF4A4D52),
                ),
              ),
              child: Row(
                children: [
                  FlowySvg(
                    FlowySvgs.icon_ai_s,
                    size: const Size.square(16),
                    color: isLightMode ? Colors.grey : const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    "在小马笔记中问您想了解的事情...",
                    style: TextStyle(
                      color: isLightMode ? Colors.grey : const Color(0xFF9E9E9E),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            children: [
              _buildSuggestionChip("选择模型"),
              _buildSuggestionChip("智能摘要"),
              _buildSuggestionChip("数据分析"),
              _buildSuggestionChip("创意写作"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isLightMode = Theme.of(context).isLightMode;
    return ActionChip(
      label: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
      onPressed: () {
        _openAIChat();
      },
      backgroundColor: isLightMode ? Colors.white : const Color(0xFF36393F),
      side: BorderSide(
        color: isLightMode ? Colors.grey.shade300 : const Color(0xFF4A4D52),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildRecentSection() {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isLightMode ? Colors.grey.shade200 : const Color(0xFF3A3D42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time, 
                size: 18, 
                color: isLightMode ? Colors.grey : const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              const Text(
                "最近访问",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentItem("添加笔记本", "创建您的第一个笔记本"),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String title, String subtitle) {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade50 : const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isLightMode ? Colors.blue.shade100 : const Color(0xFF4F5B62),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.add, 
              color: isLightMode ? Colors.blue : const Color(0xFF7289DA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLightMode ? Colors.grey.shade600 : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoSection() {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : const Color(0xFF2C2F33),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isLightMode ? Colors.grey.shade200 : const Color(0xFF3A3D42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.task_alt, 
                size: 18, 
                color: isLightMode ? Colors.grey : const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              const Text(
                "待办计划",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarSection(),
          const SizedBox(height: 16),
          _buildTodoList(),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade50 : const Color(0xFF36393F),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isLightMode ? Colors.grey.shade400 : const Color(0xFF4F5B62),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Text(
              "MAY",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "26",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "用日历连接你的生活",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "创建待办计划，创建日记，记录你的每个点滴故事....",
            style: TextStyle(
              fontSize: 12,
              color: isLightMode ? Colors.grey.shade600 : const Color(0xFF9E9E9E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              _openCalendar();
            },
            child: const Text(
              "链接我的日历",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "待办",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildTodoItem("今天", "7月11日", [
          "8:00 起床与晨总会",
          "11:00 课研分享会",
        ]),
        const SizedBox(height: 12),
        _buildTodoItem("明天", "7月12日", [
          "17:00 喝茶",
          "19:00 年会",
        ]),
      ],
    );
  }

  Widget _buildTodoItem(String day, String date, List<String> tasks) {
    final isLightMode = Theme.of(context).isLightMode;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade50 : const Color(0xFF4A4D52),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: isLightMode ? Colors.grey.shade600 : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  task,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLightMode ? Colors.grey.shade700 : const Color(0xFFB0B0B0),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _openAIChat() {
    try {
      final aiChatPlugin = makePlugin(
        pluginType: PluginType.standaloneAiChat,
        data: null,
      );

      getIt<TabsBloc>().add(
        TabsEvent.openPlugin(
          plugin: aiChatPlugin,
        ),
      );
    } catch (e) {
      // 处理错误
      debugPrint('打开AI聊天时发生错误: $e');
    }
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
      debugPrint('打开日历时发生错误: $e');
    }
  }
} 