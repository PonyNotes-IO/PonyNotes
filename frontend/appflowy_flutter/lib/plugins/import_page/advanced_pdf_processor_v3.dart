import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'pdf_stream_parser.dart';
import 'pdf_character_decoder.dart';
import 'pdf_content_filter_v2.dart';

/// 高级PDF处理器 v3.0
/// 集成解压缩和字符解码功能
class AdvancedPdfProcessorV3 {
  
  /// 处理PDF文件并提取可读文本
  static Future<Map<String, dynamic>> processPdfFile(String filePath) async {
    try {
      print('🚀 启动高级PDF处理器 v3.0...');
      
      // 读取PDF文件
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF文件不存在: $filePath');
      }
      
      Uint8List bytes = await file.readAsBytes();
      return await processPdfBytes(bytes);
      
    } catch (e) {
      print('❌ PDF文件处理失败: $e');
      return {
        'success': false,
        'error': e.toString(),
        'content': '',
        'stats': {},
      };
    }
  }
  
  /// 处理PDF字节数据
  static Future<Map<String, dynamic>> processPdfBytes(Uint8List bytes) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      print('📊 PDF信息: ${_analyzePdfInfo(bytes)}');
      
      // 1. 解析PDF流对象
      print('🔍 解析PDF流对象...');
      final streams = PdfStreamParser.parseStreams(bytes);
      print('✅ 发现 ${streams.length} 个流对象');
      
      // 2. 提取和解压缩文本内容
      print('📝 提取和解压缩文本内容...');
      
      StringBuffer allContent = StringBuffer();
      List<Map<String, dynamic>> processedStreams = [];
      int successCount = 0;
      
      for (int i = 0; i < streams.length; i++) {
        final stream = streams[i];
        print('🔄 处理流对象 ${stream.objectNumber}...');
        
        try {
          // 使用PdfStream的extractText方法
          String extractedText = stream.extractText();
          
          if (extractedText.isNotEmpty) {
            // 字符解码
            String decodedText = PdfCharacterDecoder.decodeText(extractedText);
            
            if (decodedText.isNotEmpty && _isValidText(decodedText)) {
              allContent.write(decodedText);
              allContent.write('\n');
              successCount++;
              
              processedStreams.add({
                'id': stream.objectNumber,
                'originalLength': stream.rawData.length,
                'extractedLength': extractedText.length,
                'textLength': decodedText.length,
                'filters': stream.filters.join(', '),
                'preview': decodedText.length > 100 
                    ? decodedText.substring(0, 100) + '...'
                    : decodedText,
              });
              
              print('✅ 流对象 ${stream.objectNumber}: 提取了 ${decodedText.length} 字符');
            } else {
              print('⚠️  流对象 ${stream.objectNumber}: 无有效文本内容');
            }
          } else {
            print('⚠️  流对象 ${stream.objectNumber}: 提取失败');
          }
          
        } catch (e) {
          print('❌ 流对象 ${stream.objectNumber} 处理失败: $e');
        }
      }
      
      stopwatch.stop();
      
      final finalContent = allContent.toString();
      
      // 3. 智能内容过滤和清理 v2.0
      print('✨ 执行智能内容过滤 v2.0...');
      final filteredContent = PdfContentFilterV2.extractReadableText(finalContent);
      
      // 4. 分析过滤后的内容质量
      final textAnalysis = PdfContentFilterV2.analyzeContent(filteredContent);
      
      print('📊 过滤前长度: ${finalContent.length}, 过滤后长度: ${filteredContent.length}');
      
      print('📊 成功处理了 $successCount/${streams.length} 个流对象');
      print('✅ 处理完成！');
      print('⏱️  总处理时间: ${stopwatch.elapsedMilliseconds}ms');
      print('📊 内容长度: ${filteredContent.length} 字符');
      print('🎯 质量评分: ${textAnalysis['qualityScore']}/100');
      
      return {
        'success': true,
        'content': filteredContent,
        'rawContent': finalContent, // 保留原始内容用于调试
        'processingTime': stopwatch.elapsedMilliseconds,
        'stats': {
          'totalStreams': streams.length,
          'processedStreams': successCount,
          'contentLength': filteredContent.length,
          'rawContentLength': finalContent.length,
          'qualityScore': textAnalysis['qualityScore'],
        },
        'processedStreams': processedStreams,
        'analysis': textAnalysis,
      };
      
    } catch (e) {
      stopwatch.stop();
      print('❌ PDF处理失败: $e');
      return {
        'success': false,
        'error': e.toString(),
        'content': '',
        'processingTime': stopwatch.elapsedMilliseconds,
        'stats': {},
      };
    }
  }
  
  /// 分析PDF基本信息
  static Map<String, dynamic> _analyzePdfInfo(Uint8List bytes) {
    String header = utf8.decode(bytes.take(20).toList(), allowMalformed: true);
    
    // 提取版本信息
    RegExp versionRegex = RegExp(r'%PDF-(\d+\.\d+)');
    Match? versionMatch = versionRegex.firstMatch(header);
    String version = versionMatch?.group(1) ?? 'unknown';
    
    // 统计对象数量
    String content = utf8.decode(bytes, allowMalformed: true);
    int objectCount = RegExp(r'\d+\s+\d+\s+obj').allMatches(content).length;
    int streamCount = RegExp(r'stream\s').allMatches(content).length;
    
    // 检查是否加密
    bool encrypted = content.contains('/Encrypt');
    
    // 估算页数
    int pageCount = RegExp(r'/Type\s*/Page[^s]').allMatches(content).length;
    if (pageCount == 0) {
      pageCount = RegExp(r'/Count\s*(\d+)').allMatches(content).length;
    }
    
    // 统计字体和图片
    int fontCount = RegExp(r'/Type\s*/Font').allMatches(content).length;
    int imageCount = RegExp(r'/Type\s*/XObject\s*/Subtype\s*/Image').allMatches(content).length;
    
    // 检查压缩类型
    Set<String> compressionTypes = {};
    RegExp filterRegex = RegExp(r'/Filter\s*/(\w+)');
    Iterable<Match> filterMatches = filterRegex.allMatches(content);
    for (Match match in filterMatches) {
      compressionTypes.add(match.group(1)!);
    }
    
    return {
      'version': version,
      'objectCount': objectCount,
      'streamCount': streamCount,
      'pageCount': pageCount,
      'fontCount': fontCount,
      'imageCount': imageCount,
      'encrypted': encrypted,
      'compressionTypes': compressionTypes.toList(),
    };
  }
  
  /// 检查是否为有效文本
  static bool _isValidText(String text) {
    if (text.trim().isEmpty) return false;
    
    // 检查可读字符比例
    int readableChars = 0;
    int totalChars = text.length;
    
    for (int i = 0; i < totalChars; i++) {
      int charCode = text.codeUnitAt(i);
      if ((charCode >= 32 && charCode <= 126) || // ASCII可打印字符
          (charCode >= 128) || // Unicode字符
          charCode == 10 || charCode == 13 || charCode == 9) { // 换行、回车、制表符
        readableChars++;
      }
    }
    
    double readableRatio = readableChars / totalChars;
    return readableRatio > 0.3; // 至少30%的字符是可读的
  }
  
  /// 高级文本清理
  static String _advancedTextCleaning(String text) {
    if (text.isEmpty) return text;
    
    // 1. 移除重复的空白字符
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // 2. 修复断行问题
    text = text.replaceAll(RegExp(r'(\w)-\s+(\w)'), r'$1$2'); // 连字符断行
    text = text.replaceAll(RegExp(r'(\w)\s+(\w)'), r'$1 $2'); // 规范化单词间距
    
    // 3. 清理段落结构
    List<String> lines = text.split('\n');
    List<String> cleanedLines = [];
    
    for (String line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.isNotEmpty) {
        cleanedLines.add(cleanLine);
      } else if (cleanedLines.isNotEmpty && cleanedLines.last.isNotEmpty) {
        cleanedLines.add(''); // 保留段落分隔
      }
    }
    
    // 4. 移除开头和结尾的空行
    while (cleanedLines.isNotEmpty && cleanedLines.first.isEmpty) {
      cleanedLines.removeAt(0);
    }
    while (cleanedLines.isNotEmpty && cleanedLines.last.isEmpty) {
      cleanedLines.removeLast();
    }
    
    // 5. 智能段落合并
    List<String> finalLines = [];
    for (int i = 0; i < cleanedLines.length; i++) {
      String currentLine = cleanedLines[i];
      
      if (currentLine.isEmpty) {
        finalLines.add('');
        continue;
      }
      
      // 检查是否应该与下一行合并
      if (i < cleanedLines.length - 1) {
        String nextLine = cleanedLines[i + 1];
        
        // 如果当前行不以句号结尾，且下一行不是空行，可能需要合并
        if (!currentLine.endsWith('.') && 
            !currentLine.endsWith('!') && 
            !currentLine.endsWith('?') && 
            !currentLine.endsWith(':') &&
            nextLine.isNotEmpty &&
            !_isLikelyNewParagraph(nextLine)) {
          // 合并行
          finalLines.add(currentLine + ' ' + nextLine);
          i++; // 跳过下一行
          continue;
        }
      }
      
      finalLines.add(currentLine);
    }
    
    return finalLines.join('\n').trim();
  }
  
  /// 检查是否像新段落的开始
  static bool _isLikelyNewParagraph(String line) {
    // 检查是否以大写字母开头
    if (line.isNotEmpty && line[0].toUpperCase() == line[0]) {
      return true;
    }
    
    // 检查是否包含常见的段落开始标记
    List<String> paragraphMarkers = [
      'Chapter', '章节', 'Section', '第', '一、', '二、', '三、',
      '1.', '2.', '3.', '•', '-', '*'
    ];
    
    for (String marker in paragraphMarkers) {
      if (line.startsWith(marker)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 分析文本质量
  static Map<String, dynamic> _analyzeTextQuality(String text) {
    if (text.isEmpty) {
      return {
        'qualityScore': 0,
        'qualityLevel': '无内容',
        'readabilityRatio': 0.0,
        'wordCount': 0,
        'sentenceCount': 0,
        'paragraphCount': 0,
      };
    }
    
    // 统计基本信息
    List<String> lines = text.split('\n');
    List<String> nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).toList();
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> sentences = text.split(RegExp(r'[.!?]+'));
    
    // 计算可读性比例
    int readableChars = 0;
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      if ((charCode >= 32 && charCode <= 126) || charCode >= 128 || 
          charCode == 10 || charCode == 13 || charCode == 9) {
        readableChars++;
      }
    }
    double readabilityRatio = readableChars / text.length;
    
    // 计算质量评分
    double score = 0;
    
    // 基础分数（可读性）
    score += readabilityRatio * 40;
    
    // 内容丰富度
    if (words.length > 10) score += 20;
    if (words.length > 100) score += 10;
    if (words.length > 500) score += 10;
    
    // 结构完整性
    if (sentences.length > 1) score += 10;
    if (nonEmptyLines.length > 1) score += 5;
    
    // 段落结构
    int paragraphCount = text.split(RegExp(r'\n\s*\n')).length;
    if (paragraphCount > 1) score += 5;
    
    // 确定质量等级
    String qualityLevel;
    if (score >= 90) {
      qualityLevel = '优秀';
    } else if (score >= 70) {
      qualityLevel = '良好';
    } else if (score >= 50) {
      qualityLevel = '一般';
    } else if (score >= 30) {
      qualityLevel = '较差';
    } else {
      qualityLevel = '很差';
    }
    
    return {
      'qualityScore': score.round(),
      'qualityLevel': qualityLevel,
      'readabilityRatio': readabilityRatio,
      'wordCount': words.where((w) => w.trim().isNotEmpty).length,
      'sentenceCount': sentences.where((s) => s.trim().isNotEmpty).length,
      'paragraphCount': paragraphCount,
      'lineCount': lines.length,
      'nonEmptyLineCount': nonEmptyLines.length,
      'characterStats': _analyzeCharacterStats(text),
    };
  }
  
  /// 分析字符统计
  static Map<String, int> _analyzeCharacterStats(String text) {
    Map<String, int> stats = {
      'total': text.length,
      'chinese': 0,
      'english': 0,
      'numbers': 0,
      'punctuation': 0,
      'whitespace': 0,
      'other': 0,
    };
    
    for (int i = 0; i < text.length; i++) {
      int charCode = text.codeUnitAt(i);
      
      if (charCode >= 0x4E00 && charCode <= 0x9FFF) {
        stats['chinese'] = stats['chinese']! + 1;
      } else if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        stats['english'] = stats['english']! + 1;
      } else if (charCode >= 48 && charCode <= 57) {
        stats['numbers'] = stats['numbers']! + 1;
      } else if ((charCode >= 33 && charCode <= 47) || 
                 (charCode >= 58 && charCode <= 64) ||
                 (charCode >= 91 && charCode <= 96) ||
                 (charCode >= 123 && charCode <= 126)) {
        stats['punctuation'] = stats['punctuation']! + 1;
      } else if (charCode == 32 || charCode == 9 || charCode == 10 || charCode == 13) {
        stats['whitespace'] = stats['whitespace']! + 1;
      } else {
        stats['other'] = stats['other']! + 1;
      }
    }
    
    return stats;
  }
}
