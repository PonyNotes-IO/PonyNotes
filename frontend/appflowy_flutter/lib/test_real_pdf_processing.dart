import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'plugins/import_page/professional_pdf_processor.dart';
import 'plugins/import_page/advanced_pdf_processor.dart';
import 'plugins/import_page/ocr_pdf_processor.dart';

/// 真实PDF处理测试应用
/// 这个应用可以加载真实的PDF文件并测试我们的处理器
class RealPdfTestApp extends StatelessWidget {
  const RealPdfTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF处理器测试',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PdfTestScreen(),
    );
  }
}

class PdfTestScreen extends StatefulWidget {
  const PdfTestScreen({super.key});

  @override
  State<PdfTestScreen> createState() => _PdfTestScreenState();
}

class _PdfTestScreenState extends State<PdfTestScreen> {
  String _status = '准备就绪';
  List<TestResult> _results = [];
  bool _isProcessing = false;
  
  final String _pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/test-pdf-import-example.pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF处理器测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📄 测试文件信息',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('路径: $_pdfPath'),
                    const SizedBox(height: 4),
                    FutureBuilder<FileStat?>(
                      future: _getFileInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final stat = snapshot.data!;
                          final sizeKB = (stat.size / 1024).toStringAsFixed(1);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('大小: ${sizeKB} KB'),
                              Text('修改时间: ${stat.modified}'),
                            ],
                          );
                        }
                        return const Text('获取文件信息中...');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 处理状态',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _runTests,
                      icon: _isProcessing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isProcessing ? '处理中...' : '开始测试'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📊 测试结果',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _results.isEmpty
                            ? const Center(
                                child: Text('点击"开始测试"按钮来运行PDF处理器测试'),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final result = _results[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ExpansionTile(
                                      leading: Icon(
                                        result.success ? Icons.check_circle : Icons.error,
                                        color: result.success ? Colors.green : Colors.red,
                                      ),
                                      title: Text(result.processorName),
                                      subtitle: Text(
                                        result.success
                                            ? '✅ 成功 - ${result.processingTime}ms - ${result.extractedLength} 字符'
                                            : '❌ 失败 - ${result.error}',
                                      ),
                                      children: [
                                        if (result.success && result.extractedContent != null)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '提取内容预览:',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    result.extractedContent!.length > 500
                                                        ? '${result.extractedContent!.substring(0, 500)}...'
                                                        : result.extractedContent!,
                                                    style: const TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () => _copyToClipboard(result.extractedContent!),
                                                      icon: const Icon(Icons.copy, size: 16),
                                                      label: const Text('复制'),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    ElevatedButton.icon(
                                                      onPressed: () => _saveToFile(result),
                                                      icon: const Icon(Icons.save, size: 16),
                                                      label: const Text('保存'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<FileStat?> _getFileInfo() async {
    try {
      final file = File(_pdfPath);
      if (await file.exists()) {
        return await file.stat();
      }
    } catch (e) {
      // 忽略错误
    }
    return null;
  }

  Future<void> _runTests() async {
    setState(() {
      _isProcessing = true;
      _results.clear();
      _status = '正在读取PDF文件...';
    });

    try {
      final file = File(_pdfPath);
      if (!await file.exists()) {
        setState(() {
          _status = '❌ PDF文件不存在';
          _isProcessing = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      setState(() {
        _status = '📄 文件读取成功，开始测试处理器...';
      });

      // 测试各个处理器
      final processors = [
        ('🔧 专业PDF处理器', ProfessionalPdfProcessor.processPdfBytes),
        ('🚀 高级PDF处理器', AdvancedPdfProcessor.processPdfBytes),
        ('👁️ OCR PDF处理器', OcrPdfProcessor.processPdfBytes),
      ];

      for (final (name, processor) in processors) {
        setState(() {
          _status = '正在测试 $name...';
        });

        await _testProcessor(name, processor, bytes);
      }

      setState(() {
        _status = '✅ 所有测试完成！';
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _status = '❌ 测试失败: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _testProcessor(
    String name,
    Future<String> Function(Uint8List) processor,
    Uint8List bytes,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await processor(bytes);
      stopwatch.stop();

      setState(() {
        _results.add(TestResult(
          processorName: name,
          success: true,
          processingTime: stopwatch.elapsedMilliseconds,
          extractedLength: result.length,
          extractedContent: result,
        ));
      });
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _results.add(TestResult(
          processorName: name,
          success: false,
          processingTime: stopwatch.elapsedMilliseconds,
          error: e.toString(),
        ));
      });
    }
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('内容已复制到剪贴板')),
    );
  }

  Future<void> _saveToFile(TestResult result) async {
    try {
      final fileName = 'pdf_result_${result.processorName.replaceAll(RegExp(r'[^\w]'), '_')}.md';
      final file = File(fileName);
      await file.writeAsString(result.extractedContent!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('结果已保存到 $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

class TestResult {
  final String processorName;
  final bool success;
  final int processingTime;
  final int extractedLength;
  final String? extractedContent;
  final String? error;

  TestResult({
    required this.processorName,
    required this.success,
    required this.processingTime,
    this.extractedLength = 0,
    this.extractedContent,
    this.error,
  });
}

void main() {
  runApp(const RealPdfTestApp());
}

