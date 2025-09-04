import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';

class InboxHeader extends StatelessWidget {
  const InboxHeader({super.key});

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
              // 后退按钮
              _buildIconButton(
                icon: FlowySvgs.arrow_left_s,
                onTap: () {
                  // TODO: 实现后退功能
                },
              ),
              
              const SizedBox(width: 10),
              
              // 前进按钮
              _buildIconButton(
                icon: FlowySvgs.arrow_right_s,
                onTap: () {
                  // TODO: 实现前进功能
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
