import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'advanced_pdf_processor.dart';
import 'visual_pdf_processor.dart';
import 'professional_pdf_processor.dart';
import 'enhanced_pdf_processor.dart';

class PdfMetadata {
  const PdfMetadata({
    this.title,
    this.author,
    this.subject,
    this.creator,
    this.producer,
    this.keywords,
    this.creationDate,
    this.modificationDate,
    this.pageCount = 0,
  });

  final String? title;
  final String? author;
  final String? subject;
  final String? creator;
  final String? producer;
  final String? keywords;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int pageCount;
}

class ImportResult {
  const ImportResult({
    required this.fileName,
    required this.content,
    required this.type,
    this.pdfMetadata,
  });

  final String fileName;
  final String content;
  final String type;
  final PdfMetadata? pdfMetadata;
}

class ImportService {
  static Future<ImportResult?> pickAndImportFile(String type) async {
    try {
      // Define file type filters based on import type
      List<String> allowedExtensions = [];

      switch (type) {
        case 'csv':
          allowedExtensions = ['csv'];
          break;
        case 'pdf':
          allowedExtensions = ['pdf'];
          break;
        case 'markdown':
          allowedExtensions = ['md', 'markdown', 'txt'];
          break;
        case 'html':
          allowedExtensions = ['html', 'htm'];
          break;
        case 'word':
          allowedExtensions = ['doc', 'docx'];
          break;
        default:
          allowedExtensions = ['*'];
      }

      // Pick file using AppFlowy's file picker service
      final result = await getIt<FilePickerService>().pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        // Read file content based on type
        String content = '';
        
        if (type == 'pdf') {
          // Extract PDF content using Syncfusion PDF library
          final pdfResult = await extractPdfContent(file);
          content = pdfResult.content;
          
          return ImportResult(
            fileName: fileName,
            content: content,
            type: type,
            pdfMetadata: pdfResult.metadata,
          );
        } else if (type == 'word') {
          // For Word documents, we'll need a DOCX parser library
          // For now, just return a placeholder
          content = 'Word document parsing not yet implemented';
        } else {
          // For text-based files (CSV, Markdown, HTML, TXT)
          content = await file.readAsString();
        }

        return ImportResult(
          fileName: fileName,
          content: content,
          type: type,
        );
      }
    } catch (e) {
      throw Exception('Failed to import file: $e');
    }
    
    return null;
  }

  static Future<void> importFromService(String service) async {
    // TODO: Implement third-party service import
    switch (service) {
      case 'notion':
        await _importFromNotion();
        break;
      case 'evernote':
        await _importFromEvernote();
        break;
      default:
        throw Exception('Unsupported service: $service');
    }
  }

  static Future<void> _importFromNotion() async {
    // TODO: Implement Notion API integration
    await Future.delayed(const Duration(seconds: 1));
    throw Exception('Notion import not yet implemented');
  }

  static Future<void> _importFromEvernote() async {
    // TODO: Implement Evernote API integration
    await Future.delayed(const Duration(seconds: 1));
    throw Exception('Evernote import not yet implemented');
  }

  /// Extract content and metadata from a PDF file with advanced options
  static Future<({String content, PdfMetadata metadata, Uint8List? pdfBytes})> extractPdfContent(File file) async {
    try {
      // Read the PDF file as bytes
      final Uint8List bytes = await file.readAsBytes();
      
      // First extract metadata using Syncfusion (for compatibility)
      PdfMetadata metadata;
      try {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        metadata = _extractPdfMetadata(document);
        document.dispose();
      } catch (e) {
        Log.error('Error extracting PDF metadata: $e');
        metadata = const PdfMetadata();
      }
      
      // Use enhanced PDF processor for maximum fidelity
      String content;
      try {
        content = await ProfessionalPdfProcessor.processPdfBytes(file);
        Log.info('Successfully processed PDF with Rust processor');
      } catch (rustError) {
        Log.error('Rust PDF processor failed, trying enhanced processor: $rustError');
        
        // Fallback to enhanced processor
        try {
          content = await EnhancedPdfProcessor.processPdfBytes(bytes);
          Log.info('Successfully processed PDF with enhanced processor');
        } catch (enhancedError) {
          Log.error('Enhanced PDF processor failed, trying visual processor: $enhancedError');
          
          // Fallback to visual processor
          try {
            content = await VisualPdfProcessor.processPdfBytes(bytes);
            Log.info('Successfully processed PDF with visual processor');
          } catch (visualError) {
            Log.error('Visual PDF processor failed, trying advanced processor: $visualError');
            
            // Fallback to advanced processor
            try {
              content = await AdvancedPdfProcessor.processPdfBytes(bytes);
              Log.info('Successfully processed PDF with advanced processor');
            } catch (advancedError) {
              Log.error('Advanced PDF processor also failed, falling back to basic extraction: $advancedError');
              
              // Fallback to basic extraction
              try {
                final PdfDocument document = PdfDocument(inputBytes: bytes);
                final PdfTextExtractor extractor = PdfTextExtractor(document);
                final String rawText = extractor.extractText();
                document.dispose();
                
                content = cleanPdfText(rawText);
              } catch (fallbackError) {
                Log.error('Fallback PDF extraction also failed: $fallbackError');
                content = 'Failed to extract PDF content';
              }
            }
          }
        }
      }
      
      // Add metadata header if we have content and metadata
      if (content.isNotEmpty && content != 'Failed to extract PDF content') {
        final StringBuffer headerBuffer = StringBuffer();
        
        if (metadata.title != null && metadata.title!.isNotEmpty) {
          headerBuffer.writeln('# ${metadata.title}');
          headerBuffer.writeln();
        }
        
        if (metadata.author != null && metadata.author!.isNotEmpty) {
          headerBuffer.writeln('**Author:** ${metadata.author}');
        }
        
        if (metadata.subject != null && metadata.subject!.isNotEmpty) {
          headerBuffer.writeln('**Subject:** ${metadata.subject}');
        }
        
        if (metadata.creationDate != null) {
          headerBuffer.writeln('**Created:** ${metadata.creationDate.toString().split(' ')[0]}');
        }
        
        if (metadata.pageCount > 0) {
          headerBuffer.writeln('**Pages:** ${metadata.pageCount}');
        }
        
        if (headerBuffer.isNotEmpty) {
          headerBuffer.writeln();
          headerBuffer.writeln('---');
          headerBuffer.writeln();
          content = headerBuffer.toString() + content;
        }
      }
      
      return (
        content: content.isEmpty ? 'No text content found in PDF' : content,
        metadata: metadata,
        pdfBytes: bytes, // 返回PDF字节数据用于混合查看器
      );
      
    } catch (e) {
      throw Exception('Failed to extract PDF content: $e');
    }
  }
  
  /// Extract metadata from PDF document
  static PdfMetadata _extractPdfMetadata(PdfDocument document) {
    try {
      final PdfDocumentInformation info = document.documentInformation;
      
      return PdfMetadata(
        title: info.title.isNotEmpty ? info.title : null,
        author: info.author.isNotEmpty ? info.author : null,
        subject: info.subject.isNotEmpty ? info.subject : null,
        creator: info.creator.isNotEmpty ? info.creator : null,
        producer: info.producer.isNotEmpty ? info.producer : null,
        keywords: info.keywords.isNotEmpty ? info.keywords : null,
        creationDate: info.creationDate,
        modificationDate: info.modificationDate,
        pageCount: document.pages.count,
      );
    } catch (e) {
      // Return basic metadata if extraction fails
      return PdfMetadata(
        pageCount: document.pages.count,
      );
    }
  }
  
  /// Clean up extracted PDF text for better readability and structure preservation
  static String cleanPdfText(String text) {
    // First, detect and clean any HTML content that might have been extracted
    String cleaned = _cleanHtmlContent(text);
    
    // Remove excessive whitespace and normalize line breaks
    cleaned = cleaned
        .replaceAll(RegExp(r'\r\n|\r'), '\n') // Normalize line endings
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Normalize spaces
        .trim();
    
    // Split into lines for processing
    final List<String> lines = cleaned.split('\n');
    final List<String> processedLines = [];
    
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      
      if (line.isEmpty) {
        // Preserve empty lines for paragraph breaks, but avoid excessive ones
        if (processedLines.isNotEmpty && 
            processedLines.last.isNotEmpty) {
          processedLines.add('');
        }
        continue;
      }
      
      // Detect and format headers (lines that are short and likely titles)
      if (_isLikelyHeader(line, i, lines)) {
        // Add spacing before headers (except for the first line)
        if (processedLines.isNotEmpty && processedLines.last.isNotEmpty) {
          processedLines.add('');
        }
        
        // Format as markdown header based on content
        final String headerLevel = _determineHeaderLevel(line);
        processedLines.add('$headerLevel $line');
        processedLines.add(''); // Add spacing after headers
        continue;
      }
      
      // Detect numbered lists
      if (_isNumberedListItem(line)) {
        processedLines.add(line);
        continue;
      }
      
      // Detect bullet points or dashes
      if (_isBulletListItem(line)) {
        processedLines.add('- ${line.replaceFirst(RegExp(r'^[•·\-\*]\s*'), '')}');
        continue;
      }
      
      // Regular text line
      processedLines.add(line);
    }
    
    // Post-process to detect and format tables
    final List<String> finalLines = _detectAndFormatTables(processedLines);
    
    // Clean up excessive line breaks
    return finalLines
        .join('\n')
        .replaceAll(RegExp(r'\n{4,}'), '\n\n\n') // Max 3 line breaks
        .trim();
  }
  
  /// Determine if a line is likely a header
  static bool _isLikelyHeader(String line, int index, List<String> allLines) {
    // Headers are typically:
    // 1. Short (less than 100 characters)
    // 2. Don't end with punctuation (except :)
    // 3. May contain numbers or special characters indicating sections
    
    if (line.length > 100) return false;
    
    // Check for section numbering patterns
    if (RegExp(r'^[一二三四五六七八九十\d]+[、\.]\s*').hasMatch(line)) return true;
    if (RegExp(r'^\d+\.\s*').hasMatch(line)) return true;
    
    // Check if line doesn't end with sentence punctuation
    if (!line.endsWith('.') && !line.endsWith('。') && !line.endsWith('，') && !line.endsWith(',')) {
      // Check if next line exists and is different (likely content)
      if (index + 1 < allLines.length) {
        final nextLine = allLines[index + 1].trim();
        if (nextLine.isNotEmpty && nextLine != line) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Determine header level based on content
  static String _determineHeaderLevel(String line) {
    // Primary headers (chapters, main sections)
    if (RegExp(r'^[一二三四五六七八九十]+[、\.]\s*').hasMatch(line)) return '##';
    
    // Secondary headers (numbered subsections)
    if (RegExp(r'^\d+\.\s*').hasMatch(line)) return '###';
    
    // Default to secondary header
    return '###';
  }
  
  /// Check if line is a numbered list item
  static bool _isNumberedListItem(String line) {
    return RegExp(r'^\d+[\.\)]\s+').hasMatch(line);
  }
  
  /// Check if line is a bullet list item
  static bool _isBulletListItem(String line) {
    return RegExp(r'^[•·\-\*]\s+').hasMatch(line);
  }
  
  /// Detect and format tables in the text
  static List<String> _detectAndFormatTables(List<String> lines) {
    final List<String> result = [];
    final List<String> potentialTableLines = [];
    bool inTable = false;
    
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      
      // Detect potential table content (contains multiple spaces or tabs between words)
      if (_isLikelyTableRow(line)) {
        if (!inTable) {
          inTable = true;
          potentialTableLines.clear();
        }
        potentialTableLines.add(line);
      } else {
        // If we were collecting table lines, process them
        if (inTable && potentialTableLines.isNotEmpty) {
          final List<String> tableMarkdown = _convertToMarkdownTable(potentialTableLines);
          result.addAll(tableMarkdown);
          potentialTableLines.clear();
          inTable = false;
        }
        
        // Add the current line
        result.add(line);
      }
    }
    
    // Handle any remaining table lines
    if (inTable && potentialTableLines.isNotEmpty) {
      final List<String> tableMarkdown = _convertToMarkdownTable(potentialTableLines);
      result.addAll(tableMarkdown);
    }
    
    return result;
  }
  
  /// Check if a line looks like a table row
  static bool _isLikelyTableRow(String line) {
    if (line.trim().isEmpty) return false;
    
    // Look for multiple segments separated by significant whitespace
    final List<String> segments = line.split(RegExp(r'\s{3,}'));
    
    // A table row should have at least 2 columns
    if (segments.length >= 2) {
      // Check that segments are not too long (likely not table cells if very long)
      final bool allSegmentsReasonable = segments.every((segment) => 
          segment.trim().isNotEmpty && segment.trim().length < 100);
      
      if (allSegmentsReasonable) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Convert detected table lines to Markdown table format
  static List<String> _convertToMarkdownTable(List<String> tableLines) {
    if (tableLines.isEmpty) return [];
    
    final List<List<String>> rows = [];
    int maxColumns = 0;
    
    // Parse each line into columns
    for (String line in tableLines) {
      final List<String> columns = line
          .split(RegExp(r'\s{3,}'))
          .map((col) => col.trim())
          .where((col) => col.isNotEmpty)
          .toList();
      
      if (columns.isNotEmpty) {
        rows.add(columns);
        maxColumns = math.max(maxColumns, columns.length);
      }
    }
    
    if (rows.isEmpty || maxColumns < 2) return tableLines;
    
    // Normalize all rows to have the same number of columns
    for (List<String> row in rows) {
      while (row.length < maxColumns) {
        row.add('');
      }
    }
    
    // Create Markdown table
    final List<String> markdownTable = [];
    
    // Add empty line before table
    markdownTable.add('');
    
    // Add header row (first row or create generic headers)
    final List<String> headers = rows.isNotEmpty ? rows[0] : 
        List.generate(maxColumns, (index) => '列${index + 1}');
    
    markdownTable.add('| ${headers.join(' | ')} |');
    
    // Add separator row
    markdownTable.add('| ${List.generate(maxColumns, (_) => '---').join(' | ')} |');
    
    // Add data rows (skip first row if it was used as header)
    final int startIndex = rows.isNotEmpty ? 1 : 0;
    for (int i = startIndex; i < rows.length; i++) {
      markdownTable.add('| ${rows[i].join(' | ')} |');
    }
    
    // Add empty line after table
    markdownTable.add('');
    
    return markdownTable;
  }
  
  /// Clean HTML content that might be extracted by PDF libraries
  static String _cleanHtmlContent(String text) {
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
}
