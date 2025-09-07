import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';

/// Enhanced PDF processor with comprehensive table and layout detection
/// Combines multiple processing strategies for maximum fidelity
class EnhancedPdfProcessor {

  /// Process PDF bytes with enhanced table and layout detection
  static Future<String> processPdfBytes(Uint8List bytes) async {
    PdfDocument? document;
    try {
      Log.info('🔧 启动增强PDF处理器，文件大小: ${bytes.length} bytes');
      
      // Load PDF document
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      Log.info('📄 文档加载成功，共 $pageCount 页');
      
      // Extract document information
      Log.info('📋 提取文档信息...');
      final docInfo = _extractDocumentInfo(document);
      Log.info('📋 文档标题: ${docInfo.title ?? "无"}');
      
      // Process pages with enhanced analysis
      final StringBuffer result = StringBuffer();
      
      // Add document header
      if (docInfo.title != null && docInfo.title!.isNotEmpty) {
        result.writeln('# ${docInfo.title}');
        result.writeln();
      }
      
      if (docInfo.author != null || docInfo.pageCount > 0) {
        if (docInfo.author != null) result.writeln('**作者:** ${docInfo.author}');
        if (docInfo.pageCount > 0) result.writeln('**页数:** ${docInfo.pageCount}');
        result.writeln();
        result.writeln('---');
        result.writeln();
      }
      
      // Extract and process all text
      Log.info('🔤 开始文本提取...');
      final textExtractor = PdfTextExtractor(document);
      final fullText = textExtractor.extractText();
      Log.info('🔤 原始文本长度: ${fullText.length}');
      Log.info('🔤 原始文本预览: ${fullText.substring(0, fullText.length > 300 ? 300 : fullText.length)}...');
      
      if (fullText.trim().isEmpty) {
        Log.info('⚠️ PDF文本提取为空，可能是扫描版PDF');
        return '# PDF文档\n\n此PDF可能是扫描版文档，无法提取文本内容。请尝试使用OCR功能。';
      }
      
      // Enhanced text processing with table detection
      Log.info('🔧 开始增强文本处理...');
      final processedText = processTextWithEnhancements(fullText);
      Log.info('🔧 增强处理完成，处理后长度: ${processedText.length}');
      result.write(processedText);
      
      final finalResult = result.toString();
      Log.info('✅ 增强PDF处理完成，最终输出长度: ${finalResult.length}');
      Log.info('📄 最终输出预览: ${finalResult.substring(0, finalResult.length > 500 ? 500 : finalResult.length)}...');
      
      return finalResult;
      
    } catch (e, stackTrace) {
      Log.error('❌ 增强PDF处理失败: $e');
      Log.error('❌ 堆栈跟踪: $stackTrace');
      throw Exception('Enhanced PDF processing failed: $e');
    } finally {
      document?.dispose();
    }
  }

  /// Extract comprehensive document information
  static DocumentInfo _extractDocumentInfo(PdfDocument document) {
    final info = document.documentInformation;
    
    return DocumentInfo(
      title: info.title.trim().isNotEmpty ? info.title.trim() : null,
      author: info.author.trim().isNotEmpty ? info.author.trim() : null,
      subject: info.subject.trim().isNotEmpty ? info.subject.trim() : null,
      keywords: info.keywords.trim().isNotEmpty ? info.keywords.trim() : null,
      creator: info.creator.trim().isNotEmpty ? info.creator.trim() : null,
      producer: info.producer.trim().isNotEmpty ? info.producer.trim() : null,
      creationDate: info.creationDate,
      modificationDate: info.modificationDate,
      pageCount: document.pages.count,
    );
  }

  /// Process text with enhanced table detection and formatting
  @visibleForTesting
  static String processTextWithEnhancements(String text) {
    if (text.trim().isEmpty) return text;
    
    final lines = text.split('\n');
    final processedLines = <String>[];
    
    bool inTable = false;
    final tableRows = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      
      if (line.isEmpty) {
        // Handle empty lines
        if (inTable && tableRows.isNotEmpty) {
          // End table on empty line
          processedLines.addAll(generateEnhancedTable(tableRows));
          processedLines.add('');
          tableRows.clear();
          inTable = false;
        } else if (processedLines.isNotEmpty && processedLines.last.trim().isNotEmpty) {
          processedLines.add('');
        }
        continue;
      }
      
      // Check for headings first (higher priority than tables)
      if (isEnhancedHeading(line, i, lines)) {
        // End any current table before adding heading
        if (inTable && tableRows.isNotEmpty) {
          processedLines.addAll(generateEnhancedTable(tableRows));
          processedLines.add('');
          tableRows.clear();
          inTable = false;
        }
        
        final level = determineHeadingLevel(line);
        final cleanTitle = cleanHeadingText(line);
        processedLines.add('${'#' * level} $cleanTitle');
        processedLines.add('');
        continue;
      }
      
      // Enhanced table detection
      if (isEnhancedTableRow(line, i, lines)) {
        if (!inTable) {
          inTable = true;
          tableRows.clear();
        }
        tableRows.add(formatEnhancedTableRow(line));
        continue;
      } else if (inTable) {
        // End table processing
        if (tableRows.isNotEmpty) {
          processedLines.addAll(generateEnhancedTable(tableRows));
          processedLines.add('');
        }
        inTable = false;
        tableRows.clear();
      }
      
      // Enhanced text processing
      line = _enhanceTextFormatting(line, i, lines);
      
      // Detect and format lists
      if (isEnhancedListItem(line)) {
        processedLines.add(formatEnhancedListItem(line));
        continue;
      }
      
      // Regular paragraph
      if (line.isNotEmpty) {
        processedLines.add(line);
      }
    }
    
    // Handle final table
    if (inTable && tableRows.isNotEmpty) {
      processedLines.addAll(generateEnhancedTable(tableRows));
    }
    
    return processedLines.join('\n');
  }

  /// Enhanced table row detection
  @visibleForTesting
  static bool isEnhancedTableRow(String line, int index, List<String> allLines) {
    if (line.trim().isEmpty) return false;
    
    // Strong indicators
    if (line.contains('\t') && line.split('\t').length >= 2) return true;
    if (line.contains('|') && line.split('|').length >= 3) return true;
    
    // Multiple space separation (table alignment)
    if (RegExp(r'\s{3,}').hasMatch(line)) {
      final parts = line.split(RegExp(r'\s{3,}'));
      if (parts.length >= 2) return true;
    }
    
    // Chinese table keywords - 扩展APP上架相关的表格关键词
    final tableKeywords = [
      // 通用表格关键词
      '序号', '项目', '内容', '材料', '规格', '数量', '单价', '金额',
      '姓名', '职务', '部门', '日期', '时间', '备注', '说明',
      
      // APP上架相关表格关键词
      '材料类别', '材料名称', '具体要求与说明', '准备状态',
      'A公司基础资质', 'B公司基础资质', '应用相关资质', '备案相关材料',
      '软件著作权登记证书', '企业营业执照副本', '法定代表人身份证正反面',
      '对公银行开户许可证', '应用名称', '应用图标', '应用截图', '应用简介',
      '关键词', '版本号', '安装包', '隐私政策', '用户协议', '各平台开发者账号',
      '测试设备与账号', '工信部备案申请表', '备案证书',
      
      // 表格标题行指示词
      '类别', '名称', '要求', '状态', '说明', '描述', '用途', '作用',
    ];
    
    for (final keyword in tableKeywords) {
      if (line.contains(keyword)) return true;
    }
    
    // Context-based detection
    if (index > 0 && index < allLines.length - 1) {
      final prevLine = allLines[index - 1].trim();
      final nextLine = allLines[index + 1].trim();
      
      if (_hasTablePattern(prevLine) || _hasTablePattern(nextLine)) {
        if (_hasTablePattern(line)) return true;
      }
    }
    
    return false;
  }
  
  /// Check if line has table-like patterns
  static bool _hasTablePattern(String line) {
    if (line.isEmpty) return false;
    
    // Check for colon-separated key-value pairs (common in forms)
    if (RegExp(r'[：:]\s*[^\s]').hasMatch(line)) {
      final parts = line.split(RegExp(r'[：:]'));
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        if (key.isNotEmpty && value.isNotEmpty && key.length < 50) {
          return true;
        }
      }
    }
    
    // Multiple fields separated by spaces (更宽松的检测)
    final parts = line.split(RegExp(r'\s{2,}'));  // 改为2个或更多空格
    if (parts.length >= 2) {
      // 检查是否有结构化数据模式
      bool hasStructuredData = false;
      
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          // 检查是否包含数字、中文、英文的组合
          if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(trimmed) && trimmed.length > 1) {
            hasStructuredData = true;
            break;
          }
          // 检查是否是常见的表格数据格式
          if (RegExp(r'^\d+(\.\d+)?[%$¥元]?$|^[A-Z]+\d*$|^[a-zA-Z]+\.(png|jpg|pdf)$').hasMatch(trimmed)) {
            hasStructuredData = true;
            break;
          }
        }
      }
      
      return hasStructuredData;
    }
    
    // Check for structured data patterns - 扩展APP上架相关模式
    if (RegExp(r'^\s*(地址|电话|邮箱|网站|联系|法定|注册|营业|备案|授权|申请|审核|周期|费用|资质|材料|软件|企业|对公|应用|版本|安装|隐私|用户|测试|工信部).*[：:]').hasMatch(line)) {
      return true;
    }
    
    // 检查是否包含APP上架相关的特定格式
    if (RegExp(r'(登记证书|营业执照|身份证|许可证|开发者账号|1024.*1024|PNG格式|4-6张|20-30字|200-500字|5-10个|APK|IPA格式|必须提供)').hasMatch(line)) {
      return true;
    }
    
    // 检查表格边框字符或分隔符
    if (RegExp(r'[│├┤┬┴┼─]').hasMatch(line)) {
      return true;
    }
    
    return false;
  }

  /// Format enhanced table row
  @visibleForTesting
  static String formatEnhancedTableRow(String line) {
    String formatted = line.trim();
    
    // Handle colon-separated key-value pairs
    if (RegExp(r'[：:]\s*[^\s]').hasMatch(formatted)) {
      final parts = formatted.split(RegExp(r'[：:]'));
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(':').trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          return '| $key | $value |';
        }
      }
    }
    
    // Handle different separators
    if (formatted.contains('\t')) {
      final parts = formatted.split('\t');
      final cleanParts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      return '| ${cleanParts.join(' | ')} |';
    }
    
    if (formatted.contains('|')) {
      final parts = formatted.split('|');
      final cleanParts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      return '| ${cleanParts.join(' | ')} |';
    }
    
    // Multiple spaces - 更宽松的分割（2个或更多空格）
    final parts = formatted.split(RegExp(r'\s{2,}'));
    if (parts.length >= 2) {
      final cleanParts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (cleanParts.length >= 2) {
        return '| ${cleanParts.join(' | ')} |';
      }
    }
    
    // 处理表格边框字符
    if (RegExp(r'[│├┤┬┴┼─]').hasMatch(formatted)) {
      // 移除表格边框字符并按空格分割
      final cleanLine = formatted.replaceAll(RegExp(r'[│├┤┬┴┼─]'), ' ');
      final parts = cleanLine.split(RegExp(r'\s+'));
      final cleanParts = parts.where((p) => p.trim().isNotEmpty).toList();
      if (cleanParts.length >= 2) {
        return '| ${cleanParts.join(' | ')} |';
      }
    }
    
    // 如果包含常见的表格内容，尝试智能分割
    if (RegExp(r'(登记证书|营业执照|身份证|许可证|开发者账号|1024.*1024|PNG格式|APK|IPA)').hasMatch(formatted)) {
      // 尝试在关键词前后分割
      final keywordMatch = RegExp(r'(软件著作权登记证书|企业营业执照副本|法定代表人身份证正反面|对公银行开户许可证|应用名称|应用图标|应用截图|应用简介|关键词|版本号|安装包|隐私政策|用户协议|各平台开发者账号|测试设备与账号|工信部备案申请表|备案证书)').firstMatch(formatted);
      if (keywordMatch != null) {
        final keyword = keywordMatch.group(0)!;
        final beforeKeyword = formatted.substring(0, keywordMatch.start).trim();
        final afterKeyword = formatted.substring(keywordMatch.end).trim();
        
        if (beforeKeyword.isNotEmpty && afterKeyword.isNotEmpty) {
          return '| $beforeKeyword | $keyword | $afterKeyword |';
        } else if (afterKeyword.isNotEmpty) {
          return '| $keyword | $afterKeyword |';
        }
      }
    }
    
    return '| $formatted |';
  }

  /// Generate enhanced markdown table
  @visibleForTesting
  static List<String> generateEnhancedTable(List<String> rows) {
    if (rows.isEmpty) return [];
    
    final result = <String>[];
    
    // Process rows to ensure consistent column count
    int maxColumns = 0;
    final processedRows = <List<String>>[];
    
    for (final row in rows) {
      final columns = row.split(' | ').map((c) => c.trim()).toList();
      maxColumns = maxColumns > columns.length ? maxColumns : columns.length;
      processedRows.add(columns);
    }
    
    // Pad rows to same column count
    for (final columns in processedRows) {
      while (columns.length < maxColumns) {
        columns.add('');
      }
    }
    
    // Generate table
    for (int i = 0; i < processedRows.length; i++) {
      final columns = processedRows[i];
      result.add('| ${columns.join(' | ')} |');
      
      // Add header separator after first row
      if (i == 0) {
        final separator = List.generate(maxColumns, (_) => '---').join(' | ');
        result.add('| $separator |');
      }
    }
    
    return result;
  }

  /// Enhanced heading detection
  @visibleForTesting
  static bool isEnhancedHeading(String line, int index, List<String> allLines) {
    // Don't treat table-like content as headings
    if (_hasTablePattern(line)) return false;
    
    // Chinese numbering patterns (strong indicators)
    if (RegExp(r'^[一二三四五六七八九十]+[、．.]').hasMatch(line)) return true;
    if (RegExp(r'^\d+[、．.]').hasMatch(line)) return true;
    if (RegExp(r'^第[一二三四五六七八九十\d]+[章节部分]').hasMatch(line)) return true;
    
    // Common document section headers
    if (RegExp(r'^(上架前准备|核心授权|资质与材料|备案流程|应用上架|第三方登录|短信验证码|注意事项|重要注意|时间规划)').hasMatch(line)) return true;
    
    // Process-related headers
    if (RegExp(r'^(备案|上架|申请|审核|流程|步骤|阶段|环节).*[：:]?$').hasMatch(line) && line.length < 30) return true;
    
    // Short lines that might be headings (but not table-like)
    if (line.length < 50 && index < allLines.length / 2) {
      // Make sure it's not table-like content
      if (!line.contains(RegExp(r'\s{3,}')) && !line.contains('\t') && !line.contains(':')) {
        // Check if followed by content
        if (index < allLines.length - 1) {
          final nextLine = allLines[index + 1].trim();
          if (nextLine.isNotEmpty && nextLine.length > line.length) {
            return true;
          }
        }
      }
    }
    
    // All caps (but not too long and not table-like)
    if (line.length < 100 && line == line.toUpperCase() && 
        RegExp(r'[A-Z]').hasMatch(line) && 
        !line.contains(RegExp(r'\s{3,}')) && !line.contains('\t')) return true;
    
    return false;
  }

  /// Determine heading level
  @visibleForTesting
  static int determineHeadingLevel(String line) {
    if (RegExp(r'^第[一二三四五六七八九十\d]+章').hasMatch(line)) return 1;
    if (RegExp(r'^[一二三四五六七八九十]+[、．.]').hasMatch(line)) return 2;
    if (RegExp(r'^\d+[、．.]').hasMatch(line)) return 3;
    if (line.length < 30) return 2;
    return 3;
  }

  /// Clean heading text
  @visibleForTesting
  static String cleanHeadingText(String line) {
    return line
        .replaceAll(RegExp(r'^[一二三四五六七八九十\d]+[、．.]'), '')
        .replaceAll(RegExp(r'^第[一二三四五六七八九十\d]+[章节部分]'), '')
        .trim();
  }

  /// Enhanced list item detection
  @visibleForTesting
  static bool isEnhancedListItem(String line) {
    return RegExp(r'^[•·▪▫‣⁃○●]\s+').hasMatch(line) ||
           RegExp(r'^\d+\.\s+').hasMatch(line) ||
           RegExp(r'^[（(]\d+[）)]\s+').hasMatch(line) ||
           RegExp(r'^[-*+]\s+').hasMatch(line);
  }

  /// Format enhanced list item
  @visibleForTesting
  static String formatEnhancedListItem(String line) {
    if (RegExp(r'^[•·▪▫‣⁃○●]\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^[•·▪▫‣⁃○●]\s+'), '- ');
    }
    if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
      return line; // Keep numbered lists as is
    }
    if (RegExp(r'^[（(]\d+[）)]\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^[（(]\d+[）)]\s+'), '1. ');
    }
    if (RegExp(r'^[-*+]\s+').hasMatch(line)) {
      return line.replaceFirst(RegExp(r'^[-*+]\s+'), '- ');
    }
    return line;
  }

  /// Enhanced text formatting
  static String _enhanceTextFormatting(String line, int index, List<String> allLines) {
    // Clean up excessive whitespace
    line = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Handle special characters and formatting
    return line;
  }

}

// Simplified data classes
class DocumentInfo {
  final String? title;
  final String? author;
  final String? subject;
  final String? keywords;
  final String? creator;
  final String? producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int pageCount;

  const DocumentInfo({
    this.title,
    this.author,
    this.subject,
    this.keywords,
    this.creator,
    this.producer,
    this.creationDate,
    this.modificationDate,
    required this.pageCount,
  });
}
