import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AFLogo extends StatelessWidget {
  const AFLogo({
    super.key,
    this.size = const Size.square(36),
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    // 方案1：直接使用 SvgPicture.asset，完全绕过 FlowySvg 组件
    return SvgPicture.asset(
      'assets/flowy_icons/40x/app_logo.svg',
      width: size.width,
      height: size.height,
      // 不设置 colorFilter，保持原始颜色
    );
    
    // 方案2：使用 FlowySvg 但设置明确的颜色参数（注释掉）
    // return FlowySvg(
    //   FlowySvgs.app_logo_xl,
    //   color: Colors.transparent,  // 设置为透明色，避免使用主题色
    //   blendMode: null,  // 禁用混合模式
    //   size: size,
    // );
  }
}
