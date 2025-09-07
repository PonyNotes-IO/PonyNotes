// Advanced PDF content filtering utilities
import 'dart:math';

class PdfContentFilterV2 {
  /// Filters and cleans PDF text content
  static String filterContent(String content) {
    if (content.isEmpty) return content;
    
    String filtered = content;
    
    // Remove excessive whitespace
    filtered = _normalizeWhitespace(filtered);
    
    // Filter out non-printable characters
    filtered = _removeNonPrintableChars(filtered);
    
    // Clean up common PDF artifacts
    filtered = _cleanPdfArtifacts(filtered);
    
    // Improve paragraph structure
    filtered = _improveParagraphStructure(filtered);
    
    return filtered.trim();
  }
  
  /// Extracts readable text from content
  static String extractReadableText(String content) {
    return filterContent(content);
  }
  
  /// Analyzes content characteristics
  static Map<String, dynamic> analyzeContent(String content) {
    final quality = analyzeQuality(content);
    return {
      'quality': quality,
      'length': content.length,
      'wordCount': content.split(RegExp(r'\s+')).length,
      'specialCharRatio': _calculateSpecialCharRatio(content),
      'avgWordLength': _calculateAverageWordLength(content),
      'hasSentenceStructure': _hasSentenceStructure(content),
    };
  }
  
  /// Analyzes content quality
  static double analyzeQuality(String content) {
    if (content.isEmpty) return 0.0;
    
    double score = 1.0;
    
    // Check for excessive special characters
    final specialCharRatio = _calculateSpecialCharRatio(content);
    if (specialCharRatio > 0.3) {
      score *= (1.0 - specialCharRatio);
    }
    
    // Check for reasonable word length
    final avgWordLength = _calculateAverageWordLength(content);
    if (avgWordLength < 2 || avgWordLength > 15) {
      score *= 0.5;
    }
    
    // Check for proper sentence structure
    if (!_hasSentenceStructure(content)) {
      score *= 0.7;
    }
    
    return max(0.0, min(1.0, score));
  }
  
  static String _normalizeWhitespace(String text) {
    // Replace multiple spaces with single space
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    
    // Normalize line breaks
    text = text.replaceAll(RegExp(r'\r\n|\r'), '\n');
    
    // Remove excessive blank lines
    text = text.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return text;
  }
  
  static String _removeNonPrintableChars(String text) {
    return text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }
  
  static String _cleanPdfArtifacts(String text) {
    // Remove common PDF rendering artifacts
    text = text.replaceAll(RegExp(r'[^\x20-\x7E\n\t]'), '');
    
    // Clean up font/formatting markers
    text = text.replaceAll(RegExp(r'Tf\s+\d+'), '');
    text = text.replaceAll(RegExp(r'Td\s+[\d\.\-]+\s+[\d\.\-]+'), '');
    
    return text;
  }
  
  static String _improveParagraphStructure(String text) {
    // Add proper spacing after periods
    text = text.replaceAll(RegExp(r'\.([A-Z])'), '. \$1');
    
    // Ensure paragraphs are properly separated
    text = text.replaceAll(RegExp(r'([.!?])\s*([A-Z][a-z])'), '\$1\n\n\$2');
    
    return text;
  }
  
  static double _calculateSpecialCharRatio(String text) {
    final specialChars = text.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '');
    return text.isEmpty ? 0.0 : specialChars.length / text.length;
  }
  
  static double _calculateAverageWordLength(String text) {
    final words = text.split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    
    if (words.isEmpty) return 0.0;
    
    final totalLength = words.fold(0, (sum, word) => sum + word.length);
    return totalLength / words.length;
  }
  
  static bool _hasSentenceStructure(String text) {
    // Check for basic sentence structure indicators
    return text.contains(RegExp(r'[.!?]')) && 
           text.contains(RegExp(r'[A-Z][a-z]'));
  }
}
