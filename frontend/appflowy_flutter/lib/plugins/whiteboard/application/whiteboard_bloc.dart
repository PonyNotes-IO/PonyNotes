import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy/plugins/whiteboard/application/drawing_models.dart';

// 白板事件
abstract class WhiteboardEvent extends Equatable {
  const WhiteboardEvent();

  @override
  List<Object?> get props => [];
}

class SelectTool extends WhiteboardEvent {
  const SelectTool(this.tool);
  final DrawingTool tool;

  @override
  List<Object?> get props => [tool];
}

class StartDrawing extends WhiteboardEvent {
  const StartDrawing(this.point);
  final Offset point;

  @override
  List<Object?> get props => [point];
}

class UpdateDrawing extends WhiteboardEvent {
  const UpdateDrawing(this.point);
  final Offset point;

  @override
  List<Object?> get props => [point];
}

class EndDrawing extends WhiteboardEvent {
  const EndDrawing();
}

class ChangeColor extends WhiteboardEvent {
  const ChangeColor(this.color);
  final Color color;

  @override
  List<Object?> get props => [color];
}

class ChangeStrokeWidth extends WhiteboardEvent {
  const ChangeStrokeWidth(this.strokeWidth);
  final double strokeWidth;

  @override
  List<Object?> get props => [strokeWidth];
}

class ClearBoard extends WhiteboardEvent {
  const ClearBoard();
}

class UndoAction extends WhiteboardEvent {
  const UndoAction();
}

class RedoAction extends WhiteboardEvent {
  const RedoAction();
}

// 白板状态
class WhiteboardState extends Equatable {
  WhiteboardState({
    this.selectedTool = DrawingTool.pen,
    this.selectedColor = Colors.black,
    this.strokeWidth = 2.0,
    DrawingData? drawingData,
    this.historyIndex = -1,
    this.history = const [],
  }) : drawingData = drawingData ?? DrawingData();

  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final DrawingData drawingData;
  final int historyIndex;
  final List<DrawingData> history;

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length - 1;

  WhiteboardState copyWith({
    DrawingTool? selectedTool,
    Color? selectedColor,
    double? strokeWidth,
    DrawingData? drawingData,
    int? historyIndex,
    List<DrawingData>? history,
  }) {
    return WhiteboardState(
      selectedTool: selectedTool ?? this.selectedTool,
      selectedColor: selectedColor ?? this.selectedColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      drawingData: drawingData ?? this.drawingData,
      historyIndex: historyIndex ?? this.historyIndex,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        selectedTool,
        selectedColor,
        strokeWidth,
        drawingData,
        historyIndex,
        history,
      ];
}

// 白板BLoC
class WhiteboardBloc extends Bloc<WhiteboardEvent, WhiteboardState> {
  WhiteboardBloc() : super(WhiteboardState()) {
    on<SelectTool>(_onSelectTool);
    on<StartDrawing>(_onStartDrawing);
    on<UpdateDrawing>(_onUpdateDrawing);
    on<EndDrawing>(_onEndDrawing);
    on<ChangeColor>(_onChangeColor);
    on<ChangeStrokeWidth>(_onChangeStrokeWidth);
    on<ClearBoard>(_onClearBoard);
    on<UndoAction>(_onUndoAction);
    on<RedoAction>(_onRedoAction);
  }

  void _onSelectTool(SelectTool event, Emitter<WhiteboardState> emit) {
    emit(state.copyWith(selectedTool: event.tool));
  }

  void _onStartDrawing(StartDrawing event, Emitter<WhiteboardState> emit) {
    final paint = Paint()
      ..color = state.selectedColor
      ..strokeWidth = state.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(event.point.dx, event.point.dy);

    final drawingPath = DrawingPath(
      path: path,
      paint: paint,
      tool: state.selectedTool,
      startPoint: event.point,
    );

    final newDrawingData = state.drawingData.copyWith(
      currentPath: drawingPath,
      isDrawing: true,
    );

    emit(state.copyWith(drawingData: newDrawingData));
  }

  void _onUpdateDrawing(UpdateDrawing event, Emitter<WhiteboardState> emit) {
    if (state.drawingData.currentPath == null) return;

    final currentPath = state.drawingData.currentPath!;
    final newPath = Path.from(currentPath.path);

    switch (state.selectedTool) {
      case DrawingTool.pen:
        newPath.lineTo(event.point.dx, event.point.dy);
        break;
      case DrawingTool.line:
        // 重新创建直线路径
        newPath.reset();
        newPath.moveTo(currentPath.startPoint!.dx, currentPath.startPoint!.dy);
        newPath.lineTo(event.point.dx, event.point.dy);
        break;
      case DrawingTool.rectangle:
        // 重新创建矩形路径
        newPath.reset();
        final rect = Rect.fromPoints(currentPath.startPoint!, event.point);
        newPath.addRect(rect);
        break;
      case DrawingTool.circle:
        // 重新创建圆形路径
        newPath.reset();
        final center = currentPath.startPoint!;
        final radius = (event.point - center).distance;
        newPath.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case DrawingTool.eraser:
        // 橡皮擦功能
        newPath.lineTo(event.point.dx, event.point.dy);
        break;
      case DrawingTool.text:
        // TODO: 实现文本工具
        break;
    }

    final updatedPath = currentPath.copyWith(
      path: newPath,
      endPoint: event.point,
    );

    final newDrawingData = state.drawingData.copyWith(
      currentPath: updatedPath,
    );

    emit(state.copyWith(drawingData: newDrawingData));
  }

  void _onEndDrawing(EndDrawing event, Emitter<WhiteboardState> emit) {
    if (state.drawingData.currentPath == null) return;

    final newPaths = List<DrawingPath>.from(state.drawingData.paths)
      ..add(state.drawingData.currentPath!);

    final newDrawingData = state.drawingData.copyWith(
      paths: newPaths,
      currentPath: null,
    );

    // 添加到历史记录
    final newHistory = List<DrawingData>.from(state.history.take(state.historyIndex + 1))
      ..add(newDrawingData);

    emit(state.copyWith(
      drawingData: newDrawingData,
      history: newHistory,
      historyIndex: newHistory.length - 1,
    ));
  }

  void _onChangeColor(ChangeColor event, Emitter<WhiteboardState> emit) {
    emit(state.copyWith(selectedColor: event.color));
  }

  void _onChangeStrokeWidth(ChangeStrokeWidth event, Emitter<WhiteboardState> emit) {
    emit(state.copyWith(strokeWidth: event.strokeWidth));
  }

  void _onClearBoard(ClearBoard event, Emitter<WhiteboardState> emit) {
    final newDrawingData = DrawingData();
    final newHistory = List<DrawingData>.from(state.history)..add(newDrawingData);

    emit(state.copyWith(
      drawingData: newDrawingData,
      history: newHistory,
      historyIndex: newHistory.length - 1,
    ));
  }

  void _onUndoAction(UndoAction event, Emitter<WhiteboardState> emit) {
    if (!state.canUndo) return;

    final newIndex = state.historyIndex - 1;
    final previousDrawingData = state.history[newIndex];

    emit(state.copyWith(
      drawingData: previousDrawingData,
      historyIndex: newIndex,
    ));
  }

  void _onRedoAction(RedoAction event, Emitter<WhiteboardState> emit) {
    if (!state.canRedo) return;

    final newIndex = state.historyIndex + 1;
    final nextDrawingData = state.history[newIndex];

    emit(state.copyWith(
      drawingData: nextDrawingData,
      historyIndex: newIndex,
    ));
  }
}
