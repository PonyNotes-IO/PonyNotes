import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_backend/log.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

/// PDF嵌入组件 - 在文档中直接显示PDF预览
/// 解决PDF导入后无法查看原始格式的问题
class PdfEmbedComponent extends StatefulWidget {
  const PdfEmbedComponent({
    super.key,
    required this.node,
    required this.editorState,
    required this.pdfPath,
    this.height = 400,
    this.showControls = true,
  });

  final Node node;
  final EditorState editorState;
  final String pdfPath;
  final double height;
  final bool showControls;

  @override
  State<PdfEmbedComponent> createState() => _PdfEmbedComponentState();
}

class _PdfEmbedComponentState extends State<PdfEmbedComponent> {
  late pdfx.PdfController _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  
  // 控制面板状态
  bool _showControls = true;
  bool _isFullscreen = false;
  double _zoom = 1.0;
  
  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      // 检查文件是否存在
      final file = File(widget.pdfPath);
      if (!file.existsSync()) {
        throw Exception('PDF文件不存在: ${widget.pdfPath}');
      }
      
      // 读取PDF文件
      final bytes = await file.readAsBytes();
      
      // 初始化PDF控制器
      _pdfController = pdfx.PdfController(
        document: pdfx.PdfDocument.openData(bytes),
      );
      
      // 获取文档信息
      final document = await pdfx.PdfDocument.openData(bytes);
      _totalPages = document.pagesCount;
      
      setState(() {
        _isLoading = false;
      });
      
      Log.info('PDF embedded successfully: ${path.basename(widget.pdfPath)}, $_totalPages pages');
      
    } catch (e) {
      Log.error('Failed to initialize embedded PDF: $e');
      setState(() {
        _error = 'PDF加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _isFullscreen ? MediaQuery.of(context).size.height * 0.9 : widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_showControls) _buildControlBar(),
          Expanded(
            child: _buildPdfContent(),
          ),
          if (_showControls && !_isLoading && _error == null) _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // 文件信息
          Expanded(
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    path.basename(widget.pdfPath),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // 页面导航
          if (!_isLoading && _error == null && _totalPages > 1) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1 ? _previousPage : null,
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '$_currentPage/$_totalPages',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages ? _nextPage : null,
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          
          const SizedBox(width: 8),
          
          // 缩放控制
          if (!_isLoading && _error == null) ...[
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _zoom > 0.5 ? _zoomOut : null,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            Text(
              '${(_zoom * 100).toInt()}%',
              style: const TextStyle(fontSize: 11),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _zoom < 3.0 ? _zoomIn : null,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
          
          const SizedBox(width: 8),
          
          // 全屏切换
          IconButton(
            icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: _toggleFullscreen,
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          
          // 更多选项
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            iconSize: 18,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'open_external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, size: 16),
                    SizedBox(width: 8),
                    Text('在外部应用中打开'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'save_copy',
                child: Row(
                  children: [
                    Icon(Icons.save_alt, size: 16),
                    SizedBox(width: 8),
                    Text('保存副本'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'properties',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16),
                    SizedBox(width: 8),
                    Text('文件属性'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载PDF...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializePdf(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade100,
      child: pdfx.PdfView(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
        onDocumentLoaded: (document) {
          Log.debug('PDF document loaded in embed: ${document.pagesCount} pages');
        },
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        backgroundDecoration: BoxDecoration(
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '嵌入的PDF文档 - 双击可全屏查看',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          if (_totalPages > 0)
            Text(
              '共 $_totalPages 页',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.25).clamp(0.5, 3.0);
    });
    // 注意：pdfx可能不直接支持缩放，这里只是状态管理
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.25).clamp(0.5, 3.0);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'open_external':
        _openInExternalApp();
        break;
      case 'save_copy':
        _saveCopy();
        break;
      case 'properties':
        _showProperties();
        break;
    }
  }

  void _openInExternalApp() {
    // TODO: 实现在外部应用中打开PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('外部打开功能开发中...')),
    );
  }

  void _saveCopy() {
    // TODO: 实现保存PDF副本
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存副本功能开发中...')),
    );
  }

  void _showProperties() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF文件属性'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPropertyRow('文件名', path.basename(widget.pdfPath)),
            _buildPropertyRow('文件路径', widget.pdfPath),
            _buildPropertyRow('总页数', '$_totalPages 页'),
            _buildPropertyRow('当前页', '$_currentPage 页'),
            if (File(widget.pdfPath).existsSync())
              _buildPropertyRow(
                '文件大小', 
                '${(File(widget.pdfPath).lengthSync() / 1024).toStringAsFixed(1)} KB',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// PDF嵌入块类型定义
class PdfEmbedBlockKeys {
  static const String type = 'pdf_embed';
  static const String pdfPath = 'pdf_path';
  static const String height = 'height';
  static const String showControls = 'show_controls';
}

/// PDF嵌入块组件构建器
class PdfEmbedBlockComponentBuilder extends BlockComponentBuilder {
  PdfEmbedBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return PdfEmbedBlockWidget(
      key: ValueKey(node.id),
      node: node,
      configuration: configuration,
      showActions: true,
      builder: (context) => Provider(
        create: (_) => context.read<EditorState>(),
        child: PdfEmbedComponent(
          node: node,
          editorState: context.read<EditorState>(),
          pdfPath: node.attributes[PdfEmbedBlockKeys.pdfPath] ?? '',
          height: (node.attributes[PdfEmbedBlockKeys.height] ?? 400).toDouble(),
          showControls: node.attributes[PdfEmbedBlockKeys.showControls] ?? true,
        ),
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) =>
      node.type == PdfEmbedBlockKeys.type &&
      node.attributes.containsKey(PdfEmbedBlockKeys.pdfPath);
}

/// PDF嵌入块Widget
class PdfEmbedBlockWidget extends BlockComponentStatefulWidget {
  const PdfEmbedBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.builder,
  });

  final WidgetBuilder builder;

  @override
  State<PdfEmbedBlockWidget> createState() => _PdfEmbedBlockWidgetState();
}

class _PdfEmbedBlockWidgetState extends State<PdfEmbedBlockWidget>
    with SelectableMixin, DefaultSelectableMixin, BlockComponentConfigurable, BlockComponentBackgroundColorMixin {

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  late EditorState editorState = Provider.of<EditorState>(context, listen: false);

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(
    debugLabel: PdfEmbedBlockKeys.type,
  );

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> get forwardKey => widget.node.key;

  @override
  Widget build(BuildContext context) {
    Widget child = widget.builder(context);

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}
