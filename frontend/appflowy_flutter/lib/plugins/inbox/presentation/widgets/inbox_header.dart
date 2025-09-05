import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/inbox/domain/models/sort_option.dart';
import 'package:appflowy/plugins/inbox/presentation/widgets/inbox_sort_menu.dart';

class InboxHeader extends StatefulWidget {
  final VoidCallback? onToggleLeftPanel;
  final SortOption currentSort;
  final Function(SortOption) onSortChanged;
  
  const InboxHeader({
    super.key,
    this.onToggleLeftPanel,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  State<InboxHeader> createState() => _InboxHeaderState();
}

class _InboxHeaderState extends State<InboxHeader> with TickerProviderStateMixin {
  bool _isMenuVisible = false;
  final GlobalKey _sortButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
                icon: FlowySvgs.three_dots_s,
                onTap: () {
                  // TODO: 实现更多选项功能
                },
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
  
  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}
