import 'package:flutter/material.dart';
import 'package:appflowy/plugins/whiteboard/application/drawing_models.dart';

class WhiteboardPainter extends CustomPainter {
  WhiteboardPainter({
    required this.drawingData,
  });

  final DrawingData drawingData;

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制已完成的路径
    for (final drawingPath in drawingData.paths) {
      _paintPath(canvas, drawingPath);
    }

    // 绘制当前正在绘制的路径
    if (drawingData.currentPath != null) {
      _paintPath(canvas, drawingData.currentPath!);
    }
  }

  void _paintPath(Canvas canvas, DrawingPath drawingPath) {
    switch (drawingPath.tool) {
      case DrawingTool.eraser:
        // 橡皮擦使用特殊的混合模式
        final eraserPaint = Paint()
          ..color = Colors.transparent
          ..strokeWidth = drawingPath.paint.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.clear;
        canvas.drawPath(drawingPath.path, eraserPaint);
        break;
      default:
        canvas.drawPath(drawingPath.path, drawingPath.paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) {
    return oldDelegate.drawingData != drawingData;
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    const gridSize = 20.0;

    // 绘制垂直线
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
