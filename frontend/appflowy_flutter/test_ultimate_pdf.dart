import 'dart:io';
import 'lib/plugins/import_page/ultimate_pdf_processor.dart';

/// 测试终极PDF处理器
Future<void> main(List<String> args) async {
  print('🚀 终极PDF处理器测试');
  print('=' * 70);
  
  String? pdfPath;
  
  // 检查命令行参数
  if (args.isNotEmpty) {
    pdfPath = args[0];
  } else {
    // 使用默认测试文件
    pdfPath = '/Users/kuncao/github.com/PonyNotes-IO/PonyNotes/test-pdf-import-example.pdf';
  }
  
  final pdfFile = File(pdfPath);
  
  if (!await pdfFile.exists()) {
    print('❌ PDF文件不存在: $pdfPath');
    print('\n使用方法:');
    print('dart test_ultimate_pdf.dart [PDF文件路径]');
    return;
  }
  
  print('✅ 找到PDF文件: ${pdfFile.path.split('/').last}');
  
  try {
    final bytes = await pdfFile.readAsBytes();
    final fileSize = (bytes.length / 1024).toStringAsFixed(1);
    print('📊 文件大小: ${fileSize} KB');
    print('📄 字节长度: ${bytes.length}');
    print('');
    
    // 验证PDF文件格式
    if (bytes.length >= 4) {
      final header = String.fromCharCodes(bytes.take(4));
      if (header == '%PDF') {
        final version = String.fromCharCodes(bytes.take(8));
        print('✅ 有效的PDF文件: $version');
      } else {
        print('⚠️ 文件头不是PDF格式: $header');
      }
    }
    
    print('');
    print('🔧 启动终极PDF处理器...');
    print('=' * 50);
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await UltimatePdfProcessor.processPdfBytes(bytes);
      stopwatch.stop();
      
      print('');
      print('✅ 处理完成！');
      print('⏱️  总处理时间: ${stopwatch.elapsedMilliseconds}ms');
      print('📊 输出内容长度: ${result.length} 字符');
      print('');
      
      // 分析结果质量
      _analyzeResultQuality(result);
      
      // 显示内容预览
      final previewLength = 800;
      print('📋 内容预览:');
      print('=' * 60);
      if (result.length > previewLength) {
        print('${result.substring(0, previewLength)}...');
        print('');
        print('(显示前${previewLength}字符，完整内容已保存到文件)');
      } else {
        print(result);
      }
      print('=' * 60);
      
      // 保存结果到文件
      final outputFile = File('ultimate_pdf_result.md');
      await outputFile.writeAsString(result);
      print('💾 完整结果已保存到: ${outputFile.path}');
      
    } catch (e) {
      stopwatch.stop();
      print('❌ 处理失败！');
      print('⏱️  处理时间: ${stopwatch.elapsedMilliseconds}ms');
      print('🚨 错误信息: $e');
      print('📍 错误堆栈: ${StackTrace.current}');
    }
    
  } catch (e) {
    print('❌ 读取文件失败: $e');
  }
}

/// 分析结果质量
void _analyzeResultQuality(String result) {
  print('📈 结果质量分析:');
  print('-' * 40);
  
  final lines = result.split('\n');
  final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;
  
  print('总行数: ${lines.length}');
  print('非空行数: $nonEmptyLines');
  
  // 统计字符类型
  final chineseChars = RegExp(r'[\u4e00-\u9fff]').allMatches(result).length;
  final englishWords = RegExp(r'\b[a-zA-Z]+\b').allMatches(result).length;
  final numbers = RegExp(r'\d+').allMatches(result).length;
  final punctuation = RegExp(r'[.,;:!?()[\]{}"/-]').allMatches(result).length;
  
  print('中文字符: $chineseChars');
  print('英文单词: $englishWords');
  print('数字: $numbers');
  print('标点符号: $punctuation');
  
  // 内容质量评估
  final totalChars = result.length;
  final readableChars = chineseChars + englishWords * 4 + numbers; // 估算可读字符
  final readableRatio = totalChars > 0 ? (readableChars / totalChars) : 0.0;
  
  print('');
  print('质量评估:');
  if (readableRatio > 0.7) {
    print('🟢 优秀 - 文本提取质量很高');
  } else if (readableRatio > 0.4) {
    print('🟡 良好 - 文本提取质量中等');
  } else if (readableRatio > 0.1) {
    print('🟠 一般 - 文本提取质量较低');
  } else {
    print('🔴 较差 - 文本提取可能失败');
  }
  print('可读性比例: ${(readableRatio * 100).toStringAsFixed(1)}%');
  
  // 特殊内容检测
  final specialFeatures = <String>[];
  
  if (result.contains('表格') || result.contains('Table') || result.contains('|')) {
    specialFeatures.add('表格');
  }
  
  if (result.contains('图') || result.contains('Figure') || result.contains('图像')) {
    specialFeatures.add('图像');
  }
  
  if (RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}').hasMatch(result)) {
    specialFeatures.add('日期');
  }
  
  if (result.contains('http') || result.contains('www.')) {
    specialFeatures.add('链接');
  }
  
  if (result.contains('@') && result.contains('.')) {
    specialFeatures.add('邮箱');
  }
  
  if (specialFeatures.isNotEmpty) {
    print('');
    print('检测到的特殊内容: ${specialFeatures.join(", ")}');
  }
  
  // 结构分析
  final headers = RegExp(r'^##\s+').allMatches(result, 0).length;
  final paragraphs = result.split('\n\n').length;
  
  print('');
  print('结构信息:');
  print('标题数量: $headers');
  print('段落数量: $paragraphs');
  
  print('-' * 40);
}

