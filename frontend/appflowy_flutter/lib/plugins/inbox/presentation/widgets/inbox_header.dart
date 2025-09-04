import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';

class InboxHeader extends StatelessWidget {
  final VoidCallback? onToggleLeftPanel;
  
  const InboxHeader({
    super.key,
    this.onToggleLeftPanel,
  });

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
                  onToggleLeftPanel?.call();
                },
              ),
              
              const SizedBox(width: 10),
              
              // 排序按钮
              _buildIconButton(
                icon: FlowySvgs.database_sort_s,
                onTap: () {
                  // TODO: 实现排序功能
                },
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
    required FlowySvgData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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

}
