import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'lib/plugins/import_page/enhanced_pdf_processor.dart';

/// 测试PDF处理流程，包括增强处理器
void main() async {
  final pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/test-pdf-import-example.pdf';
  final pdfFile = File(pdfPath);
  
  if (!await pdfFile.exists()) {
    print('❌ PDF文件不存在: $pdfPath');
    return;
  }
  
  print('📄 开始分析PDF处理流程...');
  
  try {
    // 1. 读取PDF字节
    final bytes = await pdfFile.readAsBytes();
    print('✅ 成功读取PDF文件，大小: ${bytes.length} bytes');
    
    // 2. 使用Syncfusion基础提取
    print('\n🔍 步骤1: Syncfusion基础文本提取');
    final document = sf.PdfDocument(inputBytes: bytes);
    final textExtractor = sf.PdfTextExtractor(document);
    final rawText = textExtractor.extractText();
    
    print('原始提取文本长度: ${rawText.length}');
    print('原始文本前200字符:');
    print(rawText.substring(0, rawText.length > 200 ? 200 : rawText.length));
    print('---');
    
    // 3. 检查是否包含HTML标签
    final containsHtml = rawText.contains('<html>') || rawText.contains('<!DOCTYPE') || rawText.contains('<body>');
    print('是否包含HTML标签: $containsHtml');
    
    if (containsHtml) {
      print('⚠️  检测到HTML内容！');
      // 查找HTML标签的位置
      final htmlStartIndex = rawText.indexOf('<');
      final htmlEndIndex = rawText.lastIndexOf('>');
      if (htmlStartIndex >= 0 && htmlEndIndex >= 0) {
        print('HTML内容位置: $htmlStartIndex - $htmlEndIndex');
        print('HTML内容片段:');
        final htmlSnippet = rawText.substring(
          htmlStartIndex, 
          (htmlEndIndex + 1).clamp(0, rawText.length)
        );
        print(htmlSnippet.substring(0, htmlSnippet.length > 500 ? 500 : htmlSnippet.length));
      }
    }
    
    // 4. 分析文档结构
    print('\n🔍 步骤2: 分析文档结构');
    final pageCount = document.pages.count;
    print('总页数: $pageCount');
    
    // 逐页检查
    for (int i = 0; i < (pageCount > 3 ? 3 : pageCount); i++) {
      print('\n--- 页面 ${i + 1} ---');
      final pageText = textExtractor.extractText(startPageIndex: i, endPageIndex: i);
      print('页面文本长度: ${pageText.length}');
      
      final pageContainsHtml = pageText.contains('<html>') || pageText.contains('<!DOCTYPE') || pageText.contains('<body>');
      print('页面是否包含HTML: $pageContainsHtml');
      
      if (pageContainsHtml) {
        print('⚠️  页面 ${i + 1} 包含HTML内容！');
        final htmlLines = pageText.split('\n').where((line) => line.contains('<') || line.contains('>')).take(5);
        print('HTML行示例:');
        for (final line in htmlLines) {
          print('  $line');
        }
      }
      
      // 显示页面内容预览
      if (pageText.isNotEmpty) {
        print('页面内容预览:');
        final preview = pageText.trim().substring(0, pageText.length > 150 ? 150 : pageText.length);
        print('  $preview...');
      }
    }
    
    // 5. 检查元数据
    print('\n🔍 步骤3: 检查PDF元数据');
    final info = document.documentInformation;
    print('标题: ${info.title}');
    print('作者: ${info.author}');
    print('创建者: ${info.creator}');
    print('生产者: ${info.producer}');
    print('主题: ${info.subject}');
    
    document.dispose();
    
    // 6. 尝试使用不同的提取方法
    print('\n🔍 步骤4: 尝试其他提取方法');
    
    // 重新加载文档进行更详细的分析
    final document2 = sf.PdfDocument(inputBytes: bytes);
    
    // 检查是否有表单字段或特殊内容
    if (document2.form.fields.count > 0) {
      print('发现表单字段: ${document2.form.fields.count} 个');
    }
    
    // 检查书签
    if (document2.bookmarks.count > 0) {
      print('发现书签: ${document2.bookmarks.count} 个');
    }
    
    document2.dispose();
    
    // 7. 测试增强PDF处理器
    print('\n🔍 步骤5: 测试增强PDF处理器');
    try {
      final enhancedResult = await EnhancedPdfProcessor.processToMarkdown(bytes);
      print('✅ 增强处理器执行成功');
      print('生成的Markdown长度: ${enhancedResult.length}');
      print('Markdown预览 (前500字符):');
      print(enhancedResult.substring(0, enhancedResult.length > 500 ? 500 : enhancedResult.length));
      print('...');
      
      // 分析处理结果
      final lines = enhancedResult.split('\n');
      final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;
      final headerCount = lines.where((line) => line.startsWith('#')).length;
      final listCount = lines.where((line) => line.trim().startsWith('- ')).length;
      
      print('\n📊 处理结果统计:');
      print('总行数: ${lines.length}');
      print('非空行数: $nonEmptyLines');
      print('标题数量: $headerCount');
      print('列表项数量: $listCount');
      
    } catch (e, stackTrace) {
      print('❌ 增强处理器出错: $e');
      print('堆栈跟踪: $stackTrace');
    }
    
  } catch (e, stackTrace) {
    print('❌ 处理过程中出错: $e');
    print('堆栈跟踪: $stackTrace');
  }
  
  print('\n✅ PDF分析完成');
}
