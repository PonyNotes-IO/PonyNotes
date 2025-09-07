// PDF stream parsing utilities
import 'dart:typed_data';

class PdfStream {
  final String filter;
  final Uint8List data;
  final Map<String, dynamic> parameters;
  final int objectNumber;
  
  PdfStream({
    required this.filter,
    required this.data,
    this.parameters = const {},
    this.objectNumber = 0,
  });
  
  /// 从流中提取文本
  String extractText() {
    return PdfStreamParser._extractTextFromStream(this);
  }
  
  /// 获取原始数据
  Uint8List get rawData => data;
  
  /// 获取过滤器列表
  List<String> get filters => [filter];
}

class PdfStreamParser {
  /// Parses PDF streams from raw data
  static List<PdfStream> parseStreams(Uint8List data) {
    final streams = <PdfStream>[];
    
    // Simple stream parsing - in a real implementation, this would
    // properly parse PDF stream objects
    final content = String.fromCharCodes(data);
    final streamMatches = RegExp(r'(\d+)\s+\d+\s+obj.*?stream\s*(.*?)\s*endstream', dotAll: true)
        .allMatches(content);
    
    int streamIndex = 0;
    for (final match in streamMatches) {
      final objectNumber = int.tryParse(match.group(1) ?? '0') ?? streamIndex;
      final streamData = match.group(2) ?? '';
      streams.add(PdfStream(
        filter: 'FlateDecode', // Default filter
        data: Uint8List.fromList(streamData.codeUnits),
        objectNumber: objectNumber,
      ));
      streamIndex++;
    }
    
    return streams;
  }
  
  /// Extracts text from PDF streams
  static String extractTextFromStreams(List<PdfStream> streams) {
    final buffer = StringBuffer();
    
    for (final stream in streams) {
      final text = _extractTextFromStream(stream);
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }
    
    return buffer.toString();
  }
  
  /// 查找包含文本的流
  static List<PdfStream> findTextStreams(List<PdfStream> streams) {
    return streams.where((stream) {
      final text = _extractTextFromStream(stream);
      return text.trim().isNotEmpty && _isLikelyText(text);
    }).toList();
  }
  
  /// 检查内容是否像是文本
  static bool _isLikelyText(String content) {
    if (content.length < 3) return false;
    
    // 计算可打印字符的比例
    int printableCount = 0;
    for (final char in content.codeUnits) {
      if ((char >= 32 && char <= 126) || 
          char == 9 || char == 10 || char == 13) {
        printableCount++;
      }
    }
    
    return printableCount > content.length * 0.5;
  }
  
  static String _extractTextFromStream(PdfStream stream) {
    // Basic text extraction - in a real implementation, this would
    // handle different stream types and text rendering operators
    final content = String.fromCharCodes(stream.data);
    
    // Extract text between parentheses (simplified)
    final textMatches = RegExp(r'\((.*?)\)').allMatches(content);
    final buffer = StringBuffer();
    
    for (final match in textMatches) {
      buffer.write(match.group(1) ?? '');
      buffer.write(' ');
    }
    
    return buffer.toString().trim();
  }
}
