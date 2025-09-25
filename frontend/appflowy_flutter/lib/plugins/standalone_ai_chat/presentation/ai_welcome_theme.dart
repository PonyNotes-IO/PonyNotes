import 'package:flutter/material.dart';

/// AI欢迎页面的主题常量，基于设计图精确配置
/// 支持深色主题适配
class AIWelcomeTheme {
  /// 动态颜色配置 - 根据当前主题返回相应颜色
  static Color backgroundColor(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color primaryTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color secondaryTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color placeholderTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);
  static Color borderColor(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color inputBorderColor(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color dividerColor(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color containerColor(BuildContext context) => Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color avatarBackgroundColor(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
  static Color avatarIconColor(BuildContext context) => Theme.of(context).colorScheme.onPrimaryContainer;
  static Color tooltipTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8);
  static Color modelSelectorTextColor(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static Color dropdownBackgroundColor(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color dropdownBorderColor(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color selectedItemColor(BuildContext context) => Theme.of(context).colorScheme.primaryContainer;
  static Color selectedItemTextColor(BuildContext context) => Theme.of(context).colorScheme.onPrimaryContainer;

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

  /// 动态文本样式 - 根据当前主题返回相应样式
  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: titleFontSize,
    fontWeight: titleFontWeight,
    color: primaryTextColor(context),
    height: 33 / 24, // line-height: 33px / font-size: 24px
  );

  static TextStyle subtitleStyle(BuildContext context) => TextStyle(
    fontSize: subtitleFontSize,
    fontWeight: subtitleFontWeight,
    color: primaryTextColor(context),
    height: 25 / 18, // line-height: 25px / font-size: 18px
  );

  static TextStyle placeholderStyle(BuildContext context) => TextStyle(
    fontSize: placeholderFontSize,
    fontWeight: placeholderFontWeight,
    color: placeholderTextColor(context),
    height: 22 / 16, // line-height: 22px / font-size: 16px
  );

  static TextStyle tooltipStyle(BuildContext context) => TextStyle(
    fontSize: tooltipFontSize,
    fontWeight: FontWeight.normal,
    color: tooltipTextColor(context),
    height: 20 / 14, // line-height: 20px / font-size: 14px
  );

  static TextStyle modelSelectorStyle(BuildContext context) => TextStyle(
    fontSize: tooltipFontSize,
    fontWeight: FontWeight.normal,
    color: modelSelectorTextColor(context),
    height: 20 / 14,
  );

  /// 动态装饰样式 - 根据当前主题返回相应装饰
  static BoxDecoration avatarDecoration(BuildContext context) => BoxDecoration(
    color: avatarBackgroundColor(context),
    shape: BoxShape.circle,
    border: Border.all(
      color: borderColor(context),
      width: 0.59,
    ),
  );

  /// 输入容器样式
  static BoxDecoration inputContainerDecoration(BuildContext context) => BoxDecoration(
    color: backgroundColor(context),
    borderRadius: const BorderRadius.all(Radius.circular(containerBorderRadius)),
    border: Border.all(color: borderColor(context), width: 1.0),
  );

  /// 模型选择按钮样式
  static BoxDecoration modelSelectorDecoration(BuildContext context) => BoxDecoration(
    color: backgroundColor(context),
    borderRadius: const BorderRadius.all(Radius.circular(buttonBorderRadius)),
    border: Border.all(color: inputBorderColor(context), width: 1.0),
  );

  /// 分隔线样式
  static BoxDecoration dividerDecoration(BuildContext context) => BoxDecoration(
    color: dividerColor(context),
  );

  /// 下拉框样式
  static BoxDecoration dropdownDecoration(BuildContext context) => BoxDecoration(
    color: dropdownBackgroundColor(context),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: dropdownBorderColor(context)),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// 图片预览区域样式
  static BoxDecoration imagePreviewAreaDecoration(BuildContext context) => BoxDecoration(
    color: containerColor(context),
    border: Border(
      bottom: BorderSide(color: borderColor(context), width: 1),
    ),
  );

  /// 图片预览项样式
  static BoxDecoration imagePreviewItemDecoration(BuildContext context) => BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: borderColor(context)),
  );
}
