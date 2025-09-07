import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

/// 🎯 最终PDF转Markdown转换器
/// 专门处理复杂PDF文件，提供多种提取策略
class FinalPdfConverter {
  
  /// 📄 将PDF文件转换为Markdown
  static Future<String> convertPdfToMarkdown(String pdfPath) async {
    print('🔄 开始处理PDF文件: $pdfPath');
    
    try {
      // 读取PDF文件
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF文件不存在: $pdfPath');
      }
      
      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      print('📁 PDF文件大小: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // 多策略提取文本
      String extractedText = '';
      
      // 策略1：查找明显的文本内容
      print('🔍 策略1：查找ASCII文本内容...');
      final asciiText = _extractAsciiText(pdfBytes);
      if (asciiText.isNotEmpty) {
        extractedText += asciiText;
        print('✅ 找到 ${asciiText.length} 字符的ASCII文本');
      }
      
      // 策略2：查找UTF-8编码的文本
      print('🔍 策略2：查找UTF-8文本内容...');
      final utf8Text = _extractUtf8Text(pdfBytes);
      if (utf8Text.isNotEmpty) {
        extractedText += '\n\n' + utf8Text;
        print('✅ 找到 ${utf8Text.length} 字符的UTF-8文本');
      }
      
      // 策略3：基于模式的文本提取
      print('🔍 策略3：基于模式提取...');
      final patternText = _extractByPattern(pdfBytes);
      if (patternText.isNotEmpty) {
        extractedText += '\n\n' + patternText;
        print('✅ 找到 ${patternText.length} 字符的模式文本');
      }
      
      // 如果没有提取到任何有用文本
      if (extractedText.trim().isEmpty) {
        extractedText = _generateAnalysisReport(pdfBytes, pdfPath);
      }
      
      // 生成最终的Markdown文档
      return _generateMarkdownDocument(pdfPath, pdfBytes, extractedText);
      
    } catch (e) {
      print('❌ PDF处理失败: $e');
      return _generateErrorMarkdown(pdfPath, e.toString());
    }
  }
  
  /// 📝 提取ASCII文本内容
  static String _extractAsciiText(Uint8List pdfBytes) {
    final StringBuffer result = StringBuffer();
    final String content = String.fromCharCodes(pdfBytes);
    
    // 查找常见的文本模式
    final patterns = [
      RegExp(r'\(([\x20-\x7E\s]+)\)'),  // 括号中的ASCII文本
      RegExp(r'<([0-9A-Fa-f\s]+)>'),   // 十六进制编码文本
      RegExp(r'([A-Za-z][A-Za-z0-9\s.,!?;:()\-]{10,})'), // 连续的可读文本
    ];
    
    final Set<String> foundTexts = {};
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        String text = match.group(1) ?? '';
        
        // 清理文本
        text = text.trim();
        if (text.length > 5 && _isReadableText(text) && !foundTexts.contains(text)) {
          foundTexts.add(text);
          result.writeln(text);
        }
      }
    }
    
    return result.toString();
  }
  
  /// 📝 提取UTF-8文本内容
  static String _extractUtf8Text(Uint8List pdfBytes) {
    final StringBuffer result = StringBuffer();
    
    try {
      // 尝试将字节作为UTF-8解码
      final String content = utf8.decode(pdfBytes, allowMalformed: true);
      
      // 查找可读的文本片段
      final RegExp textPattern = RegExp(r'[\u0020-\u007E\u4e00-\u9fff]+');
      final matches = textPattern.allMatches(content);
      
      final Set<String> foundTexts = {};
      
      for (final match in matches) {
        String text = match.group(0) ?? '';
        text = text.trim();
        
        if (text.length > 8 && _isReadableText(text) && !foundTexts.contains(text)) {
          foundTexts.add(text);
          result.writeln(text);
        }
      }
    } catch (e) {
      print('⚠️ UTF-8解码失败: $e');
    }
    
    return result.toString();
  }
  
  /// 📝 基于模式的文本提取
  static String _extractByPattern(Uint8List pdfBytes) {
    final StringBuffer result = StringBuffer();
    
    // 查找特定的PDF文本标记
    final String content = String.fromCharCodes(pdfBytes);
    
    // PDF文本对象模式
    final patterns = [
      RegExp(r'BT\s+(.*?)\s+ET', multiLine: true, dotAll: true),
      RegExp(r'Tj\s*\((.*?)\)', multiLine: true),
      RegExp(r'TJ\s*\[(.*?)\]', multiLine: true),
    ];
    
    final Set<String> foundTexts = {};
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(content);
      for (final match in matches) {
        String text = match.group(1) ?? '';
        
        // 清理PDF命令
        text = text
            .replaceAll(RegExp(r'\d+\.?\d*\s+\d+\.?\d*\s+Td'), '')
            .replaceAll(RegExp(r'/\w+\s+\d+\.?\d*\s+Tf'), '')
            .replaceAll(RegExp(r'\d+\.?\d*\s+TL'), '')
            .replaceAll(RegExp(r'[()]'), '')
            .trim();
        
        if (text.length > 3 && _isReadableText(text) && !foundTexts.contains(text)) {
          foundTexts.add(text);
          result.writeln(text);
        }
      }
    }
    
    return result.toString();
  }
  
  /// 📝 判断是否为可读文本
  static bool _isReadableText(String text) {
    if (text.length < 3) return false;
    
    // 检查是否包含字母或中文
    if (!RegExp(r'[a-zA-Z\u4e00-\u9fff]').hasMatch(text)) return false;
    
    // 排除PDF命令和二进制数据
    if (text.contains('obj') || 
        text.contains('endobj') ||
        text.contains('stream') ||
        text.contains('endstream') ||
        text.startsWith('/') ||
        text.contains('<<') ||
        text.contains('>>')) return false;
    
    // 检查可读字符比例
    final readableChars = text.replaceAll(RegExp(r'[^a-zA-Z0-9\u4e00-\u9fff\s.,!?;:()\-]'), '');
    return readableChars.length >= text.length * 0.7;
  }
  
  /// 📝 生成PDF分析报告
  static String _generateAnalysisReport(Uint8List pdfBytes, String pdfPath) {
    final StringBuffer report = StringBuffer();
    
    report.writeln('## 📊 PDF文件分析报告\n');
    
    // 基本信息
    report.writeln('### 基本信息');
    report.writeln('- **文件大小**: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
    report.writeln('- **文件路径**: `$pdfPath`');
    
    // 内容分析
    final String content = String.fromCharCodes(pdfBytes);
    
    // PDF版本
    final versionMatch = RegExp(r'%PDF-(\d+\.\d+)').firstMatch(content);
    if (versionMatch != null) {
      report.writeln('- **PDF版本**: ${versionMatch.group(1)}');
    }
    
    // 对象计数
    final objCount = RegExp(r'\d+\s+\d+\s+obj').allMatches(content).length;
    report.writeln('- **对象数量**: $objCount');
    
    // 流对象计数
    final streamCount = RegExp(r'stream').allMatches(content).length;
    report.writeln('- **流对象数量**: $streamCount');
    
    // 图像检测
    final imageCount = RegExp(r'/Image|/XObject').allMatches(content).length;
    if (imageCount > 0) {
      report.writeln('- **可能包含图像**: $imageCount 个');
    }
    
    // 字体检测
    final fontCount = RegExp(r'/Font').allMatches(content).length;
    if (fontCount > 0) {
      report.writeln('- **字体定义**: $fontCount 个');
    }
    
    report.writeln('\n### 可能的原因');
    report.writeln('1. **图像PDF**: 此PDF可能主要由扫描图像组成');
    report.writeln('2. **复杂编码**: 使用了特殊的字体编码或压缩');
    report.writeln('3. **受保护**: PDF可能有安全限制');
    report.writeln('4. **格式特殊**: 使用了不常见的PDF特性');
    
    report.writeln('\n### 建议解决方案');
    report.writeln('1. 使用专业PDF工具（如Adobe Acrobat）导出文本');
    report.writeln('2. 如果是扫描PDF，使用OCR工具识别文字');
    report.writeln('3. 尝试在线PDF转换服务');
    report.writeln('4. 检查PDF是否有密码保护');
    
    return report.toString();
  }
  
  /// 📝 生成最终的Markdown文档
  static String _generateMarkdownDocument(String pdfPath, Uint8List pdfBytes, String extractedText) {
    final StringBuffer doc = StringBuffer();
    final String fileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    
    // 文档头部
    doc.writeln('# $fileName\n');
    doc.writeln('> PDF文档转换结果 - ${DateTime.now().toString().split('.')[0]}\n');
    
    // 提取的内容
    if (extractedText.trim().isNotEmpty) {
      doc.writeln('## 📄 提取的内容\n');
      
      // 处理和格式化文本
      final processedText = _formatExtractedText(extractedText);
      doc.writeln(processedText);
    } else {
      doc.writeln('## ⚠️ 无法提取文本内容\n');
      doc.writeln('此PDF文件无法通过简单的文本提取方法获取可读内容。');
    }
    
    doc.writeln('\n---\n');
    
    // 技术信息
    doc.writeln('## 🔧 转换信息\n');
    doc.writeln('- **原始文件**: `$pdfPath`');
    doc.writeln('- **文件大小**: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
    doc.writeln('- **转换工具**: 纯Dart PDF解析器');
    doc.writeln('- **转换时间**: ${DateTime.now().toString().split('.')[0]}');
    doc.writeln('- **提取字符数**: ${extractedText.length}');
    
    return doc.toString();
  }
  
  /// 📝 格式化提取的文本
  static String _formatExtractedText(String rawText) {
    if (rawText.trim().isEmpty) return '';
    
    // 按行分割并清理
    final lines = rawText.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    
    final StringBuffer formatted = StringBuffer();
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // 检测标题
      if (line.length < 60 && 
          (line == line.toUpperCase() || 
           RegExp(r'^\d+\.?\s+[A-Z]').hasMatch(line))) {
        formatted.writeln('### $line\n');
      }
      // 检测列表
      else if (RegExp(r'^[•·▪▫‣⁃-]\s+|^\d+\.?\s+').hasMatch(line)) {
        formatted.writeln('- ${line.replaceFirst(RegExp(r'^[•·▪▫‣⁃-]\s*|\d+\.?\s*'), '')}');
      }
      // 普通文本
      else {
        formatted.writeln(line);
        
        // 段落分隔
        if (line.endsWith('.') || line.endsWith('!') || line.endsWith('?')) {
          formatted.writeln('');
        }
      }
    }
    
    return formatted.toString();
  }
  
  /// ❌ 生成错误信息的Markdown
  static String _generateErrorMarkdown(String pdfPath, String error) {
    return '''# ❌ PDF转换失败

**文件**: `$pdfPath`

**错误**: $error

**时间**: ${DateTime.now().toString().split('.')[0]}

## 🔧 建议

1. 检查PDF文件是否完整且未损坏
2. 确认文件权限允许读取
3. 尝试使用专业PDF工具
4. 如果是扫描PDF，考虑使用OCR工具

---

*此工具使用纯Dart实现，功能有限。对于复杂PDF，建议使用专业工具。*
''';
  }
}

/// 🚀 主函数
void main() async {
  const String pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  const String outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/final_output.md';
  
  print('🎯 PDF转Markdown转换器 - 最终版本');
  print('📁 输入: $pdfPath');
  print('📄 输出: $outputPath');
  print('');
  
  try {
    final String result = await FinalPdfConverter.convertPdfToMarkdown(pdfPath);
    
    await File(outputPath).writeAsString(result, encoding: utf8);
    
    print('');
    print('✅ 转换完成！');
    print('📄 结果已保存到: $outputPath');
    print('📊 文档长度: ${result.length} 字符');
    
    // 显示预览
    print('\n📖 内容预览:');
    print('=' * 60);
    if (result.length > 500) {
      print(result.substring(0, 500) + '\n...');
    } else {
      print(result);
    }
    print('=' * 60);
    
  } catch (e) {
    print('❌ 转换失败: $e');
    exit(1);
  }
}
