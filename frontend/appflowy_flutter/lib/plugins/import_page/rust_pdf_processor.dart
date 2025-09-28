import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:appflowy_backend/log.dart';

/// Rust-powered PDF processor using pdf-to-markdown library
class RustPdfProcessor {
  
  /// Process PDF file using Rust backend
  static Future<String> processPdfBytes(File pdfFile) async {
    try {
      Log.info('Starting Rust-powered PDF processing with pdf-to-markdown library...');

      // 调用Rust PDF处理器
      final markdown = await _callRustPdfProcessor(pdfFile.path);
      
      Log.info('Rust PDF processing completed, markdown length: ${markdown.length}');
      return markdown;
      
    } catch (e) {
      Log.error('Rust PDF processing failed: $e');
      throw Exception('Failed to process PDF with Rust processor: $e');
    }
  }
  
  /// 调用Rust PDF处理器
  static Future<String> _callRustPdfProcessor(String pdfPath) async {
    try {
      // 检查Rust处理器是否存在
      final processorExists = await _checkRustProcessorExists();
      if (!processorExists) {
        throw Exception('Rust processor not found. Please build it first using: cargo build --release');
      }
      
      // 构建Rust处理器路径
      final rustProcessorPath = _getRustProcessorPath();
      Log.info('Using Rust processor: $rustProcessorPath');
      Log.info('Processing PDF: $pdfPath');
      
      // 检查PDF文件是否存在
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF file not found: $pdfPath');
      }
      
      // 执行Rust PDF处理器
      final result = await Process.run(
        rustProcessorPath,
        [pdfPath],
        workingDirectory: '/Users/dongli/work/PonyNotes/frontend/rust-lib',
      );
      
      Log.info('Rust processor exit code: ${result.exitCode}');
      if (result.stderr.isNotEmpty) {
        Log.warn('Rust processor stderr: ${result.stderr}');
      }
      
      if (result.exitCode != 0) {
        Log.error('Rust processor failed with exit code: ${result.exitCode}');
        Log.error('Error output: ${result.stderr}');
        throw Exception('Rust PDF processor failed: ${result.stderr}');
      }
      
      // 直接使用stdout输出
      final markdown = result.stdout;
      Log.info('Rust processor output length: ${markdown.length} characters');
      
      return markdown;
      
    } catch (e) {
      Log.error('Failed to call Rust PDF processor: $e');
      throw Exception('Rust PDF processor execution failed: $e');
    }
  }
  
  /// 获取Rust处理器路径
  static String _getRustProcessorPath() {
    // 根据平台返回相应的Rust处理器路径
    if (Platform.isWindows) {
      return r'C:\Users\dongli\work\PonyNotes\frontend\rust-lib\target\release\pdf-processor.exe';
    } else if (Platform.isMacOS) {
      return '/Users/dongli/work/PonyNotes/frontend/rust-lib/target/release/pdf-processor';
    } else if (Platform.isLinux) {
      return '/Users/dongli/work/PonyNotes/frontend/rust-lib/target/release/pdf-processor';
    } else {
      throw UnsupportedError('Unsupported platform for Rust PDF processor');
    }
  }
  
  /// 检查Rust处理器是否存在
  static Future<bool> _checkRustProcessorExists() async {
    try {
      final processorPath = _getRustProcessorPath();
      final file = File(processorPath);
      return await file.exists();
    } catch (e) {
      Log.error('Failed to check Rust processor existence: $e');
      return false;
    }
  }
  
  /// 构建Rust处理器（如果需要）
  static Future<void> buildRustProcessor() async {
    try {
      Log.info('Building Rust PDF processor...');
      
      final result = await Process.run(
        'cargo',
        ['build', '--release', '--package', 'pdf-processor'],
        workingDirectory: '/Users/dongli/work/PonyNotes/frontend/rust-lib',
      );
      
      if (result.exitCode != 0) {
        Log.error('Failed to build Rust processor: ${result.stderr}');
        throw Exception('Rust processor build failed: ${result.stderr}');
      }
      
      Log.info('Rust PDF processor built successfully');
      
    } catch (e) {
      Log.error('Failed to build Rust processor: $e');
      throw Exception('Rust processor build failed: $e');
    }
  }
  
  /// 检查Rust处理器是否可用
  static Future<bool> isRustProcessorAvailable() async {
    try {
      return await _checkRustProcessorExists();
    } catch (e) {
      Log.error('Failed to check Rust processor availability: $e');
      return false;
    }
  }
}