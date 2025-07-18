import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';

class AFLogo extends StatelessWidget {
  const AFLogo({
    super.key,
    this.size = const Size.square(36),
  });

  final Size size;

  @override
  Widget build(BuildContext context) {
    return FlowySvg(
      FlowySvgs.app_logo_xl,
      color: null,  // 禁用主题颜色，保持 SVG 原始颜色
      blendMode: null,
      size: size,
    );
  }
}
