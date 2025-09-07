import 'dart:io';
import 'lib/plugins/import_page/advanced_pdf_processor_v3.dart';

/// 测试字符解码功能
void main() async {
  print('🧪 字符解码功能测试');
  print('======================================================================');
  
  final pdfPath = 'test-pdf-import-example.pdf';
  
  // 检查PDF文件是否存在
  final pdfFile = File(pdfPath);
  if (!await pdfFile.exists()) {
    print('❌ PDF文件不存在: $pdfPath');
    return;
  }
  
  print('✅ 找到PDF文件: $pdfPath');
  final fileSize = await pdfFile.length();
  print('📊 文件大小: ${(fileSize / 1024).toStringAsFixed(1)} KB');
  
  // 验证PDF文件
  final bytes = await pdfFile.readAsBytes();
  final header = String.fromCharCodes(bytes.take(8).toList());
  print('📄 文件头: $header');
  
  if (!header.startsWith('%PDF')) {
    print('❌ 不是有效的PDF文件');
    return;
  }
  
  print('✅ 有效的PDF文件: $header');
  print('');
  
  print('🔧 启动高级PDF处理器 v3.0...');
  print('==================================================');
  
  try {
    // 处理PDF
    final result = await AdvancedPdfProcessorV3.processPdfFile(pdfPath);
    
    if (result['success']) {
      final content = result['content'] as String;
      final stats = result['stats'] as Map<String, dynamic>;
      final processingTime = result['processingTime'] as int;
      
      print('✅ 处理成功！');
      print('⏱️  处理时间: ${processingTime}ms');
      print('📊 内容长度: ${content.length} 字符');
      print('🎯 质量评分: ${stats['qualityScore']}/100 (${stats['qualityLevel']})');
      print('📈 流对象统计: ${stats['processedStreams']}/${stats['totalStreams']} 个包含文本');
      print('');
      
      // 显示文本分析
      if (stats.containsKey('textAnalysis')) {
        final analysis = stats['textAnalysis'] as Map<String, dynamic>;
        print('📈 内容分析:');
        print('----------------------------------------');
        print('总行数: ${analysis['lineCount']}');
        print('非空行数: ${analysis['nonEmptyLineCount']}');
        print('段落数量: ${analysis['paragraphCount']}');
        print('句子数量: ${analysis['sentenceCount']}');
        print('单词数量: ${analysis['wordCount']}');
        print('');
        
        if (analysis.containsKey('characterStats')) {
          final charStats = analysis['characterStats'] as Map<String, int>;
          print('字符统计:');
          print('中文字符: ${charStats['chinese']}');
          print('英文字符: ${charStats['english']}');
          print('数字: ${charStats['numbers']}');
          print('标点符号: ${charStats['punctuation']}');
          print('空白字符: ${charStats['whitespace']}');
          print('其他字符: ${charStats['other']}');
        }
        
        print('');
        print('质量评估:');
        String qualityEmoji = _getQualityEmoji(analysis['qualityLevel']);
        print('$qualityEmoji ${analysis['qualityLevel']} - 可读性比例: ${(analysis['readabilityRatio'] * 100).toStringAsFixed(1)}%');
      }
      
      print('');
      
      // 保存结果到文件
      final outputFile = File('decoded_pdf_result.md');
      final output = StringBuffer();
      
      output.writeln('# PDF字符解码结果');
      output.writeln('');
      output.writeln('## 处理信息');
      output.writeln('- 文件: $pdfPath');
      output.writeln('- 处理时间: ${processingTime}ms');
      output.writeln('- 内容长度: ${content.length} 字符');
      output.writeln('- 质量评分: ${stats['qualityScore']}/100 (${stats['qualityLevel']})');
      output.writeln('- 成功处理: ${stats['processedStreams']}/${stats['totalStreams']} 个流对象');
      output.writeln('');
      
      if (stats.containsKey('textAnalysis')) {
        final analysis = stats['textAnalysis'] as Map<String, dynamic>;
        output.writeln('## 文本分析');
        output.writeln('- 行数: ${analysis['lineCount']}');
        output.writeln('- 段落数: ${analysis['paragraphCount']}');
        output.writeln('- 句子数: ${analysis['sentenceCount']}');
        output.writeln('- 单词数: ${analysis['wordCount']}');
        output.writeln('- 可读性: ${(analysis['readabilityRatio'] * 100).toStringAsFixed(1)}%');
        output.writeln('');
      }
      
      output.writeln('## 提取的文本内容');
      output.writeln('');
      output.writeln(content);
      
      await outputFile.writeAsString(output.toString());
      print('💾 完整结果已保存到: decoded_pdf_result.md');
      print('');
      
      // 显示内容预览
      print('📋 内容预览:');
      print('============================================================');
      final preview = content.length > 800 ? content.substring(0, 800) + '...' : content;
      print(preview);
      print('');
      print('(显示前${preview.length}字符，完整内容已保存到文件)');
      print('============================================================');
      
    } else {
      print('❌ 处理失败: ${result['error']}');
    }
    
  } catch (e) {
    print('❌ 测试失败: $e');
  }
}

String _getQualityEmoji(String qualityLevel) {
  switch (qualityLevel) {
    case '优秀': return '🟢';
    case '良好': return '🟡';
    case '一般': return '🟠';
    case '较差': return '🔴';
    case '很差': return '⚫';
    default: return '❓';
  }
}

