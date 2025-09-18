import 'package:flutter/material.dart';

/// AI欢迎页面的主题常量，基于设计图精确配置
class AIWelcomeTheme {
  /// 颜色配置
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color primaryTextColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF888888);
  static const Color placeholderTextColor = Color(0xFFAAAAAA);
  static const Color borderColor = Color(0xFFE9E9E9);
  static const Color inputBorderColor = Color(0xFFCDCDCD);
  static const Color dividerColor = Color(0xFFD8D8D8);

  /// 字体大小配置（基于设计图）
  static const double titleFontSize = 24.0;        // text_15
  static const double subtitleFontSize = 18.0;     // text_16
  static const double placeholderFontSize = 16.0;  // text_17
  static const double tooltipFontSize = 14.0;      // text_18, text-group_14

  /// 字体权重配置
  static const FontWeight titleFontWeight = FontWeight.w600;     // PingFangSC-Semibold
  static const FontWeight subtitleFontWeight = FontWeight.normal; // PingFangSC-Regular
  static const FontWeight placeholderFontWeight = FontWeight.w500; // PingFangSC-Medium

  /// 尺寸配置（基于设计图CSS）
  static const double avatarSize = 60.0;           // group_1: 60x60
  static const double containerBorderRadius = 10.0; // block_3: border-radius: 10px
  static const double buttonBorderRadius = 4.0;    // block_4: border-radius: 4px
  static const double iconSize = 30.0;             // label_5-8: 25x25
  static const double sendButtonSize = 35.0;       // label_9: 35x35
  static const double toolbarButtonSize = 30.0;    // block_4: height: 30px

  /// 边距配置（基于设计图CSS）
  static const EdgeInsets welcomeAreaPadding = EdgeInsets.fromLTRB(351, 215, 0, 0); // block_1 margin
  static const EdgeInsets subtitlePadding = EdgeInsets.fromLTRB(309, 20, 0, 0);     // text_16 margin
  static const EdgeInsets inputContainerPadding = EdgeInsets.fromLTRB(95, 30, 95, 0); // block_3 margin
  static const EdgeInsets inputTextPadding = EdgeInsets.fromLTRB(20, 20, 20, 0);      // text-wrapper_5 margin
  static const EdgeInsets toolbarPadding = EdgeInsets.fromLTRB(20, 15, 20, 13);      // group_2 margin - 减少顶部边距避免溢出

  /// 容器尺寸配置
  static const double inputContainerWidth = 950.0; // block_3: width: 950px
  static const double inputContainerHeight = 160.0; // block_3: height: 160px
  static const double toolbarWidth = 910.0;        // group_2: width: 910px
  static const double toolbarHeight = 35.0;        // group_2: height: 35px

  /// 文本样式
  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: titleFontWeight,
    color: primaryTextColor,
    height: 33 / 24, // line-height: 33px / font-size: 24px
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: subtitleFontSize,
    fontWeight: subtitleFontWeight,
    color: primaryTextColor,
    height: 25 / 18, // line-height: 25px / font-size: 18px
  );

  static const TextStyle placeholderStyle = TextStyle(
    fontSize: placeholderFontSize,
    fontWeight: placeholderFontWeight,
    color: secondaryTextColor,
    height: 22 / 16, // line-height: 22px / font-size: 16px
  );

  static const TextStyle tooltipStyle = TextStyle(
    fontSize: tooltipFontSize,
    fontWeight: FontWeight.normal,
    color: Color(0xFF939393), // 基于设计图的具体颜色
    height: 20 / 14, // line-height: 20px / font-size: 14px
  );

  static const TextStyle modelSelectorStyle = TextStyle(
    fontSize: tooltipFontSize,
    fontWeight: FontWeight.normal,
    color: Color(0xFF636363), // text-group_14 color
    height: 20 / 14,
  );

  /// 头像样式
  static const BoxDecoration avatarDecoration = BoxDecoration(
    shape: BoxShape.circle,
    border: Border.fromBorderSide(
      BorderSide(
        color: Color(0xFFECECEC), // rgba(236, 236, 236, 1)
        width: 0.59, // 0.5911330049261083px
      ),
    ),
  );

  /// 输入容器样式
  static const BoxDecoration inputContainerDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.all(Radius.circular(containerBorderRadius)),
    border: Border.fromBorderSide(
      BorderSide(color: borderColor, width: 1.0),
    ),
  );

  /// 模型选择按钮样式
  static const BoxDecoration modelSelectorDecoration = BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.all(Radius.circular(buttonBorderRadius)),
    border: Border.fromBorderSide(
      BorderSide(color: inputBorderColor, width: 1.0),
    ),
  );

  /// 分隔线样式
  static const BoxDecoration dividerDecoration = BoxDecoration(
    color: dividerColor,
  );
}
