import 'dart:typed_data';
import 'dart:math' as math;
import 'pdf_stream_parser.dart';

/// 高级PDF处理器 - 支持解压缩和智能文本提取
class AdvancedPdfProcessor {
  static const String processorName = '高级PDF处理器';
  static const String version = '2.0';
  
  /// 处理PDF字节数据并提取文本
  static Future<String> processPdfBytes(Uint8List pdfBytes) async {
    final result = await processPdf(pdfBytes);
    return result.extractedText;
  }
  
  /// 处理PDF文件并提取文本
  static Future<PdfProcessingResult> processPdf(Uint8List pdfData) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('🚀 启动$processorName v$version...');
      
      // 1. 验证PDF文件
      if (!_isValidPdf(pdfData)) {
        throw Exception('无效的PDF文件');
      }
      
      // 2. 解析PDF结构
      final pdfInfo = _analyzePdfStructure(pdfData);
      print('📊 PDF信息: $pdfInfo');
      
      // 3. 解析流对象
      print('🔍 解析PDF流对象...');
      final streams = PdfStreamParser.parseStreams(pdfData);
      print('✅ 发现 ${streams.length} 个流对象');
      
      // 4. 提取文本内容
      print('📝 提取文本内容...');
      final textContent = await _extractTextFromStreams(streams);
      
      // 5. 后处理和格式化
      final formattedText = _formatExtractedText(textContent);
      
      stopwatch.stop();
      
      // 6. 生成结果
      final result = PdfProcessingResult(
        success: true,
        processorName: processorName,
        processingTime: stopwatch.elapsedMilliseconds,
        extractedText: formattedText,
        pdfInfo: pdfInfo,
        streamCount: streams.length,
        textStreams: PdfStreamParser.findTextStreams(streams).length,
        qualityScore: _calculateQualityScore(formattedText),
      );
      
      print('✅ 处理完成！');
      print('⏱️  总处理时间: ${result.processingTime}ms');
      print('📊 输出内容长度: ${result.extractedText.length} 字符');
      
      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ 处理失败: $e');
      
      return PdfProcessingResult(
        success: false,
        processorName: processorName,
        processingTime: stopwatch.elapsedMilliseconds,
        extractedText: '',
        errorMessage: e.toString(),
      );
    }
  }
  
  /// 验证PDF文件格式
  static bool _isValidPdf(Uint8List data) {
    if (data.length < 8) return false;
    final header = String.fromCharCodes(data.take(8));
    return header.startsWith('%PDF-');
  }
  
  /// 分析PDF结构
  static Map<String, dynamic> _analyzePdfStructure(Uint8List data) {
    final content = String.fromCharCodes(data);
    
    // 提取版本信息
    final versionMatch = RegExp(r'%PDF-(\d+\.\d+)').firstMatch(content);
    final version = versionMatch?.group(1) ?? '未知';
    
    // 统计对象数量
    final objectCount = RegExp(r'\d+\s+\d+\s+obj').allMatches(content).length;
    
    // 统计流对象数量
    final streamCount = RegExp(r'stream\s*\n').allMatches(content).length;
    
    // 检测页面数量
    final pagePattern = RegExp(r'/Type\s*/Page[^s]');
    final pageCount = pagePattern.allMatches(content).length;
    
    // 检测字体数量
    final fontPattern = RegExp(r'/Type\s*/Font');
    final fontCount = fontPattern.allMatches(content).length;
    
    // 检测图像数量
    final imagePattern = RegExp(r'/Type\s*/XObject\s*/Subtype\s*/Image');
    final imageCount = imagePattern.allMatches(content).length;
    
    // 检测是否加密
    final isEncrypted = content.contains('/Encrypt');
    
    // 检测压缩类型
    final compressionTypes = <String>{};
    final filterMatches = RegExp(r'/Filter\s*/(\w+)').allMatches(content);
    for (final match in filterMatches) {
      compressionTypes.add(match.group(1)!);
    }
    
    return {
      'version': version,
      'objectCount': objectCount,
      'streamCount': streamCount,
      'pageCount': pageCount,
      'fontCount': fontCount,
      'imageCount': imageCount,
      'encrypted': isEncrypted,
      'compressionTypes': compressionTypes.toList(),
    };
  }
  
  /// 从流对象中提取文本
  static Future<String> _extractTextFromStreams(List<PdfStream> streams) async {
    final textParts = <String>[];
    int processedCount = 0;
    
    for (final stream in streams) {
      try {
        print('🔄 处理流对象 ${stream.objectNumber}...');
        
        // 提取文本
        final text = stream.extractText();
        
        if (text.isNotEmpty && _isReadableText(text)) {
          textParts.add(text);
          processedCount++;
          print('✅ 流对象 ${stream.objectNumber}: 提取了 ${text.length} 字符');
        } else {
          print('⚠️  流对象 ${stream.objectNumber}: 无有效文本内容');
        }
        
        // 每处理10个对象暂停一下，避免阻塞UI
        if (processedCount % 10 == 0) {
          await Future.delayed(Duration(milliseconds: 1));
        }
      } catch (e) {
        print('❌ 处理流对象 ${stream.objectNumber} 失败: $e');
      }
    }
    
    print('📊 成功处理了 $processedCount/${streams.length} 个流对象');
    return textParts.join('\n\n');
  }
  
  /// 检查文本是否可读
  static bool _isReadableText(String text) {
    if (text.length < 3) return false;
    
    // 统计可读字符
    int readableCount = 0;
    int totalCount = text.length;
    
    for (final char in text.codeUnits) {
      if ((char >= 32 && char <= 126) || // ASCII可打印字符
          (char >= 0x4e00 && char <= 0x9fff) || // 中文字符
          (char >= 0x3040 && char <= 0x309f) || // 日文平假名
          (char >= 0x30a0 && char <= 0x30ff) || // 日文片假名
          (char >= 0xac00 && char <= 0xd7af) || // 韩文
          char == 9 || char == 10 || char == 13) { // 制表符、换行符
        readableCount++;
      }
    }
    
    // 至少70%的字符是可读的
    return readableCount > totalCount * 0.7;
  }
  
  /// 格式化提取的文本
  static String _formatExtractedText(String rawText) {
    if (rawText.isEmpty) return '';
    
    String formatted = rawText;
    
    // 1. 清理多余的空白字符
    formatted = formatted.replaceAll(RegExp(r'\s+'), ' ');
    
    // 2. 恢复段落结构
    formatted = formatted.replaceAll(RegExp(r'\.(\s+[A-Z])'), '.\n\n\$1');
    
    // 3. 处理列表项
    formatted = formatted.replaceAll(RegExp(r'(\d+\.)(\s*[A-Z])'), '\n\$1\$2');
    formatted = formatted.replaceAll(RegExp(r'([•·▪▫])(\s*[A-Za-z])'), '\n\$1\$2');
    
    // 4. 处理标题（全大写的短行）
    final lines = formatted.split('\n');
    final processedLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // 检查是否可能是标题
      if (line.length < 80 && 
          line.toUpperCase() == line && 
          line.split(' ').length <= 10 &&
          RegExp(r'^[A-Z\s\d.,;:!?()-]+$').hasMatch(line)) {
        processedLines.add('\n## $line\n');
      } else {
        processedLines.add(line);
      }
    }
    
    formatted = processedLines.join(' ');
    
    // 5. 最终清理
    formatted = formatted
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n') // 移除多余空行
        .replaceAll(RegExp(r'^\s+|\s+$'), '') // 移除首尾空白
        .trim();
    
    return formatted;
  }
  
  /// 计算文本质量评分
  static double _calculateQualityScore(String text) {
    if (text.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // 1. 基础可读性 (40分)
    final readableChars = text.codeUnits.where((c) => 
      (c >= 32 && c <= 126) || 
      (c >= 0x4e00 && c <= 0x9fff) ||
      c == 9 || c == 10 || c == 13
    ).length;
    score += (readableChars / text.length) * 40;
    
    // 2. 内容丰富度 (30分)
    final words = text.split(RegExp(r'\s+')).where((w) => w.length > 2).length;
    score += math.min(words / 100.0, 1.0) * 30;
    
    // 3. 结构完整性 (20分)
    final sentences = text.split(RegExp(r'[.!?。！？]')).where((s) => s.trim().length > 10).length;
    score += math.min(sentences / 20.0, 1.0) * 20;
    
    // 4. 多语言支持 (10分)
    final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
    final hasNumbers = RegExp(r'\d').hasMatch(text);
    
    if (hasEnglish) score += 3;
    if (hasChinese) score += 4;
    if (hasNumbers) score += 3;
    
    return math.min(score, 100.0);
  }
}

/// PDF处理结果
class PdfProcessingResult {
  final bool success;
  final String processorName;
  final int processingTime;
  final String extractedText;
  final Map<String, dynamic>? pdfInfo;
  final int? streamCount;
  final int? textStreams;
  final double? qualityScore;
  final String? errorMessage;
  
  PdfProcessingResult({
    required this.success,
    required this.processorName,
    required this.processingTime,
    required this.extractedText,
    this.pdfInfo,
    this.streamCount,
    this.textStreams,
    this.qualityScore,
    this.errorMessage,
  });
  
  /// 获取质量等级描述
  String get qualityDescription {
    if (qualityScore == null) return '未知';
    
    if (qualityScore! >= 90) return '优秀';
    if (qualityScore! >= 75) return '良好';
    if (qualityScore! >= 60) return '中等';
    if (qualityScore! >= 40) return '较差';
    return '很差';
  }
  
  /// 生成详细报告
  String generateReport() {
    final buffer = StringBuffer();
    
    buffer.writeln('# PDF内容提取结果');
    buffer.writeln('');
    buffer.writeln('**提取方法**: $processorName');
    buffer.writeln('**提取时间**: ${DateTime.now()}');
    buffer.writeln('**处理耗时**: ${processingTime}ms');
    buffer.writeln('**内容长度**: ${extractedText.length} 字符');
    
    if (success && qualityScore != null) {
      buffer.writeln('**质量评分**: ${qualityScore!.toStringAsFixed(1)}/100 ($qualityDescription)');
    }
    
    if (pdfInfo != null) {
      buffer.writeln('');
      buffer.writeln('## PDF文档信息');
      buffer.writeln('');
      pdfInfo!.forEach((key, value) {
        buffer.writeln('- **$key**: $value');
      });
    }
    
    if (streamCount != null && textStreams != null) {
      buffer.writeln('');
      buffer.writeln('## 处理统计');
      buffer.writeln('');
      buffer.writeln('- **总流对象**: $streamCount');
      buffer.writeln('- **文本流对象**: $textStreams');
      buffer.writeln('- **文本提取率**: ${((textStreams! / streamCount!) * 100).toStringAsFixed(1)}%');
    }
    
    if (!success && errorMessage != null) {
      buffer.writeln('');
      buffer.writeln('## 错误信息');
      buffer.writeln('');
      buffer.writeln('```');
      buffer.writeln(errorMessage);
      buffer.writeln('```');
    }
    
    if (success && extractedText.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
      buffer.writeln('## 提取的文本内容');
      buffer.writeln('');
      buffer.writeln(extractedText);
    }
    
    return buffer.toString();
  }
}