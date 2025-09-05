import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/inbox/domain/models/sort_option.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_sort_menu.dart';

class InboxHeader extends StatefulWidget {
  final VoidCallback? onToggleLeftPanel;
  final SortOption currentSort;
  final Function(SortOption) onSortChanged;
  final VoidCallback? onMarkAllAsRead;
  
  const InboxHeader({
    super.key,
    this.onToggleLeftPanel,
    required this.currentSort,
    required this.onSortChanged,
    this.onMarkAllAsRead,
  });

  @override
  State<InboxHeader> createState() => _InboxHeaderState();
}

class _InboxHeaderState extends State<InboxHeader> with TickerProviderStateMixin {
  bool _isMenuVisible = false;
  bool _isMoreMenuVisible = false;
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _moreButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _moreOverlayEntry;
  late AnimationController _animationController;
  late AnimationController _moreAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _moreFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _moreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _moreFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _moreAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          // 收件箱标题
          const Text(
            '收件箱',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          
          const Spacer(),
          
          // 操作按钮组
          Row(
            children: [
              // 双左箭头按钮
              _buildIconButton(
                icon: FlowySvgs.double_back_arrow_m,
                onTap: () {
                  widget.onToggleLeftPanel?.call();
                },
              ),
              
              const SizedBox(width: 10),
              
              // 排序按钮
              GestureDetector(
                key: _sortButtonKey,
                onTap: _toggleSortMenu,
                child: Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  child: FlowySvg(
                    FlowySvgs.database_sort_s,
                    size: const Size.square(20),
                    color: _isMenuVisible 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFF666666),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // 更多选项按钮
              _buildIconButton(
                key: _moreButtonKey,
                icon: FlowySvgs.three_dots_s,
                onTap: _toggleMoreMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    Key? key,
    required FlowySvgData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: SizedBox(
        width: 24,
        height: 24,
        child: FlowySvg(
          icon,
          size: const Size.square(24),
          color: const Color(0xFF666666),
        ),
      ),
    );
  }

  void _toggleSortMenu() {
    print('🔧 排序按钮被点击！当前菜单状态: $_isMenuVisible -> ${!_isMenuVisible}');
    
    if (_isMenuVisible) {
      _hideMenu();
    } else {
      _showMenu();
    }
  }
  
  void _showMenu() {
    if (_overlayEntry != null) {
      _hideMenu();
      return;
    }
    
    setState(() {
      _isMenuVisible = true;
    });
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }
  
  void _hideMenu() async {
    if (_overlayEntry != null) {
      await _animationController.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    
    setState(() {
      _isMenuVisible = false;
    });
  }

  void _toggleMoreMenu() {
    print('🔧 更多选项按钮被点击！当前菜单状态: $_isMoreMenuVisible -> ${!_isMoreMenuVisible}');
    
    if (_isMoreMenuVisible) {
      _hideMoreMenu();
    } else {
      _showMoreMenu();
    }
  }
  
  void _showMoreMenu() {
    if (_moreOverlayEntry != null) {
      _hideMoreMenu();
      return;
    }
    
    setState(() {
      _isMoreMenuVisible = true;
    });
    
    _moreOverlayEntry = _createMoreOverlayEntry();
    Overlay.of(context).insert(_moreOverlayEntry!);
    _moreAnimationController.forward();
  }
  
  void _hideMoreMenu() async {
    if (_moreOverlayEntry != null) {
      await _moreAnimationController.reverse();
      _moreOverlayEntry?.remove();
      _moreOverlayEntry = null;
    }
    
    setState(() {
      _isMoreMenuVisible = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    print('🎯 正在创建Overlay菜单...');
    
    // 获取排序按钮的位置
    final RenderBox? renderBox = _sortButtonKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? buttonPosition;
    
    if (renderBox != null) {
      buttonPosition = renderBox.localToGlobal(Offset.zero);
      print('📍 按钮位置: $buttonPosition');
    } else {
      print('❌ 无法获取按钮位置！');
    }
    
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明的点击区域，用于关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 菜单本身
          Positioned(
            top: (buttonPosition?.dy ?? 70) + 35, // 在按钮下方显示
            left: math.max(0, (buttonPosition?.dx ?? 100) - 80), // 菜单左边缘对齐按钮中心，但确保不超出屏幕
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: 0.9 + (_fadeAnimation.value * 0.1), // 轻微的缩放效果
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击菜单时关闭
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InboxSortMenu(
                          currentSort: widget.currentSort,
                          onSortChanged: (sortOption) {
                            widget.onSortChanged(sortOption);
                            _hideMenu();
                          },
                          onClose: _hideMenu,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  OverlayEntry _createMoreOverlayEntry() {
    print('🎯 正在创建更多选项菜单...');
    
    // 获取更多选项按钮的位置和尺寸
    final RenderBox? renderBox = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    Offset? buttonPosition;
    Size? buttonSize;
    
    if (renderBox != null) {
      buttonPosition = renderBox.localToGlobal(Offset.zero);
      buttonSize = renderBox.size;
      print('📍 更多按钮位置: $buttonPosition, 尺寸: $buttonSize');
    } else {
      print('❌ 无法获取更多按钮位置');
      buttonPosition = const Offset(100, 70);
      buttonSize = const Size(40, 40);
    }

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 透明背景，点击关闭菜单
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideMoreMenu,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // 菜单本身
          Positioned(
            top: (buttonPosition?.dy ?? 70) + (buttonSize?.height ?? 40) + 4, // 紧贴按钮下方
            left: (buttonPosition?.dx ?? 100) + (buttonSize?.width ?? 40) - 160, // 菜单右边缘对齐按钮右边缘
            child: AnimatedBuilder(
              animation: _moreFadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _moreFadeAnimation,
                  child: Transform.scale(
                    scale: 0.9 + (_moreFadeAnimation.value * 0.1), // 轻微的缩放效果
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击菜单时关闭
                      child: Container(
                        width: 160, // 增加菜单宽度以避免溢出
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMoreMenuItem(
                              icon: Icons.done_all,
                              title: '全部标记为已读',
                              onTap: () {
                                _hideMoreMenu();
                                widget.onMarkAllAsRead?.call();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 设置主轴大小为最小
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF666666),
            ),
            const SizedBox(width: 8),
            Flexible( // 使用Flexible包装文本以处理溢出
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF333333),
                ),
                overflow: TextOverflow.ellipsis, // 添加省略号处理
                maxLines: 1, // 限制为单行
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _moreAnimationController.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _moreOverlayEntry?.remove();
    _moreOverlayEntry = null;
    super.dispose();
  }
}
