import 'dart:io';
import 'dart:convert';

/// 🎯 基于Poppler的专业PDF转Markdown转换器
/// 使用成熟的poppler工具包实现高质量PDF文本提取
class PopplerPdfConverter {
  
  /// 📄 将PDF文件转换为Markdown
  static Future<String> convertPdfToMarkdown(String pdfPath) async {
    print('🚀 Poppler PDF转Markdown转换器');
    print('📁 处理文件: $pdfPath');
    
    try {
      // 验证文件存在
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF文件不存在: $pdfPath');
      }
      
      final fileSize = await pdfFile.length();
      print('📊 文件大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      // 检查poppler工具是否可用
      print('🔍 检查poppler工具...');
      await _checkPopplerTools();
      
      // 获取PDF基本信息
      final pdfInfo = await _getPdfInfo(pdfPath);
      print('📄 PDF信息: $pdfInfo');
      
      // 提取文本内容
      print('🔍 使用pdftotext提取文本...');
      final extractedText = await _extractTextWithPdftotext(pdfPath);
      
      if (extractedText.trim().isEmpty) {
        print('⚠️ 无法提取文本内容，生成分析报告...');
        return _generateAnalysisReport(pdfPath, pdfInfo, fileSize);
      }
      
      // 生成最终Markdown文档
      return _generateMarkdownDocument(pdfPath, extractedText, pdfInfo, fileSize);
      
    } catch (e, stackTrace) {
      print('❌ PDF转换失败: $e');
      print('📋 堆栈跟踪: $stackTrace');
      return _generateErrorMarkdown(pdfPath, e.toString());
    }
  }
  
  /// 🔍 检查poppler工具是否可用
  static Future<void> _checkPopplerTools() async {
    final tools = ['pdftotext', 'pdfinfo', 'pdftoppm'];
    
    for (String tool in tools) {
      try {
        final result = await Process.run('which', [tool]);
        if (result.exitCode == 0) {
          print('✅ $tool: ${result.stdout.toString().trim()}');
        } else {
          print('⚠️ $tool: 未找到');
        }
      } catch (e) {
        print('⚠️ $tool: 检查失败 - $e');
      }
    }
  }
  
  /// 📊 获取PDF基本信息
  static Future<Map<String, String>> _getPdfInfo(String pdfPath) async {
    final Map<String, String> info = {};
    
    try {
      final result = await Process.run('pdfinfo', [pdfPath]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (String line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join(':').trim();
              info[key] = value;
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ 获取PDF信息失败: $e');
    }
    
    return info;
  }
  
  /// 📝 使用pdftotext提取文本
  static Future<String> _extractTextWithPdftotext(String pdfPath) async {
    try {
      // 方法1: 默认布局提取
      print('🔍 方法1: 默认布局提取...');
      final result1 = await Process.run('pdftotext', [pdfPath, '-']);
      
      if (result1.exitCode == 0 && result1.stdout.toString().trim().isNotEmpty) {
        final text1 = result1.stdout.toString();
        print('✅ 默认提取成功: ${text1.length} 字符');
        return text1;
      }
      
      // 方法2: 保持布局提取
      print('🔍 方法2: 保持布局提取...');
      final result2 = await Process.run('pdftotext', ['-layout', pdfPath, '-']);
      
      if (result2.exitCode == 0 && result2.stdout.toString().trim().isNotEmpty) {
        final text2 = result2.stdout.toString();
        print('✅ 布局提取成功: ${text2.length} 字符');
        return text2;
      }
      
      // 方法3: 原始文本提取
      print('🔍 方法3: 原始文本提取...');
      final result3 = await Process.run('pdftotext', ['-raw', pdfPath, '-']);
      
      if (result3.exitCode == 0 && result3.stdout.toString().trim().isNotEmpty) {
        final text3 = result3.stdout.toString();
        print('✅ 原始提取成功: ${text3.length} 字符');
        return text3;
      }
      
      // 方法4: 表格提取
      print('🔍 方法4: 表格模式提取...');
      final result4 = await Process.run('pdftotext', ['-table', pdfPath, '-']);
      
      if (result4.exitCode == 0 && result4.stdout.toString().trim().isNotEmpty) {
        final text4 = result4.stdout.toString();
        print('✅ 表格提取成功: ${text4.length} 字符');
        return text4;
      }
      
      print('⚠️ 所有提取方法都失败');
      return '';
      
    } catch (e) {
      print('⚠️ pdftotext提取失败: $e');
      return '';
    }
  }
  
  /// 📊 生成分析报告
  static String _generateAnalysisReport(String pdfPath, Map<String, String> pdfInfo, int fileSize) {
    final StringBuffer analysis = StringBuffer();
    
    analysis.writeln('## 📊 PDF文档分析报告\n');
    
    // 基本信息
    analysis.writeln('### 📋 基本信息');
    analysis.writeln('- **文件路径**: `$pdfPath`');
    analysis.writeln('- **文件大小**: ${(fileSize / 1024).toStringAsFixed(2)} KB');
    
    // PDF信息
    if (pdfInfo.isNotEmpty) {
      analysis.writeln('\n### 📄 PDF属性');
      pdfInfo.forEach((key, value) {
        if (value.isNotEmpty) {
          analysis.writeln('- **$key**: $value');
        }
      });
    }
    
    analysis.writeln('\n### 🔍 可能的问题');
    analysis.writeln('1. **扫描文档**: 此PDF可能是扫描版本，文字以图像形式存储');
    analysis.writeln('2. **图形内容**: 主要包含图形、图表或图像内容');
    analysis.writeln('3. **特殊编码**: 使用了特殊的字体编码或文本布局');
    analysis.writeln('4. **保护设置**: 可能设置了文本提取限制');
    analysis.writeln('5. **损坏文件**: PDF文件可能存在损坏或格式问题');
    
    analysis.writeln('\n### 💡 建议解决方案');
    analysis.writeln('1. **OCR识别**: 使用OCR工具识别扫描文档中的文字');
    analysis.writeln('   ```bash');
    analysis.writeln('   # 使用tesseract进行OCR');
    analysis.writeln('   pdftoppm "$pdfPath" output -png');
    analysis.writeln('   tesseract output-*.png output txt');
    analysis.writeln('   ```');
    analysis.writeln('2. **图像转换**: 先转换为图像再进行处理');
    analysis.writeln('   ```bash');
    analysis.writeln('   # 转换为图像');
    analysis.writeln('   pdftoppm -png "$pdfPath" page');
    analysis.writeln('   ```');
    analysis.writeln('3. **专业工具**: 使用Adobe Acrobat、Foxit等专业PDF工具');
    analysis.writeln('4. **在线服务**: 尝试SmallPDF、ILovePDF等在线转换服务');
    analysis.writeln('5. **原始格式**: 如果可能，获取原始Word或其他可编辑格式');
    
    return analysis.toString();
  }
  
  /// 📝 生成Markdown文档
  static String _generateMarkdownDocument(String pdfPath, String content, Map<String, String> pdfInfo, int fileSize) {
    final StringBuffer markdown = StringBuffer();
    final String fileName = pdfPath.split('/').last.replaceAll('.pdf', '');
    final DateTime now = DateTime.now();
    
    // 文档头部
    markdown.writeln('# $fileName\n');
    markdown.writeln('> 📄 PDF文档转换结果');
    markdown.writeln('> 🕐 转换时间: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}');
    markdown.writeln('> 🛠️ 转换工具: Poppler pdftotext\n');
    
    // PDF信息表格
    if (pdfInfo.isNotEmpty) {
      markdown.writeln('## 📊 文档信息\n');
      markdown.writeln('| 属性 | 值 |');
      markdown.writeln('|------|-----|');
      
      final importantKeys = ['Title', 'Author', 'Subject', 'Creator', 'Producer', 'Pages', 'CreationDate', 'ModDate'];
      for (String key in importantKeys) {
        if (pdfInfo.containsKey(key) && pdfInfo[key]!.isNotEmpty) {
          markdown.writeln('| $key | ${pdfInfo[key]} |');
        }
      }
      
      // 其他属性
      pdfInfo.forEach((key, value) {
        if (!importantKeys.contains(key) && value.isNotEmpty) {
          markdown.writeln('| $key | $value |');
        }
      });
      
      markdown.writeln('');
    }
    
    // 处理和格式化内容
    if (content.trim().isNotEmpty) {
      markdown.writeln('## 📖 提取的内容\n');
      
      // 智能内容格式化
      final formattedContent = _formatContent(content);
      markdown.writeln(formattedContent);
    } else {
      markdown.writeln('## ⚠️ 内容提取失败\n');
      markdown.writeln('无法从此PDF文件中提取可读文本内容。');
      markdown.writeln('这可能是因为PDF主要由图像组成或使用了特殊编码。\n');
    }
    
    // 技术信息
    markdown.writeln('\n---\n');
    markdown.writeln('## 🔧 转换信息\n');
    markdown.writeln('| 项目 | 值 |');
    markdown.writeln('|------|-----|');
    markdown.writeln('| 原始文件 | `$pdfPath` |');
    markdown.writeln('| 转换工具 | Poppler pdftotext |');
    markdown.writeln('| 转换时间 | ${now.toString().split('.')[0]} |');
    markdown.writeln('| 文件大小 | ${(fileSize / 1024).toStringAsFixed(2)} KB |');
    markdown.writeln('| 内容长度 | ${content.length} 字符 |');
    markdown.writeln('| 转换状态 | ${content.trim().isNotEmpty ? '✅ 成功' : '❌ 失败'} |');
    
    return markdown.toString();
  }
  
  /// 📝 智能格式化内容
  static String _formatContent(String rawContent) {
    if (rawContent.trim().isEmpty) return '';
    
    // 基本清理
    String content = rawContent
        .replaceAll(RegExp(r'\r\n'), '\n')      // 统一换行符
        .replaceAll(RegExp(r'\r'), '\n')        // 统一换行符
        .replaceAll(RegExp(r'\n{4,}'), '\n\n\n') // 限制连续空行
        .replaceAll(RegExp(r'[ \t]+'), ' ')     // 合并多个空格
        .trim();
    
    final lines = content.split('\n');
    final StringBuffer formatted = StringBuffer();
    
    bool inCodeBlock = false;
    String? lastLineType;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmedLine = line.trim();
      
      // 跳过空行，但保留一些结构
      if (trimmedLine.isEmpty) {
        if (lastLineType != 'empty') {
          formatted.writeln('');
          lastLineType = 'empty';
        }
        continue;
      }
      
      // 检测代码块
      if (trimmedLine.startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        formatted.writeln(trimmedLine);
        lastLineType = 'code';
        continue;
      }
      
      if (inCodeBlock) {
        formatted.writeln(line);
        lastLineType = 'code';
        continue;
      }
      
      // 检测标题
      if (_isTitle(trimmedLine, i, lines)) {
        if (lastLineType != 'empty') {
          formatted.writeln('');
        }
        
        // 根据内容判断标题级别
        String titlePrefix = '### ';
        if (trimmedLine.length < 30 && trimmedLine == trimmedLine.toUpperCase()) {
          titlePrefix = '## ';
        } else if (_isMainTitle(trimmedLine)) {
          titlePrefix = '# ';
        }
        
        formatted.writeln('$titlePrefix$trimmedLine\n');
        lastLineType = 'title';
        continue;
      }
      
      // 检测列表项
      if (_isListItem(trimmedLine)) {
        if (lastLineType != 'list' && lastLineType != 'empty') {
          formatted.writeln('');
        }
        
        if (!trimmedLine.startsWith('-') && !trimmedLine.startsWith('*') && !RegExp(r'^\d+\.').hasMatch(trimmedLine)) {
          formatted.writeln('- $trimmedLine');
        } else {
          formatted.writeln(trimmedLine);
        }
        lastLineType = 'list';
        continue;
      }
      
      // 检测表格行
      if (_isTableRow(trimmedLine)) {
        if (lastLineType != 'table' && lastLineType != 'empty') {
          formatted.writeln('');
        }
        formatted.writeln('| ${trimmedLine.replaceAll(RegExp(r'\s{2,}'), ' | ')} |');
        lastLineType = 'table';
        continue;
      }
      
      // 检测引用
      if (_isQuote(trimmedLine)) {
        if (lastLineType != 'quote' && lastLineType != 'empty') {
          formatted.writeln('');
        }
        formatted.writeln('> $trimmedLine');
        lastLineType = 'quote';
        continue;
      }
      
      // 普通段落
      formatted.writeln(trimmedLine);
      
      // 在句子结尾后添加空行
      if (_isEndOfSentence(trimmedLine)) {
        formatted.writeln('');
        lastLineType = 'paragraph_end';
      } else {
        lastLineType = 'paragraph';
      }
    }
    
    return formatted.toString();
  }
  
  /// 判断是否为标题
  static bool _isTitle(String line, int index, List<String> lines) {
    if (line.length < 3 || line.length > 100) return false;
    
    // 已经是标题格式的跳过
    if (line.startsWith('#')) return false;
    
    // 全大写且较短的可能是标题
    if (line == line.toUpperCase() && line.length < 60 && RegExp(r'[A-Z]').hasMatch(line)) {
      return true;
    }
    
    // 以数字开头的章节标题
    if (RegExp(r'^\d+\.?\s+[A-Z]').hasMatch(line)) return true;
    
    // 首字母大写且不以标点结尾的短行
    if (RegExp(r'^[A-Z]').hasMatch(line) && 
        !line.endsWith('.') && 
        !line.endsWith(',') && 
        !line.endsWith(';') &&
        line.length < 80) {
      
      // 检查下一行是否为空行或内容行
      if (index + 1 < lines.length) {
        final nextLine = lines[index + 1].trim();
        if (nextLine.isEmpty || (!_isTitle(nextLine, index + 1, lines) && nextLine.length > 20)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// 判断是否为主标题
  static bool _isMainTitle(String line) {
    // 检测常见的主标题模式
    final mainTitlePatterns = [
      RegExp(r'^第\s*[一二三四五六七八九十\d]+\s*[章节部分]', caseSensitive: false),
      RegExp(r'^chapter\s+\d+', caseSensitive: false),
      RegExp(r'^part\s+[ivx\d]+', caseSensitive: false),
      RegExp(r'^section\s+\d+', caseSensitive: false),
    ];
    
    return mainTitlePatterns.any((pattern) => pattern.hasMatch(line));
  }
  
  /// 判断是否为列表项
  static bool _isListItem(String line) {
    // 已经是列表格式的
    if (line.startsWith('-') || line.startsWith('*') || line.startsWith('+')) return true;
    if (RegExp(r'^\d+\.').hasMatch(line)) return true;
    
    // 以特殊符号开头的
    if (RegExp(r'^[•·▪▫‣⁃→①②③④⑤⑥⑦⑧⑨⑩]').hasMatch(line)) return true;
    
    // 以括号数字或字母开头的
    if (RegExp(r'^\([a-zA-Z0-9]\)').hasMatch(line)) return true;
    
    return false;
  }
  
  /// 判断是否为表格行
  static bool _isTableRow(String line) {
    // 包含多个制表符或多个空格分隔的内容
    return RegExp(r'\t.*\t|.{5,}\s{3,}.{5,}').hasMatch(line) && 
           !line.contains('  ') && 
           line.split(RegExp(r'\s{2,}')).length >= 3;
  }
  
  /// 判断是否为引用
  static bool _isQuote(String line) {
    return line.startsWith('"') || 
           line.startsWith('"') || 
           line.startsWith('「') ||
           RegExp(r'^[""''「」『』]').hasMatch(line);
  }
  
  /// 判断是否为句子结尾
  static bool _isEndOfSentence(String line) {
    return line.endsWith('.') || 
           line.endsWith('!') || 
           line.endsWith('?') ||
           line.endsWith('。') ||
           line.endsWith('！') ||
           line.endsWith('？');
  }
  
  /// ❌ 生成错误Markdown
  static String _generateErrorMarkdown(String pdfPath, String error) {
    final DateTime now = DateTime.now();
    
    return '''# ❌ PDF转换失败

**文件**: `$pdfPath`

**错误信息**: 
```
$error
```

**时间**: ${now.toString().split('.')[0]}

## 🔧 故障排除

### 常见问题
1. **Poppler未安装**: 请确保已安装poppler工具包
   ```bash
   # macOS
   brew install poppler
   
   # Ubuntu/Debian
   sudo apt-get install poppler-utils
   
   # CentOS/RHEL
   sudo yum install poppler-utils
   ```

2. **文件损坏**: PDF文件可能已损坏或不完整
3. **权限问题**: 文件可能设置了访问限制
4. **格式问题**: PDF使用了不支持的特殊格式

### 解决建议
1. 检查PDF文件是否能正常打开
2. 尝试使用其他PDF阅读器打开
3. 使用专业PDF工具进行转换
4. 联系文档提供方获取其他格式

### 手动命令测试
```bash
# 测试pdftotext命令
pdftotext "$pdfPath" -

# 获取PDF信息
pdfinfo "$pdfPath"

# 转换为图像（如果是扫描PDF）
pdftoppm -png "$pdfPath" output
```

---

*此工具使用Poppler工具包。Poppler是一个功能强大的PDF处理库，被许多应用程序使用。*
''';
  }
}

/// 🚀 主函数 - 演示用法
void main() async {
  const String pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/test-pdf-import-example.pdf';
  const String outputPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/frontend/appflowy_flutter/poppler_output.md';
  
  print('🎯 Poppler PDF转Markdown转换器');
  print('📚 使用工具: Poppler pdftotext');
  print('📁 输入文件: $pdfPath');
  print('📄 输出文件: $outputPath');
  print('');
  
  try {
    final String result = await PopplerPdfConverter.convertPdfToMarkdown(pdfPath);
    
    // 保存结果
    await File(outputPath).writeAsString(result, encoding: utf8);
    
    print('');
    print('🎉 转换完成！');
    print('📄 结果文件: $outputPath');
    print('📊 文档长度: ${result.length} 字符');
    
    // 显示预览
    print('\n📖 内容预览:');
    print('=' * 80);
    final preview = result.length > 1200 ? result.substring(0, 1200) + '\n...' : result;
    print(preview);
    print('=' * 80);
    
  } catch (e) {
    print('❌ 转换失败: $e');
    exit(1);
  }
}
