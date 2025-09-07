import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/util/theme_extension.dart';

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
  // AI聊天叠加层可见性状态


  @override
  void dispose() {
    super.dispose();
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

    final userName = widget.userProfile?.name ?? "用户";

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 32.0),
        child: Column(
          children: [
            // 问候语 - 居中显示
            Center(child: _buildGreeting(greeting, userName)),
            const SizedBox(height: 16),

            // 问AI标题
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  const FlowySvg(
                    FlowySvgs.icon_ai_s,
                    size: Size.square(24),
                  ),
                  const SizedBox(width: 12.0),
                  const Text(
                    "问AI",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 三个区域并排展示
            Column(
              children: [
                // 问AI区域
                _buildAISection(),
                const SizedBox(height: 32),

                // 最近访问标题
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 24,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12.0),
                      const Text(
                        "最近访问",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // 最近访问
                _buildRecentSection(),
                const SizedBox(height: 32),

                // 待办计划标题
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 24,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12.0),
                      const Text(
                        "待办计划",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

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
        color: isLightMode ? const Color(0xFF2F3349) : const Color(0xFF2F3349),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          // 主要输入框
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3F5C),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    "在小马笔记中可以问或找到每一件事...",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          
          // 功能按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 选择模型下拉框
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4F6C),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "选择模型",
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // 右侧功能按钮
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.image_outlined,
                    onTap: () {
                      // 处理图片功能
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.language,
                    onTap: () {
                      // 处理语言功能
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.attach_file_outlined,
                    onTap: () {
                      // 处理附件功能
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.more_horiz,
                    onTap: () {
                      // 处理更多功能
                    },
                  ),
                  const SizedBox(width: 8),
                  // 发送按钮
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.send,
                      size: 16,
                      color: Colors.white,
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4F6C),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey.shade300,
        ),
      ),
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
          // 将日历和待办列表水平排列
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 日历部分 - 占据较小的固定宽度
                SizedBox(
                  width: 240,
                  child: _buildCalendarSection(),
                ),
                // 分割线 - 自动适应高度并居中
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isLightMode ? Colors.grey.shade300 : const Color(0xFF4A4D52),
                  ),
                ),
                // 待办列表部分 - 占据剩余空间
                Expanded(
                  child: _buildTodoList(),
                ),
              ],
            ),
          ),
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
} 