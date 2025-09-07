import 'dart:io';
import 'dart:typed_data';
import 'lib/plugins/import_page/professional_pdf_processor.dart';
import 'lib/plugins/import_page/advanced_pdf_processor.dart';
import 'lib/plugins/import_page/ocr_pdf_processor.dart';

/// 真实PDF文件测试脚本
/// 使用方法: dart test_real_pdf.dart [PDF文件路径]
Future<void> main(List<String> args) async {
  print('🚀 真实PDF文件处理测试');
  print('=' * 50);
  
  String? pdfPath;
  
  // 检查命令行参数
  if (args.isNotEmpty) {
    pdfPath = args[0];
  } else {
    // 尝试查找当前目录下的PDF文件
    final currentDir = Directory.current;
    final pdfFiles = await currentDir
        .list()
        .where((file) => file.path.toLowerCase().endsWith('.pdf'))
        .toList();
    
    if (pdfFiles.isNotEmpty) {
      pdfPath = pdfFiles.first.path;
      print('📄 自动发现PDF文件: ${pdfPath.split('/').last}');
    }
  }
  
  if (pdfPath == null) {
    print('❌ 未找到PDF文件');
    print('\n使用方法:');
    print('1. dart test_real_pdf.dart /path/to/your/file.pdf');
    print('2. 将PDF文件放在当前目录下，脚本会自动检测');
    return;
  }
  
  final pdfFile = File(pdfPath);
  
  if (!await pdfFile.exists()) {
    print('❌ PDF文件不存在: $pdfPath');
    return;
  }
  
  print('✅ 找到PDF文件: ${pdfFile.path}');
  
  try {
    final bytes = await pdfFile.readAsBytes();
    final fileSize = (bytes.length / 1024).toStringAsFixed(1);
    print('📊 文件大小: ${fileSize} KB');
    print('');
    
    // 测试所有处理器
    final processors = [
      ('🔧 专业PDF处理器', ProfessionalPdfProcessor.processPdfBytes),
      ('🚀 高级PDF处理器', AdvancedPdfProcessor.processPdfBytes),
      ('👁️ OCR PDF处理器', OcrPdfProcessor.processPdfBytes),
    ];
    
    for (final (name, processor) in processors) {
      await _testProcessor(name, processor, bytes);
      print(''); // 空行分隔
    }
    
    print('✅ 所有测试完成！');
    
  } catch (e) {
    print('❌ 读取文件失败: $e');
  }
}

Future<void> _testProcessor(
  String name, 
  Future<String> Function(Uint8List) processor, 
  Uint8List bytes
) async {
  print('🔄 测试 $name...');
  final stopwatch = Stopwatch()..start();
  
  try {
    final result = await processor(bytes);
    stopwatch.stop();
    
    print('✅ $name 成功！');
    print('   ⏱️  处理时间: ${stopwatch.elapsedMilliseconds}ms');
    print('   📊 提取内容长度: ${result.length} 字符');
    
    // 显示内容预览
    final previewLength = 300;
    if (result.length > previewLength) {
      print('   📋 内容预览 (前${previewLength}字符):');
      print('   ${result.substring(0, previewLength)}...');
    } else {
      print('   📋 完整内容:');
      print('   $result');
    }
    
    // 保存结果到文件
    final outputFile = File('output_${name.replaceAll(RegExp(r'[^\w]'), '_')}.md');
    await outputFile.writeAsString(result);
    print('   💾 结果已保存到: ${outputFile.path}');
    
  } catch (e) {
    stopwatch.stop();
    print('❌ $name 失败！');
    print('   ⏱️  处理时间: ${stopwatch.elapsedMilliseconds}ms');
    print('   🚨 错误信息: $e');
  }
}

