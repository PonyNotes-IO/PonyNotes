import 'dart:io';
import 'dart:typed_data';
import 'lib/plugins/import_page/advanced_pdf_processor.dart';

void main() async {
  print('🚀 高级PDF处理器测试');
  print('=' * 70);
  
  try {
    // 查找PDF测试文件
    final testFile = File('test-pdf-import-example.pdf');
    
    if (!testFile.existsSync()) {
      print('❌ 找不到测试文件: test-pdf-import-example.pdf');
      print('请确保测试文件在当前目录中');
      return;
    }
    
    print('✅ 找到PDF文件: ${testFile.path}');
    
    // 读取文件
    final pdfBytes = await testFile.readAsBytes();
    print('📊 文件大小: ${(pdfBytes.length / 1024).toStringAsFixed(1)} KB');
    print('📄 字节长度: ${pdfBytes.length}');
    print('');
    
    // 验证PDF格式
    final header = String.fromCharCodes(pdfBytes.take(10));
    if (header.startsWith('%PDF-')) {
      print('✅ 有效的PDF文件: ${header.substring(0, 8)}');
    } else {
      print('❌ 无效的PDF文件格式');
      return;
    }
    print('');
    
    // 运行高级PDF处理器
    print('🔧 启动高级PDF处理器...');
    print('=' * 50);
    
    final result = await AdvancedPdfProcessor.processPdf(pdfBytes);
    
    print('');
    print('=' * 50);
    
    if (result.success) {
      print('✅ 处理成功！');
      print('⏱️  处理时间: ${result.processingTime}ms');
      print('📊 内容长度: ${result.extractedText.length} 字符');
      
      if (result.qualityScore != null) {
        print('🎯 质量评分: ${result.qualityScore!.toStringAsFixed(1)}/100 (${result.qualityDescription})');
      }
      
      if (result.streamCount != null && result.textStreams != null) {
        print('📈 流对象统计: ${result.textStreams}/${result.streamCount} 个包含文本');
      }
      
      // 分析提取的内容
      print('');
      print('📈 内容分析:');
      print('-' * 40);
      _analyzeExtractedContent(result.extractedText);
      
      // 保存结果
      final outputFile = File('advanced_pdf_result.md');
      await outputFile.writeAsString(result.generateReport());
      print('');
      print('💾 完整结果已保存到: ${outputFile.path}');
      
      // 显示内容预览
      print('');
      print('📋 内容预览:');
      print('=' * 60);
      final preview = result.extractedText.length > 800 
          ? '${result.extractedText.substring(0, 800)}...' 
          : result.extractedText;
      print(preview);
      print('');
      print('(显示前800字符，完整内容已保存到文件)');
      print('=' * 60);
      
    } else {
      print('❌ 处理失败');
      if (result.errorMessage != null) {
        print('错误信息: ${result.errorMessage}');
      }
    }
    
  } catch (e) {
    print('❌ 测试过程中发生错误: $e');
  }
}

void _analyzeExtractedContent(String content) {
  if (content.isEmpty) {
    print('⚠️  未提取到任何内容');
    return;
  }
  
  final lines = content.split('\n');
  final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;
  
  // 字符统计
  final chineseChars = RegExp(r'[\u4e00-\u9fff]').allMatches(content).length;
  final englishWords = RegExp(r'\b[a-zA-Z]+\b').allMatches(content).length;
  final numbers = RegExp(r'\d+').allMatches(content).length;
  final punctuation = RegExp(r'[.,;:!?()\[\]"`~@#\$%^&*+=<>|\\/-]').allMatches(content).length;
  
  print('总行数: ${lines.length}');
  print('非空行数: $nonEmptyLines');
  print('中文字符: $chineseChars');
  print('英文单词: $englishWords');
  print('数字: $numbers');
  print('标点符号: $punctuation');
  
  // 质量评估
  final totalChars = content.length;
  final readableChars = chineseChars + englishWords * 5 + numbers; // 粗略估算
  final readabilityRatio = totalChars > 0 ? (readableChars / totalChars) : 0.0;
  
  print('');
  print('质量评估:');
  if (readabilityRatio > 0.8) {
    print('🟢 优秀 - 文本提取质量很高');
  } else if (readabilityRatio > 0.6) {
    print('🟡 良好 - 文本提取质量中等');
  } else if (readabilityRatio > 0.3) {
    print('🟠 一般 - 文本提取质量较低');
  } else {
    print('🔴 较差 - 文本提取质量很低');
  }
  
  print('可读性比例: ${(readabilityRatio * 100).toStringAsFixed(1)}%');
  
  // 检测特殊内容
  final specialContent = <String>[];
  if (content.contains(RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'))) {
    specialContent.add('日期');
  }
  if (content.contains(RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}'))) {
    specialContent.add('邮箱');
  }
  if (content.contains(RegExp(r'https?://[^\s]+'))) {
    specialContent.add('网址');
  }
  if (content.contains(RegExp(r'表\s*\d+|Table\s*\d+', caseSensitive: false))) {
    specialContent.add('表格');
  }
  if (content.contains(RegExp(r'图\s*\d+|Figure\s*\d+', caseSensitive: false))) {
    specialContent.add('图像');
  }
  
  if (specialContent.isNotEmpty) {
    print('');
    print('检测到的特殊内容: ${specialContent.join(', ')}');
  }
  
  // 结构分析
  final paragraphs = content.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;
  final sentences = content.split(RegExp(r'[.!?。！？]')).where((s) => s.trim().length > 5).length;
  
  print('');
  print('结构信息:');
  print('段落数量: $paragraphs');
  print('句子数量: $sentences');
}
