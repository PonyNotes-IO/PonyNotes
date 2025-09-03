import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class SidebarFavoriteButton extends StatefulWidget {
  const SidebarFavoriteButton({super.key});

  @override
  State<SidebarFavoriteButton> createState() => _SidebarFavoriteButtonState();
}

class _SidebarFavoriteButtonState extends State<SidebarFavoriteButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavoriteBloc()..add(const FavoriteEvent.initial()),
      child: BlocBuilder<FavoriteBloc, FavoriteState>(
        builder: (context, state) {
          return Column(
            children: [
              // 收藏夹标题行
              _buildFavoriteHeader(context, state),
              // 收藏的页面列表
              if (_isExpanded) ..._buildFavoriteItems(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoriteHeader(BuildContext context, FavoriteState state) {
    final theme = AppFlowyTheme.of(context);
    final favoriteCount = state.views.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius.s),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(theme.borderRadius.s),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  // 收藏夹图标
                  FlowySvg(
                    FlowySvgs.icon_favorite_s,
                    size: const Size.square(16.0),
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  // 收藏夹文本
                  Expanded(
                    child: FlowyText.medium(
                      '最爱',
                      fontSize: 14.0,
                      figmaLineHeight: 17.0,
                      color: AppFlowyTheme.of(context).textColorScheme.primary,
                    ),
                  ),
                  // 收藏数量
                  if (favoriteCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FlowyText(
                        favoriteCount.toString(),
                        fontSize: 10,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  const SizedBox(width: 4),
                  // 展开/收起箭头
                  Icon(
                    _isExpanded 
                        ? Icons.keyboard_arrow_down 
                        : Icons.keyboard_arrow_right,
                    size: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFavoriteItems(BuildContext context, FavoriteState state) {
    if (state.views.isEmpty) {
      return [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 20), // 缩进
                Icon(
                  Icons.favorite_border,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FlowyText(
                    '暂无收藏',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return state.views.map((sectionView) {
      final view = sectionView.item;
      return _buildFavoriteItem(context, view);
    }).toList();
  }

  Widget _buildFavoriteItem(BuildContext context, ViewPB view) {
    final theme = AppFlowyTheme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius.s),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(theme.borderRadius.s),
            onTap: () {
              // 打开收藏的页面
              context.read<TabsBloc>().openPlugin(view);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 20), // 缩进，与展开箭头对齐
                  // 页面类型图标
                  _getViewIcon(view),
                  const SizedBox(width: 8),
                  // 页面名称
                  Expanded(
                    child: FlowyText(
                      view.name.isEmpty ? '未命名' : view.name,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getViewIcon(ViewPB view) {
    IconData iconData;
    Color? iconColor;
    
    switch (view.layout) {
      case ViewLayoutPB.Document:
        iconData = Icons.description_outlined;
        break;
      case ViewLayoutPB.Grid:
        iconData = Icons.table_chart_outlined;
        break;
      case ViewLayoutPB.Board:
        iconData = Icons.view_kanban_outlined;
        break;
      case ViewLayoutPB.Calendar:
        iconData = Icons.calendar_today_outlined;
        break;
      case ViewLayoutPB.Chat:
        iconData = Icons.chat_outlined;
        break;
      default:
        iconData = Icons.description_outlined;
    }
    
    return Icon(
      iconData,
      size: 14,
      color: iconColor ?? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
    );
  }
}


