import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' show Size;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf_render/pdf_render.dart' as pdf_render;

/// 🎯 专业级PDF转Markdown转换器
/// 使用成熟的Flutter/Dart库实现高质量PDF解析和转换
class ProfessionalPdfConverter {
  
  /// 📄 将PDF文件转换为Markdown
  static Future<String> convertPdfToMarkdown(String pdfPath) async {
    print('🚀 专业PDF转Markdown转换器启动');
    print('📁 处理文件: $pdfPath');
    
    try {
      // 验证文件存在
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF文件不存在: $pdfPath');
      }
      
      final Uint8List pdfBytes = await pdfFile.readAsBytes();
      print('📊 文件大小: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      
      // 使用多种方法提取文本
      String extractedText = '';
      
      // 方法1: 使用Syncfusion PDF库提取文本
      print('🔍 方法1: 使用Syncfusion PDF提取文本...');
      final syncfusionText = await _extractTextWithSyncfusion(pdfBytes);
      if (syncfusionText.isNotEmpty) {
        extractedText += syncfusionText;
        print('✅ Syncfusion提取成功: ${syncfusionText.length} 字符');
      }
      
      // 方法2: 使用pdf_render库渲染页面并OCR识别
      print('🔍 方法2: 使用pdf_render + OCR识别...');
      final ocrText = await _extractTextWithOCR(pdfPath);
      if (ocrText.isNotEmpty && ocrText != syncfusionText) {
        extractedText += '\n\n' + ocrText;
        print('✅ OCR识别成功: ${ocrText.length} 字符');
      }
      
      // 如果两种方法都失败，生成分析报告
      if (extractedText.trim().isEmpty) {
        print('⚠️ 无法提取文本内容，生成分析报告...');
        extractedText = await _generateDetailedAnalysis(pdfBytes, pdfPath);
      }
      
      // 生成最终Markdown文档
      return _generateProfessionalMarkdown(pdfPath, extractedText);
      
    } catch (e, stackTrace) {
      print('❌ PDF转换失败: $e');
      print('📋 堆栈跟踪: $stackTrace');
      return _generateErrorMarkdown(pdfPath, e.toString());
    }
  }
  
  /// 📝 使用Syncfusion PDF库提取文本
  static Future<String> _extractTextWithSyncfusion(Uint8List pdfBytes) async {
    try {
      // 加载PDF文档
      final syncfusion.PdfDocument document = syncfusion.PdfDocument(inputBytes: pdfBytes);
      final StringBuffer textBuffer = StringBuffer();
      
      print('📄 PDF页数: ${document.pages.count}');
      
      // 遍历所有页面提取文本
      for (int i = 0; i < document.pages.count; i++) {
        final syncfusion.PdfPage page = document.pages[i];
        
        // 提取页面文本
        final String pageText = syncfusion.PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        
        if (pageText.trim().isNotEmpty) {
          textBuffer.writeln('## 第 ${i + 1} 页\n');
          textBuffer.writeln(pageText.trim());
          textBuffer.writeln('\n---\n');
        }
        
        print('📖 第${i + 1}页提取: ${pageText.length} 字符');
      }
      
      // 释放资源
      document.dispose();
      
      return textBuffer.toString();
      
    } catch (e) {
      print('⚠️ Syncfusion提取失败: $e');
      return '';
    }
  }
  
  /// 📝 使用pdf_render + OCR提取文本
  static Future<String> _extractTextWithOCR(String pdfPath) async {
    try {
      // 打开PDF文档
      final doc = await pdf_render.PdfDocument.openFile(pdfPath);
      final StringBuffer ocrResult = StringBuffer();
      
      // 初始化文字识别器
      final textRecognizer = TextRecognizer();
      
      print('📄 PDF页数: ${doc.pageCount}');
      
      // 处理前5页（避免处理时间过长）
      final maxPages = doc.pageCount > 5 ? 5 : doc.pageCount;
      
      for (int i = 1; i <= maxPages; i++) {
        try {
          // 渲染页面为图像
          final page = await doc.getPage(i);
          final pageImage = await page.render(width: 2048, height: 2048 * page.height ~/ page.width);
          
          // 将图像数据转换为InputImage
          final inputImage = InputImage.fromBytes(
            bytes: pageImage.pixels,
            metadata: InputImageMetadata(
              size: Size(pageImage.width.toDouble(), pageImage.height.toDouble()),
              rotation: InputImageRotation.rotation0deg,
              format: InputImageFormat.bgra8888,
              bytesPerRow: pageImage.width * 4,
            ),
          );
          
          // OCR识别文字
          final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
          
          if (recognizedText.text.trim().isNotEmpty) {
            ocrResult.writeln('## 第 $i 页 (OCR)\n');
            ocrResult.writeln(recognizedText.text.trim());
            ocrResult.writeln('\n---\n');
          }
          
          print('🔍 第${i}页OCR: ${recognizedText.text.length} 字符');
          
        } catch (e) {
          print('⚠️ 第${i}页OCR失败: $e');
        }
      }
      
      // 释放资源
      await textRecognizer.close();
      doc.dispose();
      
      return ocrResult.toString();
      
    } catch (e) {
      print('⚠️ OCR提取失败: $e');
      return '';
    }
  }
  
  /// 📊 生成详细的PDF分析报告
  static Future<String> _generateDetailedAnalysis(Uint8List pdfBytes, String pdfPath) async {
    final StringBuffer analysis = StringBuffer();
    
    analysis.writeln('## 📊 PDF文档详细分析\n');
    
    try {
      // 使用Syncfusion分析PDF结构
      final syncfusion.PdfDocument document = syncfusion.PdfDocument(inputBytes: pdfBytes);
      
      // 基本信息
      analysis.writeln('### 📋 基本信息');
      analysis.writeln('- **文件路径**: `$pdfPath`');
      analysis.writeln('- **文件大小**: ${(pdfBytes.length / 1024).toStringAsFixed(2)} KB');
      analysis.writeln('- **页面数量**: ${document.pages.count}');
      
      // 文档属性
      final docInfo = document.documentInformation;
      if (docInfo.title.isNotEmpty) {
        analysis.writeln('- **文档标题**: ${docInfo.title}');
      }
      if (docInfo.author.isNotEmpty) {
        analysis.writeln('- **作者**: ${docInfo.author}');
      }
      if (docInfo.subject.isNotEmpty) {
        analysis.writeln('- **主题**: ${docInfo.subject}');
      }
      if (docInfo.creator.isNotEmpty) {
        analysis.writeln('- **创建工具**: ${docInfo.creator}');
      }
      if (docInfo.producer.isNotEmpty) {
        analysis.writeln('- **生成器**: ${docInfo.producer}');
      }
      
      analysis.writeln('\n### 📄 页面信息');
      
      // 分析每页的内容
      for (int i = 0; i < document.pages.count && i < 10; i++) {
        final page = document.pages[i];
        analysis.writeln('- **第${i + 1}页**: ${page.size.width.toInt()} x ${page.size.height.toInt()} 点');
        
        // 尝试获取页面元素数量
        try {
          final annotations = page.annotations.count;
          if (annotations > 0) {
            analysis.writeln('  - 注释数量: $annotations');
          }
        } catch (e) {
          // 忽略注释获取错误
        }
      }
      
      analysis.writeln('\n### 🔍 可能的问题');
      analysis.writeln('1. **图像PDF**: 此PDF可能主要由扫描图像组成，需要OCR识别');
      analysis.writeln('2. **复杂布局**: PDF使用了复杂的布局或字体编码');
      analysis.writeln('3. **受保护内容**: PDF可能有内容保护或访问限制');
      analysis.writeln('4. **非标准格式**: 使用了特殊的PDF特性或压缩方式');
      
      analysis.writeln('\n### 💡 建议解决方案');
      analysis.writeln('1. **使用专业工具**: Adobe Acrobat、Foxit Reader等');
      analysis.writeln('2. **在线转换服务**: SmallPDF、ILovePDF等在线工具');
      analysis.writeln('3. **OCR识别**: 如果是扫描PDF，使用OCR工具');
      analysis.writeln('4. **原始文档**: 如果可能，获取原始Word或其他格式文档');
      
      document.dispose();
      
    } catch (e) {
      analysis.writeln('\n❌ **分析过程中出现错误**: $e');
    }
    
    return analysis.toString();
  }
  
  /// 📝 生成专业的Markdown文档
  static String _generateProfessionalMarkdown(String pdfPath, String content) {
    final StringBuffer markdown = StringBuffer();
    final String fileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    final DateTime now = DateTime.now();
    
    // 文档头部
    markdown.writeln('# $fileName\n');
    markdown.writeln('> 📄 PDF文档转换结果');
    markdown.writeln('> 🕐 转换时间: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
    markdown.writeln('> 🛠️ 转换工具: 专业PDF转换器 (Syncfusion + OCR)\n');
    
    // 内容处理和格式化
    if (content.trim().isNotEmpty) {
      markdown.writeln('## 📖 文档内容\n');
      
      // 清理和格式化内容
      final formattedContent = _formatMarkdownContent(content);
      markdown.writeln(formattedContent);
    } else {
      markdown.writeln('## ⚠️ 内容提取失败\n');
      markdown.writeln('无法从此PDF文件中提取可读文本内容。这可能是因为：');
      markdown.writeln('- PDF主要由图像组成');
      markdown.writeln('- 使用了特殊的字体编码');
      markdown.writeln('- 文档受到保护');
      markdown.writeln('- PDF格式不标准\n');
    }
    
    // 技术信息
    markdown.writeln('\n---\n');
    markdown.writeln('## 🔧 转换信息\n');
    markdown.writeln('| 项目 | 值 |');
    markdown.writeln('|------|-----|');
    markdown.writeln('| 原始文件 | `$pdfPath` |');
    markdown.writeln('| 转换工具 | Syncfusion Flutter PDF + Google ML Kit OCR |');
    markdown.writeln('| 转换时间 | ${now.toString().split('.')[0]} |');
    markdown.writeln('| 内容长度 | ${content.length} 字符 |');
    markdown.writeln('| 转换状态 | ${content.trim().isNotEmpty ? '✅ 成功' : '❌ 部分失败'} |');
    
    return markdown.toString();
  }
  
  /// 📝 格式化Markdown内容
  static String _formatMarkdownContent(String rawContent) {
    if (rawContent.trim().isEmpty) return '';
    
    // 分行处理
    final lines = rawContent.split('\n');
    final StringBuffer formatted = StringBuffer();
    
    bool inCodeBlock = false;
    String currentSection = '';
    
    for (String line in lines) {
      final trimmedLine = line.trim();
      
      // 跳过空行和分隔符
      if (trimmedLine.isEmpty || trimmedLine == '---') {
        if (currentSection.isNotEmpty) {
          formatted.writeln('');
        }
        continue;
      }
      
      // 检测代码块
      if (trimmedLine.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        formatted.writeln(trimmedLine);
        continue;
      }
      
      if (inCodeBlock) {
        formatted.writeln(line);
        continue;
      }
      
      // 检测标题（已有##的保持，其他的根据内容判断）
      if (trimmedLine.startsWith('##')) {
        formatted.writeln('\n$trimmedLine\n');
        currentSection = trimmedLine;
      }
      // 检测可能的标题
      else if (_isPossibleTitle(trimmedLine)) {
        if (!trimmedLine.startsWith('#')) {
          formatted.writeln('\n### $trimmedLine\n');
        } else {
          formatted.writeln('\n$trimmedLine\n');
        }
        currentSection = trimmedLine;
      }
      // 检测列表项
      else if (_isListItem(trimmedLine)) {
        if (!trimmedLine.startsWith('-') && !trimmedLine.startsWith('*') && !RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
          formatted.writeln('- $trimmedLine');
        } else {
          formatted.writeln(trimmedLine);
        }
      }
      // 普通段落
      else {
        formatted.writeln(trimmedLine);
        
        // 在句子结尾后添加空行
        if (trimmedLine.endsWith('.') || trimmedLine.endsWith('!') || trimmedLine.endsWith('?')) {
          formatted.writeln('');
        }
      }
    }
    
    return formatted.toString();
  }
  
  /// 判断是否为可能的标题
  static bool _isPossibleTitle(String line) {
    if (line.length < 3 || line.length > 100) return false;
    
    // 已经是标题格式的跳过
    if (line.startsWith('#')) return false;
    
    // 全大写且较短的可能是标题
    if (line == line.toUpperCase() && line.length < 50) return true;
    
    // 以数字开头的章节标题
    if (RegExp(r'^\d+\.?\s+[A-Z]').hasMatch(line)) return true;
    
    // 首字母大写且不以标点结尾的短行
    if (RegExp(r'^[A-Z]').hasMatch(line) && 
        !line.endsWith('.') && 
        !line.endsWith(',') && 
        !line.endsWith(';') &&
        line.length < 60) return true;
    
    return false;
  }
  
  /// 判断是否为列表项
  static bool _isListItem(String line) {
    // 已经是列表格式的
    if (line.startsWith('-') || line.startsWith('*') || line.startsWith('+')) return true;
    if (RegExp(r'^\d+\.').hasMatch(line)) return true;
    
    // 以特殊符号开头的
    if (RegExp(r'^[•·▪▫‣⁃→]').hasMatch(line)) return true;
    
    return false;
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

## 🔧 故障排除建议

### 1. 文件检查
- 确认PDF文件完整且未损坏
- 检查文件权限是否允许读取
- 验证文件路径是否正确

### 2. 替代方案
- 使用Adobe Acrobat等专业工具导出文本
- 尝试在线PDF转换服务（SmallPDF、ILovePDF等）
- 如果是扫描PDF，使用专门的OCR工具
- 联系文档提供方获取其他格式版本

### 3. 技术支持
如果问题持续存在，请提供以下信息：
- PDF文件的详细信息（大小、页数、创建工具等）
- 完整的错误堆栈跟踪
- 设备和系统信息

---

*此工具使用Syncfusion Flutter PDF库和Google ML Kit OCR技术。对于某些特殊格式的PDF，可能需要专业工具处理。*
''';
  }
}

/// 🚀 主函数 - 演示用法
void main() async {
  const String pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  const String outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/professional_output.md';
  
  print('🎯 专业PDF转Markdown转换器');
  print('📚 使用成熟库: Syncfusion PDF + Google ML Kit OCR');
  print('📁 输入文件: $pdfPath');
  print('📄 输出文件: $outputPath');
  print('');
  
  try {
    final String result = await ProfessionalPdfConverter.convertPdfToMarkdown(pdfPath);
    
    // 保存结果
    await File(outputPath).writeAsString(result, encoding: utf8);
    
    print('');
    print('🎉 转换完成！');
    print('📄 结果文件: $outputPath');
    print('📊 文档长度: ${result.length} 字符');
    
    // 显示预览
    print('\n📖 内容预览:');
    print('=' * 80);
    final preview = result.length > 800 ? result.substring(0, 800) + '\n...' : result;
    print(preview);
    print('=' * 80);
    
  } catch (e) {
    print('❌ 转换失败: $e');
    exit(1);
  }
}
