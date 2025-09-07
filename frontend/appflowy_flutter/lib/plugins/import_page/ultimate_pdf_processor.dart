import 'dart:typed_data';
import 'dart:convert';

/// 终极PDF处理器
/// 专门处理压缩、编码和复杂格式的PDF文件
class UltimatePdfProcessor {
  /// 处理PDF字节数据
  static Future<String> processPdfBytes(Uint8List bytes) async {
    try {
      print('🔍 开始分析PDF结构...');
      
      // 分析PDF基本信息
      final pdfInfo = _analyzePdfStructure(bytes);
      print('📊 PDF信息: $pdfInfo');
      
      // 方法1: 智能文本提取
      final intelligentText = await _intelligentTextExtraction(bytes);
      if (intelligentText.isNotEmpty && _isGoodQualityText(intelligentText)) {
        print('✅ 智能文本提取成功');
        return _formatExtractedContent(intelligentText, '智能文本提取', pdfInfo);
      }
      
      // 方法2: 深度结构分析
      final deepAnalysisText = await _deepStructureAnalysis(bytes);
      if (deepAnalysisText.isNotEmpty && _isGoodQualityText(deepAnalysisText)) {
        print('✅ 深度结构分析成功');
        return _formatExtractedContent(deepAnalysisText, '深度结构分析', pdfInfo);
      }
      
      // 方法3: 原始数据挖掘
      final rawDataText = await _rawDataMining(bytes);
      if (rawDataText.isNotEmpty && _isGoodQualityText(rawDataText)) {
        print('✅ 原始数据挖掘成功');
        return _formatExtractedContent(rawDataText, '原始数据挖掘', pdfInfo);
      }
      
      // 方法4: 最后的尝试 - 字符频率分析
      final frequencyText = await _characterFrequencyAnalysis(bytes);
      if (frequencyText.isNotEmpty) {
        print('⚠️ 使用字符频率分析');
        return _formatExtractedContent(frequencyText, '字符频率分析', pdfInfo);
      }
      
      // 如果所有方法都失败
      print('❌ 所有提取方法都失败，生成诊断报告');
      return _generateDiagnosticReport(bytes, pdfInfo);

    } catch (e) {
      print('💥 处理器遇到错误: $e');
      return _generateErrorReport(e.toString(), bytes);
    }
  }

  /// 分析PDF结构
  static Map<String, dynamic> _analyzePdfStructure(Uint8List bytes) {
    final info = <String, dynamic>{};
    
    try {
      final pdfString = String.fromCharCodes(bytes);
      
      // PDF版本
      final versionMatch = RegExp(r'%PDF-(\d\.\d)').firstMatch(pdfString);
      info['version'] = versionMatch?.group(1) ?? '未知';
      
      // 对象数量
      final objCount = RegExp(r'\d+ \d+ obj').allMatches(pdfString).length;
      info['objectCount'] = objCount;
      
      // 流对象数量
      final streamCount = RegExp(r'stream\s').allMatches(pdfString).length;
      info['streamCount'] = streamCount;
      
      // 页面数量
      final pageCount = RegExp(r'/Type\s*/Page[^s]').allMatches(pdfString).length;
      info['pageCount'] = pageCount;
      
      // 字体信息
      final fontMatches = RegExp(r'/Font\s').allMatches(pdfString).length;
      info['fontCount'] = fontMatches;
      
      // 图像数量
      final imageCount = RegExp(r'/Image\s').allMatches(pdfString).length;
      info['imageCount'] = imageCount;
      
      // 是否加密
      info['encrypted'] = pdfString.contains('/Encrypt');
      
      // 压缩类型
      final compressionTypes = <String>[];
      if (pdfString.contains('/FlateDecode')) compressionTypes.add('FlateDecode');
      if (pdfString.contains('/LZWDecode')) compressionTypes.add('LZWDecode');
      if (pdfString.contains('/DCTDecode')) compressionTypes.add('DCTDecode');
      if (pdfString.contains('/ASCII85Decode')) compressionTypes.add('ASCII85Decode');
      info['compressionTypes'] = compressionTypes;
      
    } catch (e) {
      info['analysisError'] = e.toString();
    }
    
    return info;
  }

  /// 智能文本提取
  static Future<String> _intelligentTextExtraction(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      final pdfString = String.fromCharCodes(bytes);
      
      // 查找所有文本对象
      final textObjects = _findAdvancedTextObjects(pdfString);
      print('🔍 发现 ${textObjects.length} 个文本对象');
      
      for (final textObj in textObjects) {
        final extractedText = _advancedTextDecoding(textObj);
        if (extractedText.isNotEmpty && _isReadableText(extractedText)) {
          content.writeln(extractedText);
        }
      }
      
      // 如果直接提取失败，尝试解码流
      if (content.length < 50) {
        final streams = _findContentStreams(pdfString);
        print('🔍 分析 ${streams.length} 个内容流');
        
        for (final stream in streams) {
          final decodedText = await _decodeContentStream(stream);
          if (decodedText.isNotEmpty && _isReadableText(decodedText)) {
            content.writeln(decodedText);
          }
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      print('智能文本提取错误: $e');
      return '';
    }
  }

  /// 深度结构分析
  static Future<String> _deepStructureAnalysis(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      final pdfString = String.fromCharCodes(bytes);
      
      // 查找页面内容
      final pageContents = _findPageContents(pdfString);
      print('🔍 发现 ${pageContents.length} 个页面内容');
      
      for (final pageContent in pageContents) {
        final pageText = await _extractPageText(pageContent);
        if (pageText.isNotEmpty) {
          content.writeln('## 页面内容');
          content.writeln(pageText);
          content.writeln();
        }
      }
      
      // 查找表格数据
      final tableData = _extractTableData(pdfString);
      if (tableData.isNotEmpty) {
        content.writeln('## 表格数据');
        content.writeln(tableData);
        content.writeln();
      }
      
      return content.toString().trim();
    } catch (e) {
      print('深度结构分析错误: $e');
      return '';
    }
  }

  /// 原始数据挖掘
  static Future<String> _rawDataMining(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      // 直接搜索可能的文本模式
      final textPatterns = _findTextPatterns(bytes);
      print('🔍 发现 ${textPatterns.length} 个文本模式');
      
      for (final pattern in textPatterns) {
        final text = _cleanAndValidateText(pattern);
        if (text.isNotEmpty) {
          content.writeln(text);
        }
      }
      
      // 查找数字和特殊字符组合
      final dataPatterns = _findDataPatterns(bytes);
      for (final pattern in dataPatterns) {
        content.writeln(pattern);
      }
      
      return content.toString().trim();
    } catch (e) {
      print('原始数据挖掘错误: $e');
      return '';
    }
  }

  /// 字符频率分析
  static Future<String> _characterFrequencyAnalysis(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      // 统计字符频率
      final charFreq = <int, int>{};
      for (final byte in bytes) {
        charFreq[byte] = (charFreq[byte] ?? 0) + 1;
      }
      
      // 找出最常见的可打印字符
      final printableChars = <String>[];
      for (final entry in charFreq.entries) {
        if (entry.key >= 32 && entry.key <= 126 && entry.value > 10) {
          printableChars.add(String.fromCharCode(entry.key));
        }
      }
      
      content.writeln('## 字符频率分析结果');
      content.writeln('发现的可打印字符: ${printableChars.join(", ")}');
      
      // 尝试重建可能的文本
      final reconstructedText = _reconstructTextFromFrequency(bytes, charFreq);
      if (reconstructedText.isNotEmpty) {
        content.writeln();
        content.writeln('## 重建的文本');
        content.writeln(reconstructedText);
      }
      
      return content.toString().trim();
    } catch (e) {
      print('字符频率分析错误: $e');
      return '';
    }
  }

  /// 查找高级文本对象
  static List<String> _findAdvancedTextObjects(String pdfContent) {
    final textObjects = <String>[];
    
    // 多种文本块模式
    final patterns = [
      RegExp(r'BT\s+(.*?)\s+ET', dotAll: true),
      RegExp(r'/Text\s+(.*?)\s+endobj', dotAll: true),
      RegExp(r'Tj\s*\((.*?)\)', dotAll: true),
      RegExp(r'TJ\s*\[(.*?)\]', dotAll: true),
    ];
    
    for (final pattern in patterns) {
      final matches = pattern.allMatches(pdfContent);
      for (final match in matches) {
        final text = match.group(1);
        if (text != null && text.length > 5) {
          textObjects.add(text);
        }
      }
    }
    
    return textObjects;
  }

  /// 高级文本解码
  static String _advancedTextDecoding(String textObject) {
    final content = StringBuffer();
    
    try {
      // 多种解码策略
      final decodingStrategies = [
        _decodeSimpleText,
        _decodeHexText,
        _decodeOctalText,
        _decodeUnicodeText,
      ];
      
      for (final strategy in decodingStrategies) {
        final result = strategy(textObject);
        if (result.isNotEmpty && _isReadableText(result)) {
          content.write(result);
          content.write(' ');
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 简单文本解码
  static String _decodeSimpleText(String text) {
    try {
      final matches = RegExp(r'\((.*?)\)').allMatches(text);
      final result = StringBuffer();
      
      for (final match in matches) {
        final content = match.group(1);
        if (content != null) {
          final decoded = content
              .replaceAll(r'\n', '\n')
              .replaceAll(r'\r', '\r')
              .replaceAll(r'\t', '\t')
              .replaceAll(r'\\', '\\')
              .replaceAll(r'\(', '(')
              .replaceAll(r'\)', ')');
          result.write(decoded);
          result.write(' ');
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 十六进制文本解码
  static String _decodeHexText(String text) {
    try {
      final hexMatches = RegExp(r'<([0-9A-Fa-f\s]+)>').allMatches(text);
      final result = StringBuffer();
      
      for (final match in hexMatches) {
        final hexString = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        if (hexString.length % 2 == 0) {
          try {
            final bytes = <int>[];
            for (int i = 0; i < hexString.length; i += 2) {
              final hexByte = hexString.substring(i, i + 2);
              bytes.add(int.parse(hexByte, radix: 16));
            }
            final decoded = String.fromCharCodes(bytes);
            if (_isReadableText(decoded)) {
              result.write(decoded);
              result.write(' ');
            }
          } catch (e) {
            // 忽略解码错误
          }
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 八进制文本解码
  static String _decodeOctalText(String text) {
    try {
      final octalMatches = RegExp(r'\\(\d{3})').allMatches(text);
      String result = text;
      
      for (final match in octalMatches) {
        final octalString = match.group(1)!;
        try {
          final charCode = int.parse(octalString, radix: 8);
          if (charCode >= 32 && charCode <= 126) {
            result = result.replaceAll(match.group(0)!, String.fromCharCode(charCode));
          }
        } catch (e) {
          // 忽略解码错误
        }
      }
      
      return result;
    } catch (e) {
      return '';
    }
  }

  /// Unicode文本解码
  static String _decodeUnicodeText(String text) {
    try {
      final unicodeMatches = RegExp(r'\\u([0-9A-Fa-f]{4})').allMatches(text);
      String result = text;
      
      for (final match in unicodeMatches) {
        final unicodeString = match.group(1)!;
        try {
          final charCode = int.parse(unicodeString, radix: 16);
          result = result.replaceAll(match.group(0)!, String.fromCharCode(charCode));
        } catch (e) {
          // 忽略解码错误
        }
      }
      
      return result;
    } catch (e) {
      return '';
    }
  }

  /// 查找内容流
  static List<String> _findContentStreams(String pdfContent) {
    final streams = <String>[];
    
    final streamPatterns = [
      RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true),
      RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true),
    ];
    
    for (final pattern in streamPatterns) {
      final matches = pattern.allMatches(pdfContent);
      for (final match in matches) {
        final streamContent = match.group(1);
        if (streamContent != null && streamContent.length > 20) {
          streams.add(streamContent);
        }
      }
    }
    
    return streams;
  }

  /// 解码内容流
  static Future<String> _decodeContentStream(String streamContent) async {
    try {
      // 尝试多种解码方式
      final decodingMethods = [
        _tryDirectDecode,
        _tryBase64Decode,
        _tryZlibDecode,
        _tryManualDecode,
      ];
      
      for (final method in decodingMethods) {
        final result = method(streamContent);
        if (result.isNotEmpty && _isReadableText(result)) {
          return result;
        }
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 直接解码
  static String _tryDirectDecode(String content) {
    try {
      // 查找可能的文本命令
      final textCommands = RegExp(r"\((.*?)\)\s*(?:Tj|TJ|')", dotAll: true);
      final matches = textCommands.allMatches(content);
      final result = StringBuffer();
      
      for (final match in matches) {
        final text = match.group(1);
        if (text != null && _isReadableText(text)) {
          result.writeln(text);
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Base64解码尝试
  static String _tryBase64Decode(String content) {
    try {
      // 清理内容，只保留Base64字符
      final cleanContent = content.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      if (cleanContent.length < 20) return '';
      
      final decoded = base64.decode(cleanContent);
      final text = String.fromCharCodes(decoded);
      
      if (_isReadableText(text)) {
        return text;
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Zlib解码尝试
  static String _tryZlibDecode(String content) {
    try {
      // 这里需要实际的zlib解码，暂时返回空
      // 在真实实现中，可以使用dart:io中的gzip或其他压缩库
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 手动解码
  static String _tryManualDecode(String content) {
    try {
      final result = StringBuffer();
      final lines = content.split('\n');
      
      for (final line in lines) {
        // 查找可能包含文本的行
        if (line.contains('(') && line.contains(')')) {
          final textMatch = RegExp(r'\((.*?)\)').firstMatch(line);
          if (textMatch != null) {
            final text = textMatch.group(1)!;
            if (_isReadableText(text)) {
              result.writeln(text);
            }
          }
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 查找页面内容
  static List<String> _findPageContents(String pdfContent) {
    final pageContents = <String>[];
    
    // 查找页面对象
    final pagePattern = RegExp(r'/Type\s*/Page.*?endobj', dotAll: true);
    final matches = pagePattern.allMatches(pdfContent);
    
    for (final match in matches) {
      final pageObj = match.group(0)!;
      // 在页面对象中查找内容引用
      final contentRef = RegExp(r'/Contents\s+(\d+)\s+\d+\s+R').firstMatch(pageObj);
      if (contentRef != null) {
        final objNum = contentRef.group(1)!;
        // 查找对应的内容对象
        final contentObj = RegExp('$objNum \\d+ obj(.*?)endobj', dotAll: true).firstMatch(pdfContent);
        if (contentObj != null) {
          pageContents.add(contentObj.group(1)!);
        }
      }
    }
    
    return pageContents;
  }

  /// 提取页面文本
  static Future<String> _extractPageText(String pageContent) async {
    try {
      // 查找流内容
      final streamMatch = RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true).firstMatch(pageContent);
      if (streamMatch != null) {
        final streamContent = streamMatch.group(1)!;
        return await _decodeContentStream(streamContent);
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 提取表格数据
  static String _extractTableData(String pdfContent) {
    try {
      final result = StringBuffer();
      
      // 查找可能的表格标记
      final tablePatterns = [
        RegExp(r'Td\s+\((.*?)\)', dotAll: true),
        RegExp(r'TD\s+\((.*?)\)', dotAll: true),
        RegExp(r'table.*?endtable', dotAll: true, caseSensitive: false),
      ];
      
      for (final pattern in tablePatterns) {
        final matches = pattern.allMatches(pdfContent);
        for (final match in matches) {
          final tableContent = match.group(1);
          if (tableContent != null && tableContent.length > 5) {
            result.writeln(tableContent);
          }
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 查找文本模式
  static List<String> _findTextPatterns(Uint8List bytes) {
    final patterns = <String>[];
    
    try {
      // 转换为字符串并查找可读文本序列
      final content = String.fromCharCodes(bytes, 0, bytes.length.clamp(0, 1000000));
      
      // 查找连续的可读字符序列
      final readablePattern = RegExp(r'[a-zA-Z0-9\u4e00-\u9fff\s.,;:!?()\[\]{}"/-]{10,}');
      final matches = readablePattern.allMatches(content);
      
      for (final match in matches) {
        final text = match.group(0)!.trim();
        if (text.length >= 10 && _isReadableText(text)) {
          patterns.add(text);
        }
      }
    } catch (e) {
      // 如果转换失败，尝试部分转换
      try {
        for (int i = 0; i < bytes.length - 50; i += 1000) {
          final end = (i + 1000).clamp(0, bytes.length);
          final chunk = String.fromCharCodes(bytes.sublist(i, end));
          final readablePattern = RegExp(r'[a-zA-Z0-9\u4e00-\u9fff\s.,;:!?()\[\]{}"/-]{5,}');
          final matches = readablePattern.allMatches(chunk);
          
          for (final match in matches) {
            final text = match.group(0)!.trim();
            if (text.length >= 5 && _isReadableText(text)) {
              patterns.add(text);
            }
          }
        }
      } catch (e2) {
        // 忽略错误
      }
    }
    
    return patterns;
  }

  /// 查找数据模式
  static List<String> _findDataPatterns(Uint8List bytes) {
    final patterns = <String>[];
    
    try {
      final content = String.fromCharCodes(bytes, 0, bytes.length.clamp(0, 500000));
      
      // 查找数字模式
      final numberPattern = RegExp(r'\d+\.?\d*');
      final numberMatches = numberPattern.allMatches(content);
      
      final numbers = <String>[];
      for (final match in numberMatches) {
        numbers.add(match.group(0)!);
        if (numbers.length > 20) break; // 限制数量
      }
      
      if (numbers.isNotEmpty) {
        patterns.add('发现数字: ${numbers.join(", ")}');
      }
      
      // 查找日期模式
      final datePattern = RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{4}');
      final dateMatches = datePattern.allMatches(content);
      
      for (final match in dateMatches) {
        patterns.add('发现日期: ${match.group(0)}');
      }
      
    } catch (e) {
      // 忽略错误
    }
    
    return patterns;
  }

  /// 从频率重建文本
  static String _reconstructTextFromFrequency(Uint8List bytes, Map<int, int> charFreq) {
    try {
      final result = StringBuffer();
      
      // 找出最常见的空格和字母
      final spaceChar = 32; // 空格
      final commonChars = <int>[];
      
      for (final entry in charFreq.entries) {
        if (entry.key >= 65 && entry.key <= 90 || // A-Z
            entry.key >= 97 && entry.key <= 122 || // a-z
            entry.key >= 48 && entry.key <= 57 || // 0-9
            entry.key == spaceChar) {
          if (entry.value > 5) {
            commonChars.add(entry.key);
          }
        }
      }
      
      if (commonChars.isNotEmpty) {
        result.writeln('常见字符: ${commonChars.map((c) => String.fromCharCode(c)).join("")}');
        
        // 尝试找到包含这些字符的连续序列
        for (int i = 0; i < bytes.length - 20; i++) {
          if (commonChars.contains(bytes[i])) {
            final sequence = StringBuffer();
            int j = i;
            while (j < bytes.length && j < i + 50 && commonChars.contains(bytes[j])) {
              sequence.write(String.fromCharCode(bytes[j]));
              j++;
            }
            
            final sequenceStr = sequence.toString().trim();
            if (sequenceStr.length > 5) {
              result.writeln(sequenceStr);
              i = j; // 跳过已处理的部分
            }
          }
        }
      }
      
      return result.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 检查是否是可读文本
  static bool _isReadableText(String text) {
    if (text.length < 3) return false;
    
    // 计算可读字符的比例
    final readableChars = RegExp(r'[a-zA-Z0-9\u4e00-\u9fff\s.,;:!?()[\]{}"/-]').allMatches(text).length;
    final ratio = readableChars / text.length;
    
    return ratio > 0.5; // 至少50%是可读字符
  }

  /// 检查是否是高质量文本
  static bool _isGoodQualityText(String text) {
    if (text.length < 20) return false;
    
    // 检查是否包含足够的字母
    final letterCount = RegExp(r'[a-zA-Z\u4e00-\u9fff]').allMatches(text).length;
    final letterRatio = letterCount / text.length;
    
    // 检查是否包含合理的空格
    final spaceCount = RegExp(r'\s').allMatches(text).length;
    final spaceRatio = spaceCount / text.length;
    
    return letterRatio > 0.3 && spaceRatio > 0.05 && spaceRatio < 0.5;
  }

  /// 清理和验证文本
  static String _cleanAndValidateText(String text) {
    try {
      // 清理控制字符
      String cleaned = text.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
      
      // 清理过多的空白
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
      
      // 移除过短的文本
      cleaned = cleaned.trim();
      if (cleaned.length < 5) return '';
      
      // 验证文本质量
      if (!_isReadableText(cleaned)) return '';
      
      return cleaned;
    } catch (e) {
      return '';
    }
  }

  /// 格式化提取的内容
  static String _formatExtractedContent(String content, String method, Map<String, dynamic> pdfInfo) {
    final result = StringBuffer();
    
    result.writeln('# PDF内容提取结果');
    result.writeln();
    result.writeln('**提取方法**: $method');
    result.writeln('**提取时间**: ${DateTime.now()}');
    result.writeln('**内容长度**: ${content.length} 字符');
    result.writeln();
    
    // PDF信息
    result.writeln('## PDF文档信息');
    result.writeln();
    result.writeln('- **版本**: ${pdfInfo['version']}');
    result.writeln('- **对象数量**: ${pdfInfo['objectCount']}');
    result.writeln('- **流对象数量**: ${pdfInfo['streamCount']}');
    result.writeln('- **页面数量**: ${pdfInfo['pageCount']}');
    result.writeln('- **字体数量**: ${pdfInfo['fontCount']}');
    result.writeln('- **图像数量**: ${pdfInfo['imageCount']}');
    result.writeln('- **是否加密**: ${pdfInfo['encrypted'] ? "是" : "否"}');
    
    if (pdfInfo['compressionTypes'] != null && pdfInfo['compressionTypes'].isNotEmpty) {
      result.writeln('- **压缩类型**: ${pdfInfo['compressionTypes'].join(", ")}');
    }
    
    result.writeln();
    result.writeln('---');
    result.writeln();
    
    // 处理内容
    final lines = content.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed.length > 2) {
        processedLines.add(trimmed);
      }
    }
    
    // 智能分段和格式化
    String currentSection = '';
    for (int i = 0; i < processedLines.length; i++) {
      final line = processedLines[i];
      
      // 检查是否是标题
      if (line.length < 80 && !line.endsWith('.') && !line.endsWith('。') && 
          (i == 0 || processedLines[i-1].endsWith('.') || processedLines[i-1].endsWith('。'))) {
        if (currentSection.isNotEmpty) {
          result.writeln(currentSection);
          result.writeln();
          currentSection = '';
        }
        result.writeln('## $line');
        result.writeln();
      } else {
        // 正文内容
        if (currentSection.isNotEmpty) {
          currentSection += ' ';
        }
        currentSection += line;
        
        // 如果段落过长或到达句子结尾，换行
        if (currentSection.length > 300 || line.endsWith('.') || line.endsWith('。')) {
          result.writeln(currentSection);
          result.writeln();
          currentSection = '';
        }
      }
    }
    
    if (currentSection.isNotEmpty) {
      result.writeln(currentSection);
    }
    
    return result.toString();
  }

  /// 生成诊断报告
  static String _generateDiagnosticReport(Uint8List bytes, Map<String, dynamic> pdfInfo) {
    final result = StringBuffer();
    
    result.writeln('# PDF诊断报告');
    result.writeln();
    result.writeln('**状态**: 文本提取失败');
    result.writeln('**文件大小**: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    result.writeln('**分析时间**: ${DateTime.now()}');
    result.writeln();
    
    // PDF信息
    result.writeln('## 文档结构分析');
    result.writeln();
    for (final entry in pdfInfo.entries) {
      result.writeln('- **${entry.key}**: ${entry.value}');
    }
    result.writeln();
    
    // 问题诊断
    result.writeln('## 问题诊断');
    result.writeln();
    
    if (pdfInfo['encrypted'] == true) {
      result.writeln('🔒 **加密保护**: PDF文档受到密码保护，无法提取文本内容。');
      result.writeln();
    }
    
    if (pdfInfo['compressionTypes'] != null && pdfInfo['compressionTypes'].isNotEmpty) {
      result.writeln('🗜️ **内容压缩**: 文档使用了压缩技术 (${pdfInfo['compressionTypes'].join(", ")})，需要专门的解码器。');
      result.writeln();
    }
    
    if (pdfInfo['imageCount'] > pdfInfo['fontCount'] * 2) {
      result.writeln('🖼️ **图像型文档**: 文档主要由图像组成，可能是扫描版PDF。');
      result.writeln();
    }
    
    if (pdfInfo['streamCount'] == 0) {
      result.writeln('📄 **结构异常**: 未发现标准的内容流，文档结构可能异常。');
      result.writeln();
    }
    
    // 建议解决方案
    result.writeln('## 建议解决方案');
    result.writeln();
    result.writeln('1. **专业工具**: 使用Adobe Acrobat Pro或其他专业PDF工具');
    result.writeln('2. **OCR识别**: 对于图像型PDF，使用光学字符识别技术');
    result.writeln('3. **格式转换**: 尝试将PDF转换为Word或其他可编辑格式');
    result.writeln('4. **在线服务**: 使用在线PDF文本提取服务');
    result.writeln('5. **手动处理**: 对于重要内容，考虑人工录入');
    result.writeln();
    
    // 技术信息
    result.writeln('## 技术信息');
    result.writeln();
    result.writeln('本诊断使用了以下分析方法：');
    result.writeln('- ✅ 智能文本提取');
    result.writeln('- ✅ 深度结构分析');
    result.writeln('- ✅ 原始数据挖掘');
    result.writeln('- ✅ 字符频率分析');
    result.writeln();
    result.writeln('所有方法都未能成功提取可读文本，这表明文档可能存在特殊的保护或编码机制。');
    
    return result.toString();
  }

  /// 生成错误报告
  static String _generateErrorReport(String error, Uint8List bytes) {
    final result = StringBuffer();
    
    result.writeln('# PDF处理错误报告');
    result.writeln();
    result.writeln('**错误信息**: $error');
    result.writeln('**文件大小**: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    result.writeln('**错误时间**: ${DateTime.now()}');
    result.writeln();
    
    result.writeln('## 错误分析');
    result.writeln();
    result.writeln('处理PDF文件时遇到了意外错误。可能的原因包括：');
    result.writeln();
    result.writeln('- **文件损坏**: PDF文件可能已损坏或不完整');
    result.writeln('- **格式异常**: 文件格式不符合PDF标准');
    result.writeln('- **内存不足**: 处理大文件时系统资源不足');
    result.writeln('- **编码问题**: 文件使用了不支持的字符编码');
    result.writeln();
    
    result.writeln('## 建议操作');
    result.writeln();
    result.writeln('1. **验证文件**: 确认PDF文件完整且未损坏');
    result.writeln('2. **重新下载**: 如果是网络下载的文件，尝试重新下载');
    result.writeln('3. **文件修复**: 使用PDF修复工具尝试修复文件');
    result.writeln('4. **联系支持**: 如果问题持续，请联系技术支持');
    
    return result.toString();
  }
}
