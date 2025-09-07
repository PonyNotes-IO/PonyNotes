import 'dart:io';
import 'lib/plugins/document_loader/hybrid_pdf_service.dart';

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
    final result = await HybridPdfService.processPdf(pdfPath);
    
    // 生成输出文件名
    final pdfFileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    final outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/${pdfFileName}_extracted.md';
    
    // 创建Markdown内容
    final markdownContent = '''# ${pdfFileName}

> 📄 **原始文件**: ${pdfPath.split('/').last}  
> ⚡ **处理方法**: ${result.method}  
> 🕐 **处理时间**: ${result.processingTime.inMilliseconds}ms  
> 📊 **内容长度**: ${result.content.length} 字符  
> 📋 **表格数量**: ${result.tableCount}  
> 🖼️ **图像数量**: ${result.imageCount}  
> ✅ **处理状态**: ${result.hasErrors ? '有错误' : '成功'}

---

## 提取的内容

${result.content}

---

*由 HybridPdfService 自动提取于 ${DateTime.now().toString()}*
''';

    // 保存到文件
    final outputFile = File(outputPath);
    await outputFile.writeAsString(markdownContent);
    
    print('✅ 提取完成！');
    print('📄 输出文件: $outputPath');
    print('📊 内容统计:');
    print('   - 处理方法: ${result.method}');
    print('   - 处理时间: ${result.processingTime.inMilliseconds}ms');
    print('   - 内容长度: ${result.content.length} 字符');
    print('   - 表格数量: ${result.tableCount}');
    print('   - 图像数量: ${result.imageCount}');
    print('   - 文件大小: ${(await outputFile.stat()).size} bytes');
    
    // 显示内容预览
    if (result.content.isNotEmpty) {
      final preview = result.content.length > 300 
          ? result.content.substring(0, 300) + '...'
          : result.content;
      print('\n📋 内容预览:');
      print('$preview');
    }
    
  } catch (e, stackTrace) {
    print('❌ 提取失败: $e');
    print('Stack trace: $stackTrace');
  }
}
