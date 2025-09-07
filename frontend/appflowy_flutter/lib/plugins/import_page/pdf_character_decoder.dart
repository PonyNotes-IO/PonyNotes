// PDF character decoding utilities
import 'dart:typed_data';

class PdfCharacterDecoder {
  /// Decodes PDF text encoding
  static String decodeText(String text) {
    // Handle common PDF text encodings
    String decoded = text;
    
    // Handle escape sequences
    decoded = decoded.replaceAll(r'\(', '(');
    decoded = decoded.replaceAll(r'\)', ')');
    decoded = decoded.replaceAll(r'\\', '\\');
    decoded = decoded.replaceAll(r'\n', '\n');
    decoded = decoded.replaceAll(r'\r', '\r');
    decoded = decoded.replaceAll(r'\t', '\t');
    
    // Handle Unicode escape sequences
    decoded = _decodeUnicodeEscapes(decoded);
    
    return decoded;
  }
  
  /// Decodes PDF hex strings
  static String decodeHexString(String hexString) {
    if (!hexString.startsWith('<') || !hexString.endsWith('>')) {
      return hexString;
    }
    
    final hex = hexString.substring(1, hexString.length - 1);
    final bytes = <int>[];
    
    for (int i = 0; i < hex.length; i += 2) {
      if (i + 1 < hex.length) {
        final hexByte = hex.substring(i, i + 2);
        bytes.add(int.parse(hexByte, radix: 16));
      }
    }
    
    return String.fromCharCodes(bytes);
  }
  
  /// Handles character encoding conversion
  static String convertEncoding(Uint8List bytes, String encoding) {
    switch (encoding.toLowerCase()) {
      case 'utf-8':
      case 'utf8':
        return String.fromCharCodes(bytes);
      case 'latin-1':
      case 'iso-8859-1':
        return String.fromCharCodes(bytes);
      default:
        return String.fromCharCodes(bytes);
    }
  }
  
  static String _decodeUnicodeEscapes(String text) {
    return text.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4})'),
      (match) {
        final codePoint = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(codePoint);
      },
    );
  }
}
