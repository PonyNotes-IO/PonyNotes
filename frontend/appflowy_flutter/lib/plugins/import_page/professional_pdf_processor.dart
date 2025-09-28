import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:appflowy_backend/log.dart';
import 'rust_pdf_processor.dart';

/// Professional PDF processor with Rust backend integration
class ProfessionalPdfProcessor {
  
  /// Process PDF file with Rust backend, fallback to Syncfusion
  static Future<String> processPdfBytes(File pdfFile) async {
    try {
      Log.info('Starting professional PDF processing...');
      
      // 优先使用Rust处理器
      try {
        final rustResult = await RustPdfProcessor.processPdfBytes(pdfFile);
        Log.info('Rust PDF processing successful, markdown length: ${rustResult.length}');
        return rustResult;
      } catch (rustError) {
        Log.warn('Rust PDF processing failed, falling back to Syncfusion: $rustError');
        // 读取PDF字节并回退到Syncfusion处理
        final bytes = await pdfFile.readAsBytes();
        return await _fallbackSyncfusionProcessing(bytes);
      }
      
    } catch (e) {
      Log.error('Professional PDF processing failed: $e');
      throw Exception('Failed to process PDF with professional processor: $e');
    }
  }
  
  /// 回退到Syncfusion处理方式
  static Future<String> _fallbackSyncfusionProcessing(Uint8List bytes) async {
    Log.info('Using Syncfusion fallback processing...');
    
    final document = sf.PdfDocument(inputBytes: bytes);
    final metadata = _extractMetadata(document);
    
    // 使用全文档提取方式
    final textExtractor = sf.PdfTextExtractor(document);
    final rawText = textExtractor.extractText();
    
    // 清理HTML内容
    final cleanText = _cleanHtmlContent(rawText);
    
    Log.info('Full document text extracted, length: ${cleanText.length}');
    
    // 智能结构分析和格式化
    final markdown = _processDocumentText(cleanText, metadata);
    
    document.dispose();
    return markdown;
  }

  /// 检查Rust处理器是否可用
  static Future<bool> isRustProcessorAvailable() async {
    return await RustPdfProcessor.isRustProcessorAvailable();
  }
  
  /// 构建Rust处理器（如果需要）
  static Future<void> buildRustProcessor() async {
    await RustPdfProcessor.buildRustProcessor();
  }

  /// Extract basic metadata
  static PdfMetadata _extractMetadata(sf.PdfDocument document) {
    final info = document.documentInformation;
    final pageCount = document.pages.count;
    
    return PdfMetadata(
      title: info.title.isNotEmpty ? info.title : null,
      author: info.author.isNotEmpty ? info.author : null,
      subject: info.subject.isNotEmpty ? info.subject : null,
      pageCount: pageCount,
    );
  }

  /// 处理文档文本，生成Markdown
  static String _processDocumentText(String text, PdfMetadata metadata) {
    final StringBuffer result = StringBuffer();
    
    // 添加文档头部信息
    if (metadata.title != null && metadata.title!.isNotEmpty) {
      result.writeln('# ${metadata.title}');
      result.writeln();
    }
    
    if (metadata.author != null && metadata.author!.isNotEmpty) {
      result.writeln('**作者:** ${metadata.author}');
    }
    
    if (metadata.pageCount > 0) {
      result.writeln('**页数:** ${metadata.pageCount}');
    }
    
    if (result.isNotEmpty) {
      result.writeln();
      result.writeln('---');
      result.writeln();
    }
    
    // 智能文本处理
    final processedText = _intelligentTextProcessing(text);
    result.write(processedText);
    
    return result.toString();
  }

  /// 智能文本处理
  static String _intelligentTextProcessing(String text) {
    if (text.trim().isEmpty) return text;
    
    final lines = text.split('\n');
    final processedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty) {
        if (processedLines.isNotEmpty && processedLines.last.trim().isNotEmpty) {
          processedLines.add('');
        }
        continue;
      }
      
      // 检测标题
      if (_isTitle(line)) {
        final level = _getTitleLevel(line);
        final cleanTitle = _cleanTitle(line);
        processedLines.add('${'#' * level} $cleanTitle');
        processedLines.add('');
        continue;
      }
      
      // 检测列表项
      if (_isListItem(line)) {
        processedLines.add(_formatListItem(line));
        continue;
      }
      
      // 处理普通段落
      final cleanedLine = _cleanLine(line);
      if (cleanedLine.isNotEmpty) {
        processedLines.add(cleanedLine);
      }
    }
    
    return processedLines.join('\n');
  }

  /// 检测是否为标题
  static bool _isTitle(String line) {
    // 中文标题特征
    if (RegExp(r'^[一二三四五六七八九十]+[、．.]').hasMatch(line)) return true;
    if (RegExp(r'^\d+[、．.]').hasMatch(line)) return true;
    if (RegExp(r'^第[一二三四五六七八九十\d]+[章节部分]').hasMatch(line)) return true;
    
    // 全大写或特殊格式
    if (line.length < 50 && line == line.toUpperCase() && line.contains(RegExp(r'[A-Z]'))) return true;
    
    // 居中文本（前后有空格）
    if (line.startsWith(' ') && line.endsWith(' ') && line.trim().length < 30) return true;
    
    // APP相关标题
    if (line.contains('APP') && line.length < 100) return true;
    
    return false;
  }

  /// 获取标题级别
  static int _getTitleLevel(String line) {
    if (RegExp(r'^第[一二三四五六七八九十\d]+章').hasMatch(line)) return 1;
    if (RegExp(r'^[一二三四五六七八九十]+[、．.]').hasMatch(line)) return 2;
    if (RegExp(r'^\d+[、．.]').hasMatch(line)) return 3;
    if (line.contains('APP') && line.length < 50) return 1;
    return 2;
  }

  /// 清理标题文本
  static String _cleanTitle(String line) {
    return line
        .replaceAll(RegExp(r'^[一二三四五六七八九十\d]+[、．.]'), '')
        .replaceAll(RegExp(r'^第[一二三四五六七八九十\d]+[章节部分]'), '')
        .trim();
  }

  /// 检测列表项
  static bool _isListItem(String line) {
    return RegExp(r'^[•·▪▫‣⁃○●]\s+').hasMatch(line) ||
           RegExp(r'^\d+\.\s+').hasMatch(line) ||
           RegExp(r'^[（(]\d+[）)]\s+').hasMatch(line);
  }

  /// 格式化列表项
  static String _formatListItem(String line) {
    if (RegExp(r'^[•·▪▫‣⁃○●]\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^[•·▪▫‣⁃○●]\s+'), '- ');
    }
    if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^\d+\.\s+'), '1. ');
    }
    if (RegExp(r'^[（(]\d+[）)]\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^[（(]\d+[）)]\s+'), '1. ');
    }
    return line;
  }

  /// 清理行文本
  static String _cleanLine(String line) {
    return line.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Clean HTML content that might be extracted by PDF libraries
  static String _cleanHtmlContent(String text) {
    // Early return if no HTML detected
    if (!text.contains('<') || !text.contains('>')) {
      return text;
    }
    
    // Detect common HTML patterns
    final htmlPatterns = [
      '<html>', '<!DOCTYPE', '<body>', '<div>', '<p>', '<table>', '<tr>', '<td>', '<span>',
      'style=', 'class=',
    ];
    
    bool hasHtmlContent = false;
    final lowerText = text.toLowerCase();
    for (final pattern in htmlPatterns) {
      if (lowerText.contains(pattern.toLowerCase())) {
        hasHtmlContent = true;
        break;
      }
    }
    
    if (!hasHtmlContent) {
      return text; // No HTML content detected
    }
    
    // Clean HTML content
    String cleaned = text;
    
    // Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Decode common HTML entities
    final htmlEntities = {
      '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&apos;': "'",
      '&nbsp;': ' ', '&#39;': "'", '&#34;': '"', '&#x27;': "'", '&#x2F;': '/',
      '&#x3D;': '=', '&#x60;': '`', '&#x3A;': ':', '&#x3B;': ';', '&#x2C;': ',',
      '&#x2E;': '.', '&#x21;': '!', '&#x3F;': '?', '&#x28;': '(', '&#x29;': ')',
      '&#x5B;': '[', '&#x5D;': ']', '&#x7B;': '{', '&#x7D;': '}',
    };
    
    htmlEntities.forEach((entity, replacement) {
      cleaned = cleaned.replaceAll(entity, replacement);
    });
    
    // Clean up Unicode entities
    cleaned = cleaned.replaceAll(RegExp(r'&#x[0-9a-fA-F]+;'), '');
    cleaned = cleaned.replaceAll(RegExp(r'&#[0-9]+;'), '');
    
    // Remove CSS style attributes
    cleaned = cleaned.replaceAll(RegExp(r'style\s*=\s*"[^"]*"'), '');
    cleaned = cleaned.replaceAll(RegExp(r"style\s*=\s*'[^']*'"), '');
    cleaned = cleaned.replaceAll(RegExp(r'class\s*=\s*"[^"]*"'), '');
    cleaned = cleaned.replaceAll(RegExp(r"class\s*=\s*'[^']*'"), '');
    
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return cleaned.trim();
  }
}

/// Basic PDF metadata
class PdfMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final int pageCount;

  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    required this.pageCount,
  });
}