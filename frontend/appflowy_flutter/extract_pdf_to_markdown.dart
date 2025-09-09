import 'dart:io';
import 'lib/plugins/document_loader/pdf_import_service.dart';

/// 🎯 提取PDF并保存为Markdown文件的脚本
Future<void> main() async {
  const pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  
  print('📄 开始提取PDF内容...');
  print('输入文件: $pdfPath');
  
  try {
    // 检查PDF文件是否存在
    final pdfFile = File(pdfPath);
    if (!await pdfFile.exists()) {
      print('❌ PDF文件不存在: $pdfPath');
      return;
    }
    
    // 处理PDF
    final stopwatch = Stopwatch()..start();
    final markdownContent = await PdfImportService.convertPdfToMarkdown(pdfPath);
    stopwatch.stop();
    
    // 生成输出文件名
    final pdfFileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    final outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/${pdfFileName}_extracted.md';
    
    // 添加处理信息到Markdown内容
    final enhancedContent = '''# ${pdfFileName}

> 📄 **原始文件**: ${pdfPath.split('/').last}  
> ⚡ **处理方法**: PdfImportService (Syncfusion)  
> 🕐 **处理时间**: ${stopwatch.elapsedMilliseconds}ms  
> 📊 **内容长度**: ${markdownContent.length} 字符  
> ✅ **处理状态**: 成功

---

${markdownContent}

---

*由 PdfImportService 自动提取于 ${DateTime.now().toString()}*
''';

    // 保存到文件
    final outputFile = File(outputPath);
    await outputFile.writeAsString(enhancedContent);
    
    print('✅ 提取完成！');
    print('📄 输出文件: $outputPath');
    print('📊 内容统计:');
    print('   - 处理方法: PdfImportService (Syncfusion)');
    print('   - 处理时间: ${stopwatch.elapsedMilliseconds}ms');
    print('   - 内容长度: ${markdownContent.length} 字符');
    print('   - 文件大小: ${(await outputFile.stat()).size} bytes');
    
    // 显示内容预览
    if (markdownContent.isNotEmpty) {
      final preview = markdownContent.length > 300 
          ? markdownContent.substring(0, 300) + '...'
          : markdownContent;
      print('\n📋 内容预览:');
      print('$preview');
    }
    
  } catch (e, stackTrace) {
    print('❌ 提取失败: $e');
    print('Stack trace: $stackTrace');
  }
}
