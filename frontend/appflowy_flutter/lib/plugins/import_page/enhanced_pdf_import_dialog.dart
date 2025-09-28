import 'dart:io';
import 'dart:typed_data';
import 'package:appflowy/plugins/import_page/visual_pdf_processor.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy/workspace/application/settings/share/import_service.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'professional_pdf_processor.dart';
import 'advanced_pdf_processor.dart';
import 'ocr_pdf_processor.dart';

/// 增强的PDF导入对话框，提供多种处理模式和实时预览
class EnhancedPdfImportDialog extends StatefulWidget {
  final String parentViewId;
  final VoidCallback? onImportSuccess;

  const EnhancedPdfImportDialog({
    super.key,
    required this.parentViewId,
    this.onImportSuccess,
  });

  @override
  State<EnhancedPdfImportDialog> createState() => _EnhancedPdfImportDialogState();
}

class _EnhancedPdfImportDialogState extends State<EnhancedPdfImportDialog> {
  File? _selectedFile;
  Uint8List? _pdfBytes;
  String? _extractedContent;
  String? _processingError;
  bool _isProcessing = false;
  PdfImportMode _importMode = PdfImportMode.professional;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildModeSelector(),
            const SizedBox(height: 16),
            _buildFileSelector(),
            const SizedBox(height: 16),
            if (_selectedFile != null) ...[
              _buildProcessButton(),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _buildContentPreview(),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.picture_as_pdf, size: 32, color: Colors.red),
        const SizedBox(width: 12),
        const Text(
          '智能PDF导入',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '处理模式',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PdfImportMode.values.map((mode) {
            return ChoiceChip(
              label: Text(mode.displayName),
              selected: _importMode == mode,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _importMode = mode;
                    _extractedContent = null;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _importMode.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFileSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择PDF文件',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_selectedFile == null)
            GestureDetector(
              onTap: _selectFile,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 32, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      '点击选择PDF文件',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedFile!.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: _selectFile,
                  child: const Text('更换文件'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedFile != null && !_isProcessing ? _processFile : null,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isProcessing ? '处理中...' : '开始处理'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildContentPreview() {
    if (_processingError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '处理失败',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_processingError!),
          ],
        ),
      );
    }

    if (_extractedContent == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.preview, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '选择文件并点击"开始处理"来预览提取的内容',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '提取内容预览',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_pdfBytes != null)
              TextButton.icon(
                onPressed: _showHybridPreview,
                icon: const Icon(Icons.preview),
                label: const Text('混合预览'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _extractedContent!,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _extractedContent != null ? _importDocument : null,
          child: const Text('导入文档'),
        ),
      ],
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedFile = file;
          _extractedContent = null;
          _processingError = null;
        });
      }
    } catch (e) {
      Log.error('Failed to select PDF file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: $e')),
      );
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isProcessing = true;
      _processingError = null;
    });

    try {
      // 读取PDF字节
      _pdfBytes = await _selectedFile!.readAsBytes();
      
      String content;
      
      // 根据选择的模式处理PDF
      switch (_importMode) {
        case PdfImportMode.professional:
          content = await ProfessionalPdfProcessor.processPdfBytes(_selectedFile!);
          break;
        case PdfImportMode.advanced:
          content = await AdvancedPdfProcessor.processPdfBytes(_pdfBytes!);
          break;
        case PdfImportMode.ocr:
          content = await OcrPdfProcessor.processPdfBytes(_pdfBytes!);
          break;
        case PdfImportMode.visual:
          content = await VisualPdfProcessor.processPdfBytes(_pdfBytes!);
          break;
      }

      setState(() {
        _extractedContent = content;
        _isProcessing = false;
      });

    } catch (e) {
      Log.error('Failed to process PDF: $e');
      setState(() {
        _processingError = 'PDF处理失败: $e';
        _isProcessing = false;
      });
    }
  }

  void _showHybridPreview() {
    if (_pdfBytes != null && _extractedContent != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfHybridPreviewScreen(
            pdfBytes: _pdfBytes!,
            extractedText: _extractedContent!,
            fileName: p.basenameWithoutExtension(_selectedFile!.path),
          ),
        ),
      );
    }
  }

  Future<void> _importDocument() async {
    if (_extractedContent == null) return;

    try {
      final fileName = p.basenameWithoutExtension(_selectedFile!.path);
      
      // 将Markdown转换为Document格式
      final document = customMarkdownToDocument(_extractedContent!);
      final documentBytes = DocumentDataPBFromTo.fromDocument(document)?.writeToBuffer();
      
      if (documentBytes != null) {
        final importValues = [
          ImportItemPayloadPB.create()
            ..name = fileName
            ..data = documentBytes
            ..viewLayout = ViewLayoutPB.Document
            ..importType = ImportTypePB.Markdown,
        ];
        
        await ImportBackendService.importPages(widget.parentViewId, importValues);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入PDF文档: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          widget.onImportSuccess?.call();
        }
      }
    } catch (e) {
      Log.error('Failed to import PDF document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

enum PdfImportMode {
  professional('专业模式', '智能识别文档结构，保持格式和层次'),
  advanced('高级模式', '深度分析内容，优化表格和列表'),
  ocr('OCR模式', '图像文字识别，适用于扫描文档'),
  visual('视觉模式', '保持视觉布局，适用于复杂排版');

  const PdfImportMode(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// PDF混合预览屏幕
class PdfHybridPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String extractedText;
  final String fileName;

  const PdfHybridPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.extractedText,
    required this.fileName,
  });

  @override
  State<PdfHybridPreviewScreen> createState() => _PdfHybridPreviewScreenState();
}

class _PdfHybridPreviewScreenState extends State<PdfHybridPreviewScreen> {
  late pdfx.PdfController _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  double _zoom = 1.0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePdf();
  }

  Future<void> _initializePdf() async {
    try {
      // 初始化PDF控制器
      _pdfController = pdfx.PdfController(
        document: pdfx.PdfDocument.openData(widget.pdfBytes),
      );
      
      // 获取文档信息
      final document = await pdfx.PdfDocument.openData(widget.pdfBytes);
      _totalPages = document.pagesCount;
      
      setState(() {
        _isLoading = false;
      });
      
      Log.info('PDF混合预览初始化成功: ${widget.fileName}, $_totalPages 页');
      
    } catch (e) {
      Log.error('PDF混合预览初始化失败: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('混合预览: ${widget.fileName}'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
            tooltip: _showControls ? '隐藏控制栏' : '显示控制栏',
          ),
          IconButton(
            onPressed: () {
              // TODO: 实现保存功能
            },
            icon: const Icon(Icons.save),
            tooltip: '保存',
          ),
        ],
      ),
      body: Row(
        children: [
          // PDF原文显示
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('原文档', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_showControls && !_isLoading && _error == null) ...[
                        IconButton(
                          onPressed: _currentPage > 1 ? () => _pdfController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ) : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: '上一页',
                        ),
                        Text('$_currentPage / $_totalPages'),
                        IconButton(
                          onPressed: _currentPage < _totalPages ? () => _pdfController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ) : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: '下一页',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _zoom > 0.5 ? () => setState(() => _zoom -= 0.1) : null,
                          icon: const Icon(Icons.zoom_out),
                          tooltip: '缩小',
                        ),
                        Text('${(_zoom * 100).toInt()}%'),
                        IconButton(
                          onPressed: _zoom < 3.0 ? () => setState(() => _zoom += 0.1) : null,
                          icon: const Icon(Icons.zoom_in),
                          tooltip: '放大',
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _buildPdfViewer(),
                  ),
                ),
                if (_showControls && !_isLoading && _error == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.grey[200],
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 4),
                        Text('PDF文档: ${widget.fileName}'),
                        const Spacer(),
                        Text('总页数: $_totalPages'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 1,
            color: Colors.grey[300],
          ),
          // 提取文本显示
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[100],
                  child: const Row(
                    children: [
                      Icon(Icons.text_fields, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('解析结果 (Markdown)', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: _buildMarkdownViewer(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      const Icon(Icons.text_fields, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Markdown解析结果'),
                      const Spacer(),
                      Text('字符数: ${widget.extractedText.length}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
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

    return Transform.scale(
      scale: _zoom,
      child: pdfx.PdfView(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
        onDocumentLoaded: (document) {
          Log.debug('PDF文档在混合预览中加载: ${document.pagesCount} 页');
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

  Widget _buildMarkdownViewer() {
    return Markdown(
      data: widget.extractedText,
      shrinkWrap: true,
      selectable: true,
      padding: EdgeInsets.zero,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.4,
        ),
        h1: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        h2: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        h3: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
        listBullet: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey.shade200,
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.black87,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(8),
        tableBorder: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        tableBody: const TextStyle(
          color: Colors.black87,
        ),
      ),
    );
  }
}