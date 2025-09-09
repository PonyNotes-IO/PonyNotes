import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:appflowy_backend/log.dart';

/// 专业的HTML解析器，用于将HTML转换为结构化的Markdown
class ProfessionalHtmlParser {
  /// 将HTML内容转换为Markdown
  static String convertHtmlToMarkdown(String htmlContent, String fileName) {
    try {
      Log.info('🔍 开始专业HTML解析: $fileName');
      
      // 解析HTML文档
      final document = html_parser.parse(htmlContent);
      
      // 提取文档标题
      String title = _extractTitle(document, fileName);
      
      // 转换文档内容
      final buffer = StringBuffer();
      buffer.writeln('# $title\n');
      
      // 处理body内容，如果没有body则处理整个文档
      final bodyElement = document.body ?? document.documentElement;
      if (bodyElement != null) {
        _processElement(bodyElement, buffer, 0);
      } else {
        // 如果没有结构化内容，回退到纯文本
        buffer.writeln(_extractPlainText(document));
      }
      
      final result = buffer.toString().trim();
      Log.info('✅ HTML解析完成，生成Markdown长度: ${result.length}');
      
      return result.isEmpty ? _createFallbackContent(fileName, htmlContent) : result;
      
    } catch (e) {
      Log.error('❌ HTML解析失败: $e');
      return _createFallbackContent(fileName, htmlContent);
    }
  }
  
  /// 提取文档标题
  static String _extractTitle(dom.Document document, String fileName) {
    // 尝试从title标签获取
    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.trim().isNotEmpty) {
      return titleElement.text.trim();
    }
    
    // 尝试从第一个h1标签获取
    final h1Element = document.querySelector('h1');
    if (h1Element != null && h1Element.text.trim().isNotEmpty) {
      return h1Element.text.trim();
    }
    
    // 使用文件名
    return fileName;
  }
  
  /// 递归处理HTML元素
  static void _processElement(dom.Element element, StringBuffer buffer, int depth) {
    final tagName = element.localName?.toLowerCase() ?? '';
    
    switch (tagName) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _processHeading(element, buffer, tagName);
        break;
      case 'p':
        _processParagraph(element, buffer);
        break;
      case 'a':
        _processLink(element, buffer);
        break;
      case 'img':
        _processImage(element, buffer);
        break;
      case 'ul':
      case 'ol':
        _processList(element, buffer, tagName == 'ol');
        break;
      case 'li':
        // li元素由父级ul/ol处理
        break;
      case 'blockquote':
        _processBlockquote(element, buffer);
        break;
      case 'pre':
      case 'code':
        _processCode(element, buffer, tagName == 'pre');
        break;
      case 'table':
        _processTable(element, buffer);
        break;
      case 'br':
        buffer.writeln();
        break;
      case 'hr':
        buffer.writeln('\n---\n');
        break;
      case 'strong':
      case 'b':
        buffer.write('**${element.text}**');
        break;
      case 'em':
      case 'i':
        buffer.write('*${element.text}*');
        break;
      case 'div':
      case 'section':
      case 'article':
      case 'main':
      case 'header':
      case 'footer':
      case 'nav':
        _processContainer(element, buffer, depth);
        break;
      case 'script':
      case 'style':
      case 'meta':
      case 'link':
      case 'head':
        // 忽略这些元素
        break;
      default:
        // 处理其他元素，递归处理子元素
        _processChildren(element, buffer, depth);
    }
  }
  
  /// 处理标题
  static void _processHeading(dom.Element element, StringBuffer buffer, String tagName) {
    final level = int.parse(tagName.substring(1)); // h1 -> 1, h2 -> 2, etc.
    final prefix = '#' * level;
    final text = _getElementText(element).trim();
    if (text.isNotEmpty) {
      buffer.writeln('\n$prefix $text\n');
    }
  }
  
  /// 处理段落
  static void _processParagraph(dom.Element element, StringBuffer buffer) {
    final text = _getElementText(element).trim();
    if (text.isNotEmpty) {
      buffer.writeln('$text\n');
    }
  }
  
  /// 处理链接
  static void _processLink(dom.Element element, StringBuffer buffer) {
    final text = element.text.trim();
    final href = element.attributes['href'] ?? '';
    if (text.isNotEmpty) {
      if (href.isNotEmpty) {
        buffer.write('[$text]($href)');
      } else {
        buffer.write(text);
      }
    }
  }
  
  /// 处理图片
  static void _processImage(dom.Element element, StringBuffer buffer) {
    final alt = element.attributes['alt'] ?? '';
    final src = element.attributes['src'] ?? '';
    final width = element.attributes['width'];
    final height = element.attributes['height'];
    final style = element.attributes['style'] ?? '';
    
    if (src.isEmpty) return;
    
    // 检查是否是小图标或emoji
    if (_isSmallIcon(element, src, alt, width, height, style)) {
      // 对于小图标，使用简单的文本表示或emoji
      _processSmallIcon(element, buffer, alt, src);
    } else {
      // 对于普通图片，使用标准的Markdown图片格式
      buffer.writeln('![${alt.isNotEmpty ? alt : '图片'}]($src)\n');
    }
  }
  
  /// 判断是否是小图标 - 增强版检测
  static bool _isSmallIcon(dom.Element element, String src, String alt, String? width, String? height, String style) {
    final className = element.attributes['class'] ?? '';
    
    // 1. 优先检查CSS class名称 - 这是最可靠的方式
    if (className.isNotEmpty) {
      final classLower = className.toLowerCase();
      if (classLower.contains('label') ||
          classLower.contains('thumbnail') ||
          classLower.contains('icon') ||
          classLower.contains('emoji') ||
          classLower.contains('symbol') ||
          classLower.contains('small') ||
          classLower.contains('mini') ||
          classLower.contains('btn') ||
          classLower.contains('button')) {
        return true;
      }
    }
    
    // 2. 检查尺寸属性 - 扩大阈值
    if (width != null || height != null) {
      final w = _parseSize(width);
      final h = _parseSize(height);
      // 提高阈值到48px，更准确地识别小图标
      if ((w != null && w <= 48) || (h != null && h <= 48)) {
        return true;
      }
    }
    
    // 3. 检查CSS样式中的尺寸
    if (style.isNotEmpty) {
      final widthMatch = RegExp(r'width\s*:\s*(\d+)px').firstMatch(style);
      final heightMatch = RegExp(r'height\s*:\s*(\d+)px').firstMatch(style);
      if (widthMatch != null || heightMatch != null) {
        final w = widthMatch != null ? int.tryParse(widthMatch.group(1)!) : null;
        final h = heightMatch != null ? int.tryParse(heightMatch.group(1)!) : null;
        if ((w != null && w <= 48) || (h != null && h <= 48)) {
          return true;
        }
      }
    }
    
    // 4. 检查文件名关键词
    final srcLower = src.toLowerCase();
    if (srcLower.contains('icon') || 
        srcLower.contains('emoji') || 
        srcLower.contains('symbol') ||
        srcLower.contains('bullet') ||
        srcLower.contains('thumbnail') ||
        srcLower.contains('label') ||
        srcLower.endsWith('.ico')) {
      return true;
    }
    
    // 5. 检查alt文本
    if (alt.length == 1 || (alt.length <= 5 && _isLikelyEmoji(alt))) {
      return true;
    }
    
    // 6. 检查父元素
    final parent = element.parent;
    if (parent != null) {
      final parentClass = parent.attributes['class'] ?? '';
      if (parentClass.contains('icon') || 
          parentClass.contains('emoji') || 
          parentClass.contains('symbol') ||
          parentClass.contains('thumbnail') ||
          parentClass.contains('label')) {
        return true;
      }
    }
    
    return false;
  }
  
  /// 解析尺寸字符串为数字
  static int? _parseSize(String? size) {
    if (size == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(size);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
  
  /// 判断文本是否可能是emoji描述
  static bool _isLikelyEmoji(String text) {
    // 检查是否包含实际的emoji字符（使用Unicode范围）
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'  // 情绪符号
      r'[\u{1F300}-\u{1F5FF}]|'  // 符号和象形文字
      r'[\u{1F680}-\u{1F6FF}]|'  // 交通和地图符号
      r'[\u{1F1E0}-\u{1F1FF}]|'  // 旗帜
      r'[\u{2600}-\u{26FF}]|'    // 杂项符号
      r'[\u{2700}-\u{27BF}]',     // 装饰符号
      unicode: true
    );
    return emojiRegex.hasMatch(text);
  }
  
  /// 处理小图标
  static void _processSmallIcon(dom.Element element, StringBuffer buffer, String alt, String src) {
    final className = element.attributes['class'] ?? '';
    
    if (alt.isNotEmpty) {
      // 如果alt文本包含emoji，直接使用
      if (_isLikelyEmoji(alt)) {
        buffer.write(alt);
      } else if (alt.length <= 8) {
        // 对于短的alt文本，使用方括号包围
        buffer.write('[${alt}]');
      } else {
        // 对于较长的alt文本，截取并添加图标标识
        final shortAlt = alt.length > 15 ? '${alt.substring(0, 15)}...' : alt;
        buffer.write('🔸$shortAlt');
      }
    } else {
      // 没有alt文本时，根据class或src推断
      if (className.contains('emoji') || src.toLowerCase().contains('emoji')) {
        buffer.write('😊');
      } else {
        buffer.write('🔸'); // 通用图标符号
      }
    }
  }
  
  /// 处理列表
  static void _processList(dom.Element element, StringBuffer buffer, bool isOrdered) {
    buffer.writeln();
    final items = element.querySelectorAll('li');
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final text = _getElementText(item).trim();
      if (text.isNotEmpty) {
        final prefix = isOrdered ? '${i + 1}. ' : '- ';
        buffer.writeln('$prefix$text');
      }
    }
    buffer.writeln();
  }
  
  /// 处理引用
  static void _processBlockquote(dom.Element element, StringBuffer buffer) {
    final text = _getElementText(element).trim();
    if (text.isNotEmpty) {
      final lines = text.split('\n');
      buffer.writeln();
      for (final line in lines) {
        buffer.writeln('> ${line.trim()}');
      }
      buffer.writeln();
    }
  }
  
  /// 处理代码
  static void _processCode(dom.Element element, StringBuffer buffer, bool isBlock) {
    final text = element.text;
    if (text.isNotEmpty) {
      if (isBlock) {
        buffer.writeln('\n```');
        buffer.writeln(text);
        buffer.writeln('```\n');
      } else {
        buffer.write('`$text`');
      }
    }
  }
  
  /// 处理表格
  static void _processTable(dom.Element element, StringBuffer buffer) {
    final rows = element.querySelectorAll('tr');
    if (rows.isEmpty) return;
    
    buffer.writeln();
    
    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final cells = row.querySelectorAll('td, th');
      
      if (cells.isNotEmpty) {
        buffer.write('|');
        for (final cell in cells) {
          final text = _getElementText(cell).trim().replaceAll('|', '\\|');
          buffer.write(' $text |');
        }
        buffer.writeln();
        
        // 添加表头分隔符
        if (i == 0 && row.querySelector('th') != null) {
          buffer.write('|');
          for (int j = 0; j < cells.length; j++) {
            buffer.write(' --- |');
          }
          buffer.writeln();
        }
      }
    }
    
    buffer.writeln();
  }
  
  /// 处理容器元素
  static void _processContainer(dom.Element element, StringBuffer buffer, int depth) {
    _processChildren(element, buffer, depth);
    // 在容器后添加适当的间距
    if (depth == 0) {
      buffer.writeln();
    }
  }
  
  /// 处理子元素
  static void _processChildren(dom.Element element, StringBuffer buffer, int depth) {
    for (final child in element.children) {
      _processElement(child, buffer, depth + 1);
    }
    
    // 如果没有子元素但有文本内容，处理文本
    if (element.children.isEmpty && element.text.trim().isNotEmpty) {
      final text = element.text.trim();
      buffer.writeln('$text\n');
    }
  }
  
  /// 获取元素的纯文本内容，处理内联格式
  static String _getElementText(dom.Element element) {
    final buffer = StringBuffer();
    
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        buffer.write(node.text);
      } else if (node is dom.Element) {
        switch (node.localName?.toLowerCase()) {
          case 'strong':
          case 'b':
            buffer.write('**${node.text}**');
            break;
          case 'em':
          case 'i':
            buffer.write('*${node.text}*');
            break;
          case 'code':
            buffer.write('`${node.text}`');
            break;
          case 'a':
            final text = node.text.trim();
            final href = node.attributes['href'] ?? '';
            if (text.isNotEmpty && href.isNotEmpty) {
              buffer.write('[$text]($href)');
            } else {
              buffer.write(text);
            }
            break;
          case 'br':
            buffer.write('\n');
            break;
          default:
            buffer.write(node.text);
        }
      }
    }
    
    return buffer.toString();
  }
  
  /// 提取纯文本内容（回退方案）
  static String _extractPlainText(dom.Document document) {
    // 移除script和style标签
    document.querySelectorAll('script, style').forEach((element) {
      element.remove();
    });
    
    final text = document.body?.text ?? document.text ?? '';
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
  
  /// 创建回退内容
  static String _createFallbackContent(String fileName, String htmlContent) {
    Log.info('⚠️ 使用HTML回退方案');
    
    // 尝试提取基本信息
    final document = html_parser.parse(htmlContent);
    final title = _extractTitle(document, fileName);
    final plainText = _extractPlainText(document);
    
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    
    if (plainText.isNotEmpty && plainText.length > 20) {
      buffer.writeln(plainText);
      buffer.writeln('\n---\n');
      buffer.writeln('*注意：此文档是从HTML文件自动转换而来，可能丢失了原始格式。*');
    } else {
      buffer.writeln('导入的HTML文件内容无法正确解析。\n');
      buffer.writeln('原始HTML文件可能包含复杂的结构、样式或脚本。\n');
      buffer.writeln('建议：');
      buffer.writeln('1. 检查原始HTML文件是否完整');
      buffer.writeln('2. 尝试在浏览器中打开原始文件');
      buffer.writeln('3. 考虑使用其他格式（如Markdown或纯文本）重新保存');
    }
    
    return buffer.toString();
  }
  
  /// 为复杂HTML提供原始显示选项
  static String createHtmlViewerContent(String fileName, String htmlContent) {
    final buffer = StringBuffer();
    buffer.writeln('# $fileName (HTML源文档)\n');
    buffer.writeln('此文档包含原始HTML内容，建议在浏览器中查看以获得最佳显示效果。\n');
    buffer.writeln('## HTML内容预览\n');
    buffer.writeln('```html');
    
    // 限制显示的HTML长度，避免文档过大
    final previewLength = htmlContent.length > 5000 ? 5000 : htmlContent.length;
    buffer.writeln(htmlContent.substring(0, previewLength));
    
    if (htmlContent.length > 5000) {
      buffer.writeln('\n... (内容已截断，完整内容请查看原始文件)');
    }
    
    buffer.writeln('```\n');
    buffer.writeln('*提示：此文档显示的是HTML源代码。要查看渲染后的效果，请在浏览器中打开原始HTML文件。*');
    
    return buffer.toString();
  }
}
