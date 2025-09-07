import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// 强健的PDF处理器
/// 使用多种方法来提取PDF内容，避免依赖有问题的库
class RobustPdfProcessor {
  /// 处理PDF字节数据
  static Future<String> processPdfBytes(Uint8List bytes) async {
    try {
      // 方法1: 尝试直接文本提取
      final directText = await _extractDirectText(bytes);
      if (directText.isNotEmpty && directText.length > 100) {
        return _formatExtractedText(directText, '直接文本提取');
      }

      // 方法2: PDF结构分析
      final structuralText = await _extractStructuralText(bytes);
      if (structuralText.isNotEmpty && structuralText.length > 50) {
        return _formatExtractedText(structuralText, 'PDF结构分析');
      }

      // 方法3: 字节流分析
      final streamText = await _extractFromStreams(bytes);
      if (streamText.isNotEmpty) {
        return _formatExtractedText(streamText, '字节流分析');
      }

      // 如果所有方法都失败，返回基本信息
      return _generateFallbackContent(bytes);

    } catch (e) {
      debugPrint('RobustPdfProcessor 错误: $e');
      return _generateErrorContent(e.toString(), bytes);
    }
  }

  /// 直接文本提取方法
  static Future<String> _extractDirectText(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      // 查找PDF中的文本对象
      final pdfString = String.fromCharCodes(bytes);
      final textObjects = _findTextObjects(pdfString);
      
      for (final textObj in textObjects) {
        final extractedText = _decodeTextObject(textObj);
        if (extractedText.isNotEmpty) {
          content.writeln(extractedText);
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      debugPrint('直接文本提取失败: $e');
      return '';
    }
  }

  /// PDF结构分析方法
  static Future<String> _extractStructuralText(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      final pdfString = String.fromCharCodes(bytes);
      
      // 查找页面内容流
      final contentStreams = _findContentStreams(pdfString);
      
      for (final stream in contentStreams) {
        final text = _parseContentStream(stream);
        if (text.isNotEmpty) {
          content.writeln(text);
          content.writeln('---');
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      debugPrint('结构分析失败: $e');
      return '';
    }
  }

  /// 字节流分析方法
  static Future<String> _extractFromStreams(Uint8List bytes) async {
    final content = StringBuffer();
    
    try {
      final pdfString = String.fromCharCodes(bytes);
      
      // 查找所有可能包含文本的流对象
      final streams = _findAllStreams(pdfString);
      
      for (final stream in streams) {
        final decodedText = _tryDecodeStream(stream);
        if (decodedText.isNotEmpty && _isValidText(decodedText)) {
          content.writeln(decodedText);
          content.writeln();
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      debugPrint('字节流分析失败: $e');
      return '';
    }
  }

  /// 查找PDF中的文本对象
  static List<String> _findTextObjects(String pdfContent) {
    final textObjects = <String>[];
    
    // 查找BT...ET文本块
    final btPattern = RegExp(r'BT\s+(.*?)\s+ET', dotAll: true);
    final matches = btPattern.allMatches(pdfContent);
    
    for (final match in matches) {
      final textBlock = match.group(1);
      if (textBlock != null && textBlock.isNotEmpty) {
        textObjects.add(textBlock);
      }
    }
    
    return textObjects;
  }

  /// 解码文本对象
  static String _decodeTextObject(String textObject) {
    final content = StringBuffer();
    
    try {
      // 查找文本显示命令: Tj, TJ, '
      final textCommands = [
        RegExp(r'\((.*?)\)\s*Tj'),
        RegExp(r"\((.*?)\)\s*'"),
        RegExp(r'\[(.*?)\]\s*TJ'),
      ];
      
      for (final pattern in textCommands) {
        final matches = pattern.allMatches(textObject);
        for (final match in matches) {
          final text = match.group(1);
          if (text != null) {
            final decodedText = _decodeString(text);
            if (decodedText.isNotEmpty) {
              content.write(decodedText);
              content.write(' ');
            }
          }
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 查找内容流
  static List<String> _findContentStreams(String pdfContent) {
    final streams = <String>[];
    
    // 查找stream...endstream块
    final streamPattern = RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true);
    final matches = streamPattern.allMatches(pdfContent);
    
    for (final match in matches) {
      final streamContent = match.group(1);
      if (streamContent != null && streamContent.isNotEmpty) {
        streams.add(streamContent);
      }
    }
    
    return streams;
  }

  /// 解析内容流
  static String _parseContentStream(String streamContent) {
    final content = StringBuffer();
    
    try {
      // 尝试查找文本命令
      final lines = streamContent.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        
        // 查找文本显示命令
        if (trimmedLine.contains('Tj') || trimmedLine.contains('TJ') || trimmedLine.endsWith("'")) {
          final textMatch = RegExp(r'\((.*?)\)').firstMatch(trimmedLine);
          if (textMatch != null) {
            final text = _decodeString(textMatch.group(1)!);
            if (text.isNotEmpty) {
              content.writeln(text);
            }
          }
        }
      }
      
      return content.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// 查找所有流
  static List<String> _findAllStreams(String pdfContent) {
    final streams = <String>[];
    
    try {
      // 更宽泛的流查找
      final patterns = [
        RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true),
        RegExp(r'stream\s+(.*?)\s+endstream', dotAll: true),
      ];
      
      for (final pattern in patterns) {
        final matches = pattern.allMatches(pdfContent);
        for (final match in matches) {
          final streamContent = match.group(1);
          if (streamContent != null && streamContent.length > 10) {
            streams.add(streamContent);
          }
        }
      }
    } catch (e) {
      debugPrint('查找流失败: $e');
    }
    
    return streams;
  }

  /// 尝试解码流
  static String _tryDecodeStream(String streamContent) {
    try {
      // 尝试多种解码方式
      
      // 1. 直接查找可读文本
      final readableText = _extractReadableText(streamContent);
      if (readableText.isNotEmpty) {
        return readableText;
      }
      
      // 2. 尝试解码十六进制
      final hexDecoded = _tryHexDecode(streamContent);
      if (hexDecoded.isNotEmpty) {
        return hexDecoded;
      }
      
      // 3. 查找括号内的文本
      final bracketText = _extractBracketText(streamContent);
      if (bracketText.isNotEmpty) {
        return bracketText;
      }
      
      return '';
    } catch (e) {
      return '';
    }
  }

  /// 提取可读文本
  static String _extractReadableText(String content) {
    final result = StringBuffer();
    final lines = content.split('\n');
    
    for (final line in lines) {
      // 查找包含可读字符的行
      if (_containsReadableText(line)) {
        final cleanedLine = _cleanLine(line);
        if (cleanedLine.isNotEmpty) {
          result.writeln(cleanedLine);
        }
      }
    }
    
    return result.toString().trim();
  }

  /// 尝试十六进制解码
  static String _tryHexDecode(String content) {
    try {
      final hexPattern = RegExp(r'<([0-9A-Fa-f\s]+)>');
      final matches = hexPattern.allMatches(content);
      final result = StringBuffer();
      
      for (final match in matches) {
        final hexString = match.group(1)!.replaceAll(RegExp(r'\s+'), '');
        if (hexString.length % 2 == 0) {
          try {
            final bytes = <int>[];
            for (int i = 0; i < hexString.length; i += 2) {
              final hexByte = hexString.substring(i, i + 2);
              bytes.add(int.parse(hexByte, radix: 16));
            }
            final decoded = String.fromCharCodes(bytes);
            if (_isValidText(decoded)) {
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

  /// 提取括号内文本
  static String _extractBracketText(String content) {
    final result = StringBuffer();
    final bracketPattern = RegExp(r'\((.*?)\)');
    final matches = bracketPattern.allMatches(content);
    
    for (final match in matches) {
      final text = _decodeString(match.group(1)!);
      if (text.isNotEmpty) {
        result.write(text);
        result.write(' ');
      }
    }
    
    return result.toString().trim();
  }

  /// 解码字符串
  static String _decodeString(String encoded) {
    try {
      // 处理转义字符
      String decoded = encoded
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .replaceAll(r'\t', '\t')
          .replaceAll(r'\\', '\\')
          .replaceAll(r'\(', '(')
          .replaceAll(r'\)', ')');
      
      // 过滤控制字符
      decoded = decoded.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]'), '');
      
      return decoded.trim();
    } catch (e) {
      return '';
    }
  }

  /// 检查是否包含可读文本
  static bool _containsReadableText(String line) {
    if (line.length < 3) return false;
    
    // 检查是否包含字母数字字符
    final readableChars = RegExp(r'[a-zA-Z0-9\u4e00-\u9fff]');
    final matches = readableChars.allMatches(line);
    
    // 至少包含3个可读字符
    return matches.length >= 3;
  }

  /// 清理行内容
  static String _cleanLine(String line) {
    return line
        .replaceAll(RegExp(r'[^\w\s\u4e00-\u9fff.,;:!?()[\]{}"/-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 验证文本有效性
  static bool _isValidText(String text) {
    if (text.length < 2) return false;
    
    // 检查是否包含足够的可读字符
    final readableChars = RegExp(r'[a-zA-Z0-9\u4e00-\u9fff]');
    final matches = readableChars.allMatches(text);
    
    // 可读字符比例应该大于30%
    return matches.length / text.length > 0.3;
  }

  /// 格式化提取的文本
  static String _formatExtractedText(String text, String method) {
    final result = StringBuffer();
    
    result.writeln('# PDF内容提取结果');
    result.writeln();
    result.writeln('**提取方法**: $method');
    result.writeln('**提取时间**: ${DateTime.now()}');
    result.writeln('**内容长度**: ${text.length} 字符');
    result.writeln();
    result.writeln('---');
    result.writeln();
    
    // 分段处理文本
    final lines = text.split('\n');
    final processedLines = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        processedLines.add(trimmed);
      }
    }
    
    // 智能分段
    String currentParagraph = '';
    for (final line in processedLines) {
      if (line.length < 50 && !line.endsWith('.') && !line.endsWith('。')) {
        // 可能是标题
        if (currentParagraph.isNotEmpty) {
          result.writeln(currentParagraph);
          result.writeln();
          currentParagraph = '';
        }
        result.writeln('## $line');
        result.writeln();
      } else {
        // 正文内容
        if (currentParagraph.isNotEmpty) {
          currentParagraph += ' ';
        }
        currentParagraph += line;
        
        // 如果段落过长，换行
        if (currentParagraph.length > 200) {
          result.writeln(currentParagraph);
          result.writeln();
          currentParagraph = '';
        }
      }
    }
    
    if (currentParagraph.isNotEmpty) {
      result.writeln(currentParagraph);
    }
    
    return result.toString();
  }

  /// 生成备用内容
  static String _generateFallbackContent(Uint8List bytes) {
    final result = StringBuffer();
    
    result.writeln('# PDF文档信息');
    result.writeln();
    result.writeln('**状态**: 无法提取文本内容');
    result.writeln('**文件大小**: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    result.writeln('**分析时间**: ${DateTime.now()}');
    result.writeln();
    result.writeln('## 可能的原因');
    result.writeln();
    result.writeln('1. **图像型PDF**: 文档主要由扫描图像组成');
    result.writeln('2. **加密保护**: PDF文档受到密码保护');
    result.writeln('3. **特殊编码**: 使用了不常见的文本编码方式');
    result.writeln('4. **复杂格式**: 包含复杂的表格或特殊布局');
    result.writeln();
    result.writeln('## 建议解决方案');
    result.writeln();
    result.writeln('1. **OCR识别**: 使用光学字符识别技术');
    result.writeln('2. **专业工具**: 使用Adobe Acrobat等专业PDF工具');
    result.writeln('3. **格式转换**: 将PDF转换为Word或其他格式');
    result.writeln('4. **手动输入**: 对于重要内容进行人工录入');
    
    // 尝试提取基本信息
    final basicInfo = _extractBasicInfo(bytes);
    if (basicInfo.isNotEmpty) {
      result.writeln();
      result.writeln('## 基本信息');
      result.writeln();
      result.writeln(basicInfo);
    }
    
    return result.toString();
  }

  /// 提取基本信息
  static String _extractBasicInfo(Uint8List bytes) {
    try {
      final pdfString = String.fromCharCodes(bytes);
      final info = StringBuffer();
      
      // 查找PDF版本
      final versionMatch = RegExp(r'%PDF-(\d\.\d)').firstMatch(pdfString);
      if (versionMatch != null) {
        info.writeln('**PDF版本**: ${versionMatch.group(1)}');
      }
      
      // 查找页数信息
      final pageMatches = RegExp(r'/Type\s*/Page[^s]').allMatches(pdfString);
      if (pageMatches.isNotEmpty) {
        info.writeln('**预估页数**: ${pageMatches.length} 页');
      }
      
      // 查找创建信息
      final creatorMatch = RegExp(r'/Creator\s*\((.*?)\)').firstMatch(pdfString);
      if (creatorMatch != null) {
        info.writeln('**创建者**: ${creatorMatch.group(1)}');
      }
      
      final producerMatch = RegExp(r'/Producer\s*\((.*?)\)').firstMatch(pdfString);
      if (producerMatch != null) {
        info.writeln('**生成器**: ${producerMatch.group(1)}');
      }
      
      return info.toString();
    } catch (e) {
      return '';
    }
  }

  /// 生成错误内容
  static String _generateErrorContent(String error, Uint8List bytes) {
    final result = StringBuffer();
    
    result.writeln('# PDF处理错误');
    result.writeln();
    result.writeln('**错误信息**: $error');
    result.writeln('**文件大小**: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    result.writeln('**处理时间**: ${DateTime.now()}');
    result.writeln();
    result.writeln('## 错误详情');
    result.writeln();
    result.writeln('处理PDF文件时遇到了技术问题。这可能是由于：');
    result.writeln();
    result.writeln('- PDF文件格式不标准或损坏');
    result.writeln('- 文件包含不支持的特殊功能');
    result.writeln('- 系统资源不足或处理超时');
    result.writeln();
    result.writeln('请尝试：');
    result.writeln('1. 确认PDF文件完整且未损坏');
    result.writeln('2. 使用其他PDF工具进行预处理');
    result.writeln('3. 联系技术支持获取帮助');
    
    return result.toString();
  }
}
