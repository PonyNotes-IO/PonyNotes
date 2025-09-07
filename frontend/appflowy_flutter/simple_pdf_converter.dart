import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// 🎯 简单PDF转Markdown转换器
/// 使用纯Dart PDF库处理PDF文件
class SimplePdfConverter {
  
  /// 📄 将PDF文件直接转换为Markdown
  static Future<String> convertPdfToMarkdown(String pdfPath) async {
    print('🔄 开始处理PDF文件: $pdfPath');
    
    try {
      // 读取PDF文件
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF文件不存在: $pdfPath');
      }
      
      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      print('📁 PDF文件大小: ${pdfBytes.length} bytes');
      
      // 使用printing库提取PDF文本
      String extractedText = '';
      
      try {
        // 尝试使用printing库的文本提取功能
        extractedText = await _extractTextUsingPrinting(pdfBytes);
      } catch (e) {
        print('⚠️ printing库提取失败，尝试基础方法: $e');
        extractedText = await _extractTextBasic(pdfBytes, pdfPath);
      }
      
      if (extractedText.trim().isEmpty) {
        extractedText = '无法提取PDF文本内容。这可能是因为：\n- PDF是扫描件（图片）\n- PDF有密码保护\n- PDF格式不兼容';
      }
      
      // 生成Markdown内容
      final String fileName = pdfPath.split('/').last.replaceAll('.pdf', '');
      final StringBuffer markdownContent = StringBuffer();
      
      // 添加文档头部信息
      markdownContent.writeln('# $fileName\n');
      markdownContent.writeln('> PDF文档转换 - ${DateTime.now().toString().split('.')[0]}\n');
      
      // 处理提取的文本
      final processedText = _processExtractedText(extractedText);
      markdownContent.writeln(processedText);
      
      // 添加文档统计信息
      markdownContent.writeln('\n## 📊 文档统计\n');
      markdownContent.writeln('- **原始文件**: $pdfPath');
      markdownContent.writeln('- **文件大小**: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      markdownContent.writeln('- **提取字符数**: ${extractedText.length}');
      markdownContent.writeln('- **转换时间**: ${DateTime.now().toString().split('.')[0]}');
      
      print('✅ PDF处理完成！');
      print('📊 提取了 ${extractedText.length} 个字符');
      
      return markdownContent.toString();
      
    } catch (e) {
      print('❌ PDF处理失败: $e');
      return _generateErrorMarkdown(pdfPath, e.toString());
    }
  }
  
  /// 📝 使用printing库提取文本
  static Future<String> _extractTextUsingPrinting(Uint8List pdfBytes) async {
    try {
      // 注意：printing库主要用于打印，文本提取功能有限
      // 这里我们尝试一个基础的方法
      final String pdfString = String.fromCharCodes(pdfBytes);
      
      // 寻找PDF中的文本流
      final RegExp textPattern = RegExp(r'BT\s+(.*?)\s+ET', multiLine: true, dotAll: true);
      final matches = textPattern.allMatches(pdfString);
      
      final StringBuffer extractedText = StringBuffer();
      for (final match in matches) {
        final String textBlock = match.group(1) ?? '';
        // 简单清理PDF命令
        final cleanText = textBlock
            .replaceAll(RegExp(r'Tf\s+'), '')
            .replaceAll(RegExp(r'Td\s+'), ' ')
            .replaceAll(RegExp(r'Tj\s+'), '')
            .replaceAll(RegExp(r'\[.*?\]\s*TJ'), '')
            .replaceAll(RegExp(r'\d+\.?\d*\s+'), '');
        
        extractedText.writeln(cleanText);
      }
      
      return extractedText.toString();
    } catch (e) {
      throw Exception('printing库文本提取失败: $e');
    }
  }
  
  /// 📝 基础文本提取方法
  static Future<String> _extractTextBasic(Uint8List pdfBytes, String pdfPath) async {
    try {
      // 将PDF字节转换为字符串进行基础分析
      final String pdfContent = String.fromCharCodes(pdfBytes);
      final StringBuffer extractedText = StringBuffer();
      
      // 1. 寻找文本对象
      final RegExp streamPattern = RegExp(r'stream\s+(.*?)\s+endstream', multiLine: true, dotAll: true);
      final matches = streamPattern.allMatches(pdfContent);
      
      print('📖 找到 ${matches.length} 个数据流');
      
      for (final match in matches) {
        final String streamContent = match.group(1) ?? '';
        
        // 2. 寻找可能的文本内容
        final RegExp textPattern = RegExp(r'\((.*?)\)', multiLine: true);
        final textMatches = textPattern.allMatches(streamContent);
        
        for (final textMatch in textMatches) {
          String text = textMatch.group(1) ?? '';
          
          // 3. 清理和解码文本
          text = text
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\r', '\n')
              .replaceAll(r'\t', '\t')
              .replaceAll(r'\\', r'\')
              .replaceAll(r'\(', '(')
              .replaceAll(r'\)', ')');
          
          // 4. 过滤掉明显的非文本内容
          if (text.length > 2 && 
              !text.contains('<<') && 
              !text.contains('>>') &&
              text.contains(RegExp(r'[a-zA-Z\u4e00-\u9fff]'))) {
            extractedText.writeln(text);
          }
        }
      }
      
      // 5. 如果没有提取到内容，尝试其他方法
      if (extractedText.toString().trim().isEmpty) {
        print('🔍 尝试其他提取方法...');
        
        // 寻找直接的文本内容
        final RegExp directTextPattern = RegExp(r'[a-zA-Z\u4e00-\u9fff][a-zA-Z0-9\u4e00-\u9fff\s.,!?;:()]{10,}');
        final directMatches = directTextPattern.allMatches(pdfContent);
        
        for (final match in directMatches) {
          final String text = match.group(0) ?? '';
          if (text.trim().isNotEmpty) {
            extractedText.writeln(text.trim());
          }
        }
      }
      
      return extractedText.toString();
      
    } catch (e) {
      throw Exception('基础文本提取失败: $e');
    }
  }
  
  /// 📝 处理提取的文本，转换为Markdown格式
  static String _processExtractedText(String rawText) {
    if (rawText.trim().isEmpty) {
      return '> 未能提取到文本内容\n\n这可能是因为PDF包含图像或使用了不支持的编码格式。';
    }
    
    String processed = rawText;
    
    // 1. 清理多余空行
    processed = processed.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    
    // 2. 规范化换行符
    processed = processed.replaceAll(RegExp(r'\r\n?'), '\n');
    
    // 3. 处理可能的标题（全大写短行）
    processed = processed.replaceAllMapped(
      RegExp(r'^([A-Z\s\d]{3,50})$', multiLine: true),
      (match) => '## ${match.group(1)}\n'
    );
    
    // 4. 处理数字列表
    processed = processed.replaceAllMapped(
      RegExp(r'^(\d+\.?\s+)(.+)$', multiLine: true),
      (match) => '${match.group(1)}${match.group(2)}'
    );
    
    // 5. 处理项目符号
    processed = processed.replaceAllMapped(
      RegExp(r'^([•·▪▫‣⁃]\s+)(.+)$', multiLine: true),
      (match) => '- ${match.group(2)}'
    );
    
    // 6. 清理行首尾空格
    final lines = processed.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    return lines.join('\n');
  }
  
  /// ❌ 生成错误信息的Markdown
  static String _generateErrorMarkdown(String pdfPath, String error) {
    return '''# ❌ PDF转换失败

**文件路径**: `$pdfPath`

**错误信息**: 
```
$error
```

**可能的解决方案**:
1. 检查PDF文件是否存在且未损坏
2. 确保PDF文件未被其他程序占用
3. 检查文件权限是否允许读取
4. 尝试使用其他PDF文件测试
5. 如果是扫描PDF，可能需要OCR工具

**转换时间**: ${DateTime.now().toString().split('.')[0]}

---

**技术说明**: 
此转换器使用纯Dart实现，对复杂PDF格式的支持有限。对于高质量转换，建议使用专业的PDF处理工具。
''';
  }
}

/// 🚀 主函数 - 直接运行转换
void main() async {
  const String pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  const String outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/converted_output.md';
  
  print('🎯 开始PDF转Markdown转换（纯Dart版本）');
  print('📁 输入文件: $pdfPath');
  print('📄 输出文件: $outputPath');
  
  try {
    // 转换PDF为Markdown
    final String markdownContent = await SimplePdfConverter.convertPdfToMarkdown(pdfPath);
    
    // 保存Markdown文件
    final File outputFile = File(outputPath);
    await outputFile.writeAsString(markdownContent, encoding: utf8);
    
    print('✅ 转换完成！');
    print('📄 输出文件已保存: $outputPath');
    print('📊 内容长度: ${markdownContent.length} 字符');
    
    // 显示前500字符预览
    if (markdownContent.length > 500) {
      print('\n📖 内容预览:');
      print('=' * 50);
      print(markdownContent.substring(0, 500) + '...');
      print('=' * 50);
    } else {
      print('\n📖 完整内容:');
      print('=' * 50);
      print(markdownContent);
      print('=' * 50);
    }
    
  } catch (e) {
    print('❌ 转换失败: $e');
    exit(1);
  }
}
