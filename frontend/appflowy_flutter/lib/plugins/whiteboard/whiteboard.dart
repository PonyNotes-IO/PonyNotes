library;

import 'package:appflowy/features/page_access_level/logic/page_access_level_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/whiteboard/application/whiteboard_bloc.dart';
import 'package:appflowy/plugins/whiteboard/application/drawing_models.dart';
import 'package:appflowy/plugins/whiteboard/presentation/whiteboard_painter.dart';

class WhiteboardPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return WhiteboardPlugin(pluginType: pluginType, view: data);
    }

    throw FlowyPluginException.invalidData;
  }

  @override
  String get menuName => "白板";

  @override
  FlowySvgData get icon => FlowySvgs.icon_board_s; // 暂时使用看板图标，后续可替换为专用白板图标

  @override
  PluginType get pluginType => PluginType.whiteboard;

  @override
  ViewLayoutPB? get layoutType => ViewLayoutPB.Whiteboard;
}

class WhiteboardPlugin extends Plugin {
  WhiteboardPlugin({
    required ViewPB view,
    required PluginType pluginType,
  }) : notifier = ViewPluginNotifier(view: view) {
    _pluginType = pluginType;
  }

  @override
  late final ViewPluginNotifier notifier;
  late final PluginType _pluginType;
  late final PageAccessLevelBloc _pageAccessLevelBloc;

  @override
  PluginWidgetBuilder get widgetBuilder => WhiteboardPluginWidgetBuilder(
        notifier: notifier,
        pageAccessLevelBloc: _pageAccessLevelBloc,
      );

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get pluginType => _pluginType;

  @override
  void init() {
    _pageAccessLevelBloc = PageAccessLevelBloc(view: notifier.view)
      ..add(const PageAccessLevelEvent.initial());
  }

  @override
  void dispose() {
    _pageAccessLevelBloc.close();
    notifier.dispose();
  }
}

class WhiteboardPluginWidgetBuilder extends PluginWidgetBuilder {
  WhiteboardPluginWidgetBuilder({
    required this.notifier,
    required this.pageAccessLevelBloc,
  });

  final ViewPluginNotifier notifier;
  final PageAccessLevelBloc pageAccessLevelBloc;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => WhiteboardBloc(),
        ),
        BlocProvider<PageAccessLevelBloc>.value(
          value: pageAccessLevelBloc,
        ),
      ],
      child: WhiteboardPage(
        view: notifier.view,
        onViewChanged: (view) => notifier.view = view,
      ),
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  String? get viewName => notifier.view.nameOrDefault;

  @override
  Widget get leftBarItem => BlocProvider<PageAccessLevelBloc>.value(
        value: pageAccessLevelBloc,
        child: ViewTitleBar(
          key: ValueKey(notifier.view.id),
          view: notifier.view,
        ),
      );

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      ViewTabBarItem(view: notifier.view, shortForm: shortForm);
}

class WhiteboardPage extends StatefulWidget {
  const WhiteboardPage({
    super.key,
    required this.view,
    required this.onViewChanged,
  });

  final ViewPB view;
  final Function(ViewPB) onViewChanged;

  @override
  State<WhiteboardPage> createState() => _WhiteboardPageState();
}

class _WhiteboardPageState extends State<WhiteboardPage> {

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WhiteboardBloc, WhiteboardState>(
      builder: (context, state) {
        final bloc = context.read<WhiteboardBloc>();
        
        return Scaffold(
          appBar: AppBar(
            title: Text('白板 - ${widget.view.name}'),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            actions: [
              // 撤销按钮
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: state.canUndo 
                    ? () => bloc.add(const UndoAction())
                    : null,
                tooltip: '撤销',
              ),
              // 重做按钮  
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: state.canRedo 
                    ? () => bloc.add(const RedoAction())
                    : null,
                tooltip: '重做',
              ),
              // 清空画板
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => bloc.add(const ClearBoard()),
                tooltip: '清空',
              ),
              // 保存按钮
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveWhiteboard,
                tooltip: '保存',
              ),
            ],
          ),
          body: Row(
            children: [
              // 左侧工具栏
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                child: _buildToolbar(state, bloc),
              ),
              // 主绘图区域
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRect(
                    child: Builder(
                      builder: (drawingContext) {
                        return GestureDetector(
                          onPanStart: (details) {
                            final renderBox = drawingContext.findRenderObject() as RenderBox;
                            final localPosition = renderBox.globalToLocal(details.globalPosition);
                            bloc.add(StartDrawing(localPosition));
                          },
                          onPanUpdate: (details) {
                            final renderBox = drawingContext.findRenderObject() as RenderBox;
                            final localPosition = renderBox.globalToLocal(details.globalPosition);
                            bloc.add(UpdateDrawing(localPosition));
                          },
                          onPanEnd: (details) {
                            bloc.add(const EndDrawing());
                          },
                          child: Stack(
                            children: [
                              // 网格背景
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: GridPainter(),
                                ),
                              ),
                              // 绘图层
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: WhiteboardPainter(
                                    drawingData: state.drawingData,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar(WhiteboardState state, WhiteboardBloc bloc) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // 画笔工具
        _ToolButton(
          icon: Icons.brush,
          label: '画笔',
          isSelected: state.selectedTool == DrawingTool.pen,
          onTap: () => bloc.add(const SelectTool(DrawingTool.pen)),
        ),
        // 直线工具
        _ToolButton(
          icon: Icons.timeline,
          label: '直线',
          isSelected: state.selectedTool == DrawingTool.line,
          onTap: () => bloc.add(const SelectTool(DrawingTool.line)),
        ),
        // 矩形工具
        _ToolButton(
          icon: Icons.crop_square,
          label: '矩形',
          isSelected: state.selectedTool == DrawingTool.rectangle,
          onTap: () => bloc.add(const SelectTool(DrawingTool.rectangle)),
        ),
        // 圆形工具
        _ToolButton(
          icon: Icons.circle_outlined,
          label: '圆形',
          isSelected: state.selectedTool == DrawingTool.circle,
          onTap: () => bloc.add(const SelectTool(DrawingTool.circle)),
        ),
        // 橡皮擦
        _ToolButton(
          icon: Icons.auto_fix_high,
          label: '橡皮擦',
          isSelected: state.selectedTool == DrawingTool.eraser,
          onTap: () => bloc.add(const SelectTool(DrawingTool.eraser)),
        ),
        const SizedBox(height: 24),
        // 颜色选择
        _buildColorPicker(state, bloc),
        const SizedBox(height: 16),
        // 线条粗细
        _buildStrokeWidthSlider(state, bloc),
      ],
    );
  }

  Widget _buildColorPicker(WhiteboardState state, WhiteboardBloc bloc) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Column(
      children: [
        const Text('颜色', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: colors.map((color) {
            final isSelected = state.selectedColor == color;
            return GestureDetector(
              onTap: () => bloc.add(ChangeColor(color)),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStrokeWidthSlider(WhiteboardState state, WhiteboardBloc bloc) {
    return Column(
      children: [
        const Text('粗细', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        RotatedBox(
          quarterTurns: 3,
          child: Slider(
            value: state.strokeWidth,
            min: 1.0,
            max: 10.0,
            divisions: 9,
            onChanged: (value) => bloc.add(ChangeStrokeWidth(value)),
          ),
        ),
      ],
    );
  }

  void _saveWhiteboard() {
    // TODO: 实现保存功能，与后端集成
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存功能将在后续版本中实现')),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 24,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

