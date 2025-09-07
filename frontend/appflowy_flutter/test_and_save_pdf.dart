import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy/plugins/document_loader/hybrid_pdf_service.dart';
import 'dart:io';

/// 🎯 运行PDF处理测试并保存结果为Markdown文件
void main() {
  group('PDF处理并保存结果', () {
    const testPdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
    
    test('处理PDF并保存Markdown结果', () async {
      final file = File(testPdfPath);
      
      // 检查PDF文件是否存在
      if (!await file.exists()) {
        print('⚠️  跳过测试：PDF文件不存在');
        return;
      }
      
      print('🚀 开始处理PDF: ${file.path.split('/').last}');
      
      final stopwatch = Stopwatch()..start();
      
      try {
        // 处理PDF
        final result = await HybridPdfService.processPdf(testPdfPath);
        stopwatch.stop();
        
        print('✅ 处理完成！');
        print('   - 耗时: ${stopwatch.elapsedMilliseconds}ms');
        print('   - 处理方法: ${result.method}');
        print('   - 内容长度: ${result.content.length}字符');
        
        // 生成输出文件名
        final pdfFileName = testPdfPath.split('/').last.replaceAll('.pdf', '');
        final outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/${pdfFileName}_processed.md';
        
        // 创建Markdown内容
        final markdownContent = '''# ${pdfFileName}

> 📄 **原始文件**: ${testPdfPath.split('/').last}  
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
        
        print('📄 结果已保存到: $outputPath');
        print('📁 文件大小: ${(await outputFile.stat()).size} bytes');
        
        // 验证文件确实被创建
        expect(await outputFile.exists(), true, reason: 'Markdown文件应该被创建');
        expect(result.content, isNotEmpty, reason: '应该提取到一些内容');
        
        print('🎉 测试通过，Markdown文件已保存！');
        
      } catch (e, stackTrace) {
        stopwatch.stop();
        print('❌ 处理失败: $e');
        print('Stack trace: $stackTrace');
        fail('PDF处理应该成功，但抛出异常: $e');
      }
    });
  });
}
