import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:appflowy_backend/log.dart';

/// Professional PDF processor with enhanced structure preservation
/// Specifically designed to maintain high fidelity with source documents
class ProfessionalPdfProcessor {
  
  /// Process PDF bytes with maximum fidelity preservation - 专门优化中文文档和表格处理
  static Future<String> processPdfBytes(Uint8List bytes) async {
    try {
      Log.info('Starting professional PDF processing with enhanced Chinese document support...');
      
      final document = sf.PdfDocument(inputBytes: bytes);
      final metadata = _extractEnhancedMetadata(document);
      
      // 使用全文档提取方式，避免分页破坏结构
      final textExtractor = sf.PdfTextExtractor(document);
      final rawText = textExtractor.extractText();
      
      // 立即检测并清理可能的HTML内容
      final fullText = _cleanHtmlContent(rawText);
      
      Log.info('Full document text extracted, length: ${fullText.length}');
      if (rawText.length != fullText.length) {
        Log.info('HTML content detected and cleaned, original length: ${rawText.length}, cleaned length: ${fullText.length}');
      }
      
      // 智能结构分析和格式化
      final enhancedMarkdown = _processFullDocumentText(fullText, metadata);
      
      document.dispose();
      return enhancedMarkdown;
      
    } catch (e) {
      Log.error('Professional PDF processing failed: $e');
      throw Exception('Failed to process PDF with professional processor: $e');
    }
  }

  /// Extract comprehensive metadata including document structure hints
  static EnhancedPdfMetadata _extractEnhancedMetadata(sf.PdfDocument document) {
    final info = document.documentInformation;
    final pageCount = document.pages.count;
    
    return EnhancedPdfMetadata(
      title: info.title.isNotEmpty ? info.title : null,
      author: info.author.isNotEmpty ? info.author : null,
      subject: info.subject.isNotEmpty ? info.subject : null,
      keywords: info.keywords.isNotEmpty ? info.keywords : null,
      creator: info.creator.isNotEmpty ? info.creator : null,
      producer: info.producer.isNotEmpty ? info.producer : null,
      creationDate: info.creationDate,
      modificationDate: info.modificationDate,
      pageCount: pageCount,
      documentType: _detectDocumentType(info, pageCount),
      language: _detectLanguage(info),
    );
  }

  /// 专门处理完整文档文本，优化中文文档和表格结构
  static String _processFullDocumentText(String fullText, EnhancedPdfMetadata metadata) {
    final StringBuffer result = StringBuffer();
    
    // 添加文档头部信息
    if (metadata.title != null && metadata.title!.isNotEmpty) {
      result.writeln('# ${metadata.title}');
      result.writeln();
    }
    
    if (metadata.author != null && metadata.author!.isNotEmpty) {
      result.writeln('**作者:** ${metadata.author}');
    }
    
    if (metadata.subject != null && metadata.subject!.isNotEmpty) {
      result.writeln('**主题:** ${metadata.subject}');
    }
    
    if (metadata.pageCount > 0) {
      result.writeln('**页数:** ${metadata.pageCount}');
    }
    
    if (result.isNotEmpty) {
      result.writeln();
      result.writeln('---');
      result.writeln();
    }
    
    // 智能文本处理和结构识别
    final processedText = _intelligentTextProcessing(fullText);
    result.write(processedText);
    
    return result.toString();
  }

  /// 智能文本处理，专门优化中文文档格式
  static String _intelligentTextProcessing(String text) {
    if (text.trim().isEmpty) return text;
    
    final lines = text.split('\n');
    final processedLines = <String>[];
    
    bool inTable = false;
    final tableRows = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty) {
        // 保留空行，但避免过多连续空行
        if (processedLines.isNotEmpty && processedLines.last.trim().isNotEmpty) {
          processedLines.add('');
        }
        continue;
      }
      
      // 检测表格行（包含多个制表符或特定模式）
      if (_isTableRow(line, i, lines)) {
        if (!inTable) {
          inTable = true;
          tableRows.clear();
        }
        tableRows.add(_formatTableRow(line));
        continue;
      } else if (inTable) {
        // 结束表格处理
        if (tableRows.isNotEmpty) {
          processedLines.addAll(_generateMarkdownTable(tableRows));
          processedLines.add('');
        }
        inTable = false;
        tableRows.clear();
      }
      
      // 检测标题
      if (_isTitle(line, i, lines)) {
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
    
    // 处理最后的表格
    if (inTable && tableRows.isNotEmpty) {
      processedLines.addAll(_generateMarkdownTable(tableRows));
    }
    
    return processedLines.join('\n');
  }

  /// Enhanced table row detection with better pattern recognition
  static bool _isTableRow(String line, int index, List<String> allLines) {
    if (line.trim().isEmpty) return false;
    
    // 1. 明确的表格分隔符检测
    if (line.contains('\t') && line.split('\t').length > 2) return true;
    if (line.contains('|') && line.split('|').length >= 3) return true;
    
    // 2. 中文表格关键词检测
    final chineseTableKeywords = [
      '材料类型', '材料名称', '具体要求', '序号', '项目', '内容', '数量', 
      '单价', '金额', '备注', '规格', '型号', '品牌', '日期', '时间',
      '姓名', '职务', '部门', '联系方式', '地址', '编号', '代码'
    ];
    
    for (final keyword in chineseTableKeywords) {
      if (line.contains(keyword)) return true;
    }
    
    // 3. 数字-文本混合模式检测（表格特征）
    final parts = line.split(RegExp(r'\s{2,}'));
    if (parts.length >= 3) {
      int numericCount = 0;
      int textCount = 0;
      int dateCount = 0;
      
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        
        // 检测数字（包括货币、百分比、小数）
        if (RegExp(r'^\d+(\.\d+)?[%$¥€£]?$').hasMatch(trimmed) ||
            RegExp(r'^[¥$€£]\d+(\.\d+)?$').hasMatch(trimmed) ||
            RegExp(r'^\d{1,3}(,\d{3})*(\.\d+)?$').hasMatch(trimmed)) {
          numericCount++;
        }
        // 检测日期
        else if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{2,4}$').hasMatch(trimmed) ||
                 RegExp(r'^\d{4}[/-]\d{1,2}[/-]\d{1,2}$').hasMatch(trimmed) ||
                 RegExp(r'^\d{4}年\d{1,2}月\d{1,2}日$').hasMatch(trimmed)) {
          dateCount++;
        }
        // 检测文本
        else if (RegExp(r'^[a-zA-Z\u4e00-\u9fa5]').hasMatch(trimmed)) {
          textCount++;
        }
      }
      
      // 表格特征：有数字/日期和文本混合，且字段数量合理
      if ((numericCount > 0 || dateCount > 0) && textCount > 0 && parts.length >= 3) {
        return true;
      }
    }
    
    // 4. 上下文检测 - 检查前后行是否也有表格特征
    if (parts.length > 2) {
      int contextMatches = 0;
      
      // 检查前面2行
      for (int i = Math.max(0, index - 2); i < index; i++) {
        final contextParts = allLines[i].trim().split(RegExp(r'\s{2,}'));
        if (contextParts.length > 2) contextMatches++;
      }
      
      // 检查后面2行
      for (int i = index + 1; i < Math.min(allLines.length, index + 3); i++) {
        final contextParts = allLines[i].trim().split(RegExp(r'\s{2,}'));
        if (contextParts.length > 2) contextMatches++;
      }
      
      // 如果上下文中有多行都有表格特征，则认为当前行是表格行
      if (contextMatches >= 2) return true;
    }
    
    // 5. 表格边框字符检测
    if (RegExp(r'^[\s\-_=\+\|]*$').hasMatch(line) && line.length > 5) {
      return true;
    }
    
    // 6. 对齐模式检测（多个字段对齐）
    if (parts.length >= 3) {
      bool hasAlignedFields = true;
      for (final part in parts) {
        if (part.trim().length < 1) {
          hasAlignedFields = false;
          break;
        }
      }
      if (hasAlignedFields) return true;
    }
    
    return false;
  }

  /// Enhanced table row formatting with better column alignment
  static String _formatTableRow(String line) {
    String formatted = line.trim();
    
    // 1. 处理制表符分隔
    if (formatted.contains('\t')) {
      final parts = formatted.split('\t');
      return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' | ');
    }
    
    // 2. 处理管道符分隔
    if (formatted.contains('|')) {
      final parts = formatted.split('|');
      return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' | ');
    }
    
    // 3. 处理多个空格分隔
    final parts = formatted.split(RegExp(r'\s{2,}'));
    if (parts.length >= 2) {
      return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' | ');
    }
    
    // 4. 处理特殊字符分隔（如冒号、分号等）
    if (RegExp(r'[：:；;，,]').hasMatch(formatted)) {
      final parts = formatted.split(RegExp(r'[：:；;，,]\s*'));
      if (parts.length >= 2) {
        return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' | ');
      }
    }
    
    // 5. 智能字段检测（基于中文和数字模式）
    final smartParts = _smartSplitTableRow(formatted);
    if (smartParts.length >= 2) {
      return smartParts.join(' | ');
    }
    
    // 6. 默认返回原行（可能是单列表格或特殊格式）
    return formatted;
  }
  
  /// Smart table row splitting based on content patterns
  static List<String> _smartSplitTableRow(String line) {
    final parts = <String>[];
    final buffer = StringBuffer();
    final chars = line.split('');
    
    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];
      final nextChar = i < chars.length - 1 ? chars[i + 1] : '';
      // final prevChar = i > 0 ? chars[i - 1] : '';
      
      buffer.write(char);
      
      // 检测分割点：
      // 1. 数字后跟中文
      if (RegExp(r'\d').hasMatch(char) && RegExp(r'[\u4e00-\u9fa5]').hasMatch(nextChar)) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      }
      // 2. 中文后跟数字
      else if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(char) && RegExp(r'\d').hasMatch(nextChar)) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      }
      // 3. 连续空格
      else if (char == ' ' && nextChar == ' ') {
        parts.add(buffer.toString().trim());
        buffer.clear();
        // 跳过多余空格
        while (i < chars.length - 1 && chars[i + 1] == ' ') {
          i++;
        }
      }
    }
    
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().trim());
    }
    
    return parts.where((p) => p.isNotEmpty).toList();
  }

  /// Enhanced Markdown table generation with proper formatting
  static List<String> _generateMarkdownTable(List<String> rows) {
    if (rows.isEmpty) return [];
    
    final result = <String>[];
    final processedRows = <List<String>>[];
    
    // 1. 预处理所有行，统一列数
    int maxColumns = 0;
    for (final row in rows) {
      final columns = row.split(' | ');
      maxColumns = Math.max(maxColumns, columns.length);
      processedRows.add(columns);
    }
    
    // 2. 补齐列数不足的行
    for (final columns in processedRows) {
      while (columns.length < maxColumns) {
        columns.add('');
      }
    }
    
    // 3. 计算每列的最大宽度（用于对齐）
    final columnWidths = List<int>.filled(maxColumns, 0);
    for (final columns in processedRows) {
      for (int i = 0; i < columns.length; i++) {
        columnWidths[i] = Math.max(columnWidths[i], columns[i].trim().length);
      }
    }
    
    // 4. 生成表格
    for (int rowIndex = 0; rowIndex < processedRows.length; rowIndex++) {
      final columns = processedRows[rowIndex];
      final formattedColumns = <String>[];
      
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final content = columns[colIndex].trim();
        final width = Math.max(columnWidths[colIndex], 3); // 最小宽度3
        formattedColumns.add(content.padRight(width));
      }
      
      result.add('| ${formattedColumns.join(' | ')} |');
      
      // 在第一行（表头）后添加分隔符
      if (rowIndex == 0) {
        final separatorColumns = <String>[];
        for (int i = 0; i < maxColumns; i++) {
          final width = Math.max(columnWidths[i], 3);
          separatorColumns.add('-' * width);
        }
        result.add('| ${separatorColumns.join(' | ')} |');
      }
    }
    
    return result;
  }

  /// 检测是否为标题
  static bool _isTitle(String line, int index, List<String> allLines) {
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
    // 移除多余的空格，但保留中文文本的自然间距
    return line.replaceAll(RegExp(r'\s+'), ' ').trim();
  }


  // Helper methods for structure detection and classification

  static DocumentType _detectDocumentType(sf.PdfDocumentInformation info, int pageCount) {
    final title = info.title.toLowerCase();
    final subject = info.subject.toLowerCase();
    
    if (title.contains('manual') || title.contains('guide') || subject.contains('manual')) {
      return DocumentType.manual;
    }
    if (title.contains('report') || subject.contains('report')) {
      return DocumentType.report;
    }
    if (title.contains('paper') || title.contains('article') || subject.contains('research')) {
      return DocumentType.academic;
    }
    if (pageCount == 1) {
      return DocumentType.letter;
    }
    return DocumentType.document;
  }

  static String? _detectLanguage(sf.PdfDocumentInformation info) {
    // Simple language detection based on metadata
    final title = info.title;
    final subject = info.subject;
    
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(title + subject)) {
      return 'zh';
    }
    return 'en';
  }


}

// Enhanced data classes for professional PDF processing

class EnhancedPdfMetadata {
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;
  final String? producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int pageCount;
  final DocumentType documentType;
  final String? language;

  const EnhancedPdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    required this.pageCount,
    required this.documentType,
    this.language,
  });
}

enum DocumentType {
  unknown,
  document,
  report,
  manual,
  academic,
  letter,
  presentation,
}

class DocumentStructureAnalysis {
  final List<PageStructure> pageStructures;
  final HeaderPattern headerPattern;
  final FooterPattern footerPattern;
  final FontHierarchy fontHierarchy;
  final DocumentLayout documentLayout;

  const DocumentStructureAnalysis({
    required this.pageStructures,
    required this.headerPattern,
    required this.footerPattern,
    required this.fontHierarchy,
    required this.documentLayout,
  });
}

class PageStructure {
  final int pageNumber;
  final List<EnhancedTextBlock> textBlocks;
  final bool hasHeader;
  final bool hasFooter;
  final int columnCount;

  const PageStructure({
    required this.pageNumber,
    required this.textBlocks,
    required this.hasHeader,
    required this.hasFooter,
    required this.columnCount,
  });
}

class EnhancedTextBlock {
  final String text;
  final TextBlockType blockType;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final TextAlignment alignment;
  final int indentLevel;
  final int lineNumber;
  final int pageNumber;

  const EnhancedTextBlock({
    required this.text,
    required this.blockType,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.alignment,
    required this.indentLevel,
    required this.lineNumber,
    required this.pageNumber,
  });
}

enum TextBlockType {
  header,
  paragraph,
  footer,
  numberedList,
  bulletList,
  table,
  quote,
}

enum TextAlignment {
  left,
  center,
  right,
  justify,
}

enum HeaderPattern {
  none,
  partial,
  consistent,
}

enum FooterPattern {
  none,
  partial,
  consistent,
}

class FontHierarchy {
  final double titleSize;
  final double headingSize;
  final double bodySize;
  final double captionSize;
  final List<double> allSizes;

  const FontHierarchy({
    required this.titleSize,
    required this.headingSize,
    required this.bodySize,
    required this.captionSize,
    required this.allSizes,
  });
}

enum DocumentLayout {
  singleColumn,
  doubleColumn,
  multiColumn,
  mixed,
}

class StructuredDocumentContent {
  final List<StructuredPage> pages;
  final DocumentStructureAnalysis documentStructure;

  const StructuredDocumentContent({
    required this.pages,
    required this.documentStructure,
  });
}

class StructuredPage {
  final int pageNumber;
  final List<StructuredElement> elements;
  final bool hasHeader;
  final bool hasFooter;
  final int columnCount;

  const StructuredPage({
    required this.pageNumber,
    required this.elements,
    required this.hasHeader,
    required this.hasFooter,
    required this.columnCount,
  });
}

class StructuredElement {
  final ElementType type;
  final String text;
  final TextFormatting formatting;
  final int indentLevel;
  final ListType? listType;

  const StructuredElement({
    required this.type,
    required this.text,
    required this.formatting,
    required this.indentLevel,
    this.listType,
  });
}

enum ElementType {
  heading,
  paragraph,
  list,
  table,
  quote,
  code,
}

enum ListType {
  bullet,
  numbered,
}

class TextFormatting {
  final bool isBold;
  final bool isItalic;

  const TextFormatting({
    required this.isBold,
    required this.isItalic,
  });
}

/// Clean HTML content that might be extracted by PDF libraries
String _cleanHtmlContent(String text) {
  // Early return if no HTML detected
  if (!text.contains('<') || !text.contains('>')) {
    return text;
  }
  
  // Detect common HTML patterns that indicate HTML formatting
  final htmlPatterns = [
    '<html>',
    '<!DOCTYPE',
    '<body>',
    '<div>',
    '<p>',
    '<table>',
    '<tr>',
    '<td>',
    '<span>',
    'style=',
    'class=',
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
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&apos;': "'",
    '&nbsp;': ' ',
    '&#39;': "'",
    '&#34;': '"',
    '&#x27;': "'",
    '&#x2F;': '/',
    '&#x3D;': '=',
    '&#x60;': '`',
    '&#x3A;': ':',
    '&#x3B;': ';',
    '&#x2C;': ',',
    '&#x2E;': '.',
    '&#x21;': '!',
    '&#x3F;': '?',
    '&#x28;': '(',
    '&#x29;': ')',
    '&#x5B;': '[',
    '&#x5D;': ']',
    '&#x7B;': '{',
    '&#x7D;': '}',
  };
  
  htmlEntities.forEach((entity, replacement) {
    cleaned = cleaned.replaceAll(entity, replacement);
  });
  
  // Clean up Unicode entities (like &#x4e0a; for Chinese characters)
  cleaned = cleaned.replaceAll(RegExp(r'&#x[0-9a-fA-F]+;'), '');
  cleaned = cleaned.replaceAll(RegExp(r'&#[0-9]+;'), '');
  
  // Remove CSS style attributes and other HTML attributes
  cleaned = cleaned.replaceAll(RegExp(r'style\s*=\s*"[^"]*"'), '');
  cleaned = cleaned.replaceAll(RegExp(r"style\s*=\s*'[^']*'"), '');
  cleaned = cleaned.replaceAll(RegExp(r'class\s*=\s*"[^"]*"'), '');
  cleaned = cleaned.replaceAll(RegExp(r"class\s*=\s*'[^']*'"), '');
  cleaned = cleaned.replaceAll(RegExp(r'id\s*=\s*"[^"]*"'), '');
  cleaned = cleaned.replaceAll(RegExp(r"id\s*=\s*'[^']*'"), '');
  
  // Normalize whitespace after HTML removal
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
  cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n'); // Max 2 consecutive newlines
  
  return cleaned.trim();
}
