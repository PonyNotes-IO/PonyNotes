import 'package:flutter/material.dart';

// 绘图工具枚举
enum DrawingTool {
  pen,        // 画笔
  line,       // 直线
  rectangle,  // 矩形
  circle,     // 圆形
  eraser,     // 橡皮擦
  text,       // 文本（待实现）
}

// 绘图数据模型
class DrawingPath {
  DrawingPath({
    required this.path,
    required this.paint,
    required this.tool,
    this.startPoint,
    this.endPoint,
  });

  final Path path;
  final Paint paint;
  final DrawingTool tool;
  final Offset? startPoint; // 用于直线、矩形等
  final Offset? endPoint;   // 用于直线、矩形等

  DrawingPath copyWith({
    Path? path,
    Paint? paint,
    DrawingTool? tool,
    Offset? startPoint,
    Offset? endPoint,
  }) {
    return DrawingPath(
      path: path ?? this.path,
      paint: paint ?? this.paint,
      tool: tool ?? this.tool,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
    );
  }
}

// 绘图状态数据
class DrawingData {
  DrawingData({
    this.paths = const [],
    this.currentPath,
    this.isDrawing = false,
  });

  final List<DrawingPath> paths;
  final DrawingPath? currentPath;
  final bool isDrawing;

  DrawingData copyWith({
    List<DrawingPath>? paths,
    DrawingPath? currentPath,
    bool? isDrawing,
  }) {
    return DrawingData(
      paths: paths ?? this.paths,
      currentPath: currentPath,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }
}
