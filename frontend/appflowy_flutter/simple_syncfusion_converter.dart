import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// 🎯 基于Syncfusion的PDF转Markdown转换器
/// 使用成熟的Syncfusion Flutter PDF库实现专业级PDF解析
class SyncfusionPdfConverter {
  
  /// 📄 将PDF文件转换为Markdown
  static Future<String> convertPdfToMarkdown(String pdfPath) async {
    print('🚀 Syncfusion PDF转Markdown转换器');
    print('📁 处理文件: $pdfPath');
    
    try {
      // 验证文件存在
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF文件不存在: $pdfPath');
      }
      
      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      print('📊 文件大小: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // 使用Syncfusion PDF库解析文档
      print('🔍 使用Syncfusion解析PDF...');
      final String extractedText = await _extractTextWithSyncfusion(pdfBytes);
      
      if (extractedText.trim().isEmpty) {
        print('⚠️ 无法提取文本内容，生成分析报告...');
        return _generateAnalysisReport(pdfBytes, pdfPath);
      }
      
      // 生成最终Markdown文档
      return _generateMarkdownDocument(pdfPath, extractedText);
      
    } catch (e, stackTrace) {
      print('❌ PDF转换失败: $e');
      print('📋 堆栈跟踪: $stackTrace');
      return _generateErrorMarkdown(pdfPath, e.toString());
    }
  }
  
  /// 📝 使用Syncfusion PDF库提取文本
  static Future<String> _extractTextWithSyncfusion(Uint8List pdfBytes) async {
    PdfDocument? document;
    
    try {
      // 加载PDF文档
      document = PdfDocument(inputBytes: pdfBytes);
      final StringBuffer textBuffer = StringBuffer();
      
      print('📄 PDF页数: ${document.pages.count}');
      
      // 创建文本提取器
      final PdfTextExtractor textExtractor = PdfTextExtractor(document);
      
      // 方法1: 提取全部文本
      print('🔍 方法1: 提取全部文本...');
      final String fullText = textExtractor.extractText();
      if (fullText.trim().isNotEmpty) {
        textBuffer.writeln('## 文档完整内容\n');
        textBuffer.writeln(fullText.trim());
        textBuffer.writeln('\n---\n');
        print('✅ 全文提取成功: ${fullText.length} 字符');
      }
      
      // 方法2: 逐页提取文本（如果全文提取失败或内容较少）
      if (fullText.trim().length < 100) {
        print('🔍 方法2: 逐页提取文本...');
        
        for (int i = 0; i < document.pages.count; i++) {
          try {
            // 提取单页文本
            final String pageText = textExtractor.extractText(
              startPageIndex: i, 
              endPageIndex: i
            );
            
            if (pageText.trim().isNotEmpty && pageText.trim() != fullText.trim()) {
              textBuffer.writeln('### 第 ${i + 1} 页\n');
              textBuffer.writeln(pageText.trim());
              textBuffer.writeln('\n---\n');
              print('📖 第${i + 1}页提取: ${pageText.length} 字符');
            }
          } catch (e) {
            print('⚠️ 第${i + 1}页提取失败: $e');
          }
        }
      }
      
      // 方法3: 尝试提取文档信息和元数据
      print('🔍 方法3: 提取文档元数据...');
      final String metadata = _extractDocumentMetadata(document);
      if (metadata.isNotEmpty) {
        textBuffer.writeln('## 文档信息\n');
        textBuffer.writeln(metadata);
        textBuffer.writeln('\n---\n');
      }
      
      return textBuffer.toString();
      
    } catch (e) {
      print('⚠️ Syncfusion提取失败: $e');
      return '';
    } finally {
      // 释放资源
      document?.dispose();
    }
  }
  
  /// 📝 提取文档元数据
  static String _extractDocumentMetadata(PdfDocument document) {
    final StringBuffer metadata = StringBuffer();
    
    try {
      final PdfDocumentInformation docInfo = document.documentInformation;
      
      if (docInfo.title.isNotEmpty) {
        metadata.writeln('**标题**: ${docInfo.title}');
      }
      if (docInfo.author.isNotEmpty) {
        metadata.writeln('**作者**: ${docInfo.author}');
      }
      if (docInfo.subject.isNotEmpty) {
        metadata.writeln('**主题**: ${docInfo.subject}');
      }
      if (docInfo.keywords.isNotEmpty) {
        metadata.writeln('**关键词**: ${docInfo.keywords}');
      }
      if (docInfo.creator.isNotEmpty) {
        metadata.writeln('**创建工具**: ${docInfo.creator}');
      }
      if (docInfo.producer.isNotEmpty) {
        metadata.writeln('**生成器**: ${docInfo.producer}');
      }
      if (docInfo.creationDate != null) {
        metadata.writeln('**创建时间**: ${docInfo.creationDate}');
      }
      if (docInfo.modificationDate != null) {
        metadata.writeln('**修改时间**: ${docInfo.modificationDate}');
      }
      
      // 页面信息
      metadata.writeln('**页面数量**: ${document.pages.count}');
      
      // 第一页尺寸信息
      if (document.pages.count > 0) {
        final firstPage = document.pages[0];
        metadata.writeln('**页面尺寸**: ${firstPage.size.width.toInt()} x ${firstPage.size.height.toInt()} 点');
      }
      
    } catch (e) {
      print('⚠️ 元数据提取失败: $e');
    }
    
    return metadata.toString();
  }
  
  /// 📊 生成分析报告
  static String _generateAnalysisReport(Uint8List pdfBytes, String pdfPath) {
    final StringBuffer analysis = StringBuffer();
    
    analysis.writeln('## 📊 PDF文档分析报告\n');
    
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      
      // 基本信息
      analysis.writeln('### 📋 基本信息');
      analysis.writeln('- **文件路径**: `$pdfPath`');
      analysis.writeln('- **文件大小**: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      analysis.writeln('- **页面数量**: ${document.pages.count}');
      
      // 文档属性
      final docInfo = document.documentInformation;
      analysis.writeln('\n### 📄 文档属性');
      analysis.writeln('- **标题**: ${docInfo.title.isEmpty ? "未设置" : docInfo.title}');
      analysis.writeln('- **作者**: ${docInfo.author.isEmpty ? "未设置" : docInfo.author}');
      analysis.writeln('- **创建工具**: ${docInfo.creator.isEmpty ? "未知" : docInfo.creator}');
      analysis.writeln('- **生成器**: ${docInfo.producer.isEmpty ? "未知" : docInfo.producer}');
      
      // 页面分析
      analysis.writeln('\n### 📄 页面信息');
      for (int i = 0; i < document.pages.count && i < 5; i++) {
        final page = document.pages[i];
        analysis.writeln('- **第${i + 1}页**: ${page.size.width.toInt()} x ${page.size.height.toInt()} 点');
      }
      
      if (document.pages.count > 5) {
        analysis.writeln('- **...** (共${document.pages.count}页)');
      }
      
      analysis.writeln('\n### 🔍 可能的问题');
      analysis.writeln('1. **扫描文档**: 此PDF可能是扫描版本，文字以图像形式存储');
      analysis.writeln('2. **复杂编码**: 使用了特殊的字体编码或文本布局');
      analysis.writeln('3. **图形内容**: 主要包含图形、图表或图像内容');
      analysis.writeln('4. **保护设置**: 可能设置了文本提取限制');
      
      analysis.writeln('\n### 💡 建议解决方案');
      analysis.writeln('1. **OCR识别**: 使用OCR工具识别扫描文档中的文字');
      analysis.writeln('2. **专业工具**: 使用Adobe Acrobat、Foxit等专业PDF工具');
      analysis.writeln('3. **在线服务**: 尝试SmallPDF、ILovePDF等在线转换服务');
      analysis.writeln('4. **原始格式**: 如果可能，获取原始Word或其他可编辑格式');
      
      document.dispose();
      
    } catch (e) {
      analysis.writeln('\n❌ **分析过程中出现错误**: $e');
    }
    
    return analysis.toString();
  }
  
  /// 📝 生成Markdown文档
  static String _generateMarkdownDocument(String pdfPath, String content) {
    final StringBuffer markdown = StringBuffer();
    final String fileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    final DateTime now = DateTime.now();
    
    // 文档头部
    markdown.writeln('# $fileName\n');
    markdown.writeln('> 📄 PDF文档转换结果');
    markdown.writeln('> 🕐 转换时间: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
    markdown.writeln('> 🛠️ 转换工具: Syncfusion Flutter PDF\n');
    
    // 处理和格式化内容
    if (content.trim().isNotEmpty) {
      markdown.writeln('## 📖 提取的内容\n');
      
      // 基本的内容清理和格式化
      final formattedContent = _formatContent(content);
      markdown.writeln(formattedContent);
    } else {
      markdown.writeln('## ⚠️ 内容提取失败\n');
      markdown.writeln('无法从此PDF文件中提取可读文本内容。');
      markdown.writeln('这可能是因为PDF主要由图像组成或使用了特殊编码。\n');
    }
    
    // 技术信息
    markdown.writeln('\n---\n');
    markdown.writeln('## 🔧 转换信息\n');
    markdown.writeln('| 项目 | 值 |');
    markdown.writeln('|------|-----|');
    markdown.writeln('| 原始文件 | `$pdfPath` |');
    markdown.writeln('| 转换工具 | Syncfusion Flutter PDF v27.2.5 |');
    markdown.writeln('| 转换时间 | ${now.toString().split('.')[0]} |');
    markdown.writeln('| 内容长度 | ${content.length} 字符 |');
    markdown.writeln('| 转换状态 | ${content.trim().isNotEmpty ? '✅ 成功' : '❌ 失败'} |');
    
    return markdown.toString();
  }
  
  /// 📝 格式化内容
  static String _formatContent(String rawContent) {
    if (rawContent.trim().isEmpty) return '';
    
    // 简单的内容清理
    String content = rawContent
        .replaceAll(RegExp(r'\r\n'), '\n')  // 统一换行符
        .replaceAll(RegExp(r'\r'), '\n')    // 统一换行符
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')  // 合并多个空行
        .trim();
    
    // 分段处理
    final lines = content.split('\n');
    final StringBuffer formatted = StringBuffer();
    
    for (String line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.isEmpty) {
        formatted.writeln('');
        continue;
      }
      
      // 保持现有的标题格式
      if (trimmedLine.startsWith('#')) {
        formatted.writeln(trimmedLine);
        formatted.writeln('');
        continue;
      }
      
      // 检测可能的标题（全大写且较短）
      if (trimmedLine.length < 80 && 
          trimmedLine == trimmedLine.toUpperCase() && 
          RegExp(r'[A-Z]').hasMatch(trimmedLine)) {
        formatted.writeln('### $trimmedLine\n');
        continue;
      }
      
      // 普通段落
      formatted.writeln(trimmedLine);
      
      // 在句子结尾后添加空行
      if (trimmedLine.endsWith('.') || 
          trimmedLine.endsWith('!') || 
          trimmedLine.endsWith('?')) {
        formatted.writeln('');
      }
    }
    
    return formatted.toString();
  }
  
  /// ❌ 生成错误Markdown
  static String _generateErrorMarkdown(String pdfPath, String error) {
    final DateTime now = DateTime.now();
    
    return '''# ❌ PDF转换失败

**文件**: `$pdfPath`

**错误信息**: 
```
$error
```

**时间**: ${now.toString().split('.')[0]}

## 🔧 故障排除

### 常见问题
1. **文件损坏**: PDF文件可能已损坏或不完整
2. **权限问题**: 文件可能设置了访问限制
3. **格式问题**: PDF使用了不支持的特殊格式

### 解决建议
1. 检查PDF文件是否能正常打开
2. 尝试使用其他PDF阅读器打开
3. 使用专业PDF工具进行转换
4. 联系文档提供方获取其他格式

---

*此工具使用Syncfusion Flutter PDF库。对于某些特殊PDF，可能需要专业工具处理。*
''';
  }
}

/// 🚀 主函数 - 演示用法
void main() async {
  const String pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  const String outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/syncfusion_output.md';
  
  print('🎯 Syncfusion PDF转Markdown转换器');
  print('📚 使用专业库: Syncfusion Flutter PDF v27.2.5');
  print('📁 输入文件: $pdfPath');
  print('📄 输出文件: $outputPath');
  print('');
  
  try {
    final String result = await SyncfusionPdfConverter.convertPdfToMarkdown(pdfPath);
    
    // 保存结果
    await File(outputPath).writeAsString(result, encoding: utf8);
    
    print('');
    print('🎉 转换完成！');
    print('📄 结果文件: $outputPath');
    print('📊 文档长度: ${result.length} 字符');
    
    // 显示预览
    print('\n📖 内容预览:');
    print('=' * 80);
    final preview = result.length > 1000 ? result.substring(0, 1000) + '\n...' : result;
    print(preview);
    print('=' * 80);
    
  } catch (e) {
    print('❌ 转换失败: $e');
    exit(1);
  }
}
