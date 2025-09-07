import 'dart:io';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy/workspace/application/settings/application_data_storage.dart';
import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:appflowy/startup/startup.dart';

import 'file_library_models.dart';

class FileLibraryService {
  static const String _fileLibraryDir = 'file_library';
  
  /// 获取文件库目录路径
  Future<String> get _fileLibraryPath async {
    final appDataPath = await getIt<ApplicationDataStorage>().getPath();
    return p.join(appDataPath, _fileLibraryDir);
  }

  /// 获取所有文件（包括导入的PDF文件）
  Future<List<FileLibraryItem>> getAllFiles() async {
    final libraryPath = await _fileLibraryPath;
    final directory = Directory(libraryPath);
    
    if (!directory.existsSync()) {
      return _getMockFiles(); // 如果目录不存在，返回模拟数据
    }
    
    final files = <FileLibraryItem>[];
    
    // 扫描文件库目录中的所有文件
    await for (final entity in directory.list()) {
      if (entity is File) {
        final file = await _createFileLibraryItemFromFile(entity);
        if (file != null) {
          files.add(file);
        }
      }
    }
    
    // 添加模拟数据（可选，用于演示）
    files.addAll(_getMockFiles());
    
    // 按创建时间倒序排列
    files.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    
    return files;
  }

  /// 导入PDF文件到文件库
  Future<FileLibraryItem?> importPdfFile() async {
    // 使用文件选择器选择PDF文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    
    if (result == null || result.files.isEmpty) {
      return null; // 用户取消选择
    }
    
    final platformFile = result.files.first;
    if (platformFile.path == null) {
      throw Exception('无法获取文件路径');
    }
    
    final sourceFile = File(platformFile.path!);
    if (!sourceFile.existsSync()) {
      throw Exception('源文件不存在');
    }
    
    // 确保文件库目录存在
    final libraryPath = await _fileLibraryPath;
    final directory = Directory(libraryPath);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    
    // 生成新的文件名（保持原始名称，添加UUID避免冲突）
    final originalName = platformFile.name;
    final extension = p.extension(originalName);
    final nameWithoutExt = p.basenameWithoutExtension(originalName);
    final newFileName = '${nameWithoutExt}_${uuid()}$extension';
    final targetPath = p.join(libraryPath, newFileName);
    
    // 复制文件到文件库
    final targetFile = await sourceFile.copy(targetPath);
    
    // 创建文件库项目
    final fileItem = await _createFileLibraryItemFromFile(targetFile, originalName: originalName);
    
    return fileItem;
  }

  /// 删除文件
  Future<void> deleteFile(String fileId) async {
    final libraryPath = await _fileLibraryPath;
    final directory = Directory(libraryPath);
    
    if (!directory.existsSync()) {
      return;
    }
    
    // 查找并删除对应的文件
    await for (final entity in directory.list()) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        if (fileName.contains(fileId) || fileId.contains(fileName)) {
          await entity.delete();
          break;
        }
      }
    }
  }

  /// 打开PDF文件
  Future<void> openPdfFile(FileLibraryItem item) async {
    if (item.uploadType == FileUploadTypePB.LocalFile) {
      // 本地文件，直接使用系统默认程序打开
      final file = File(item.url);
      if (file.existsSync()) {
        await afLaunchUrlString(item.url);
      } else {
        throw Exception('文件不存在：${item.url}');
      }
    } else {
      // 网络文件，使用浏览器打开
      await afLaunchUrlString(item.url);
    }
  }

  /// 从文件创建FileLibraryItem
  Future<FileLibraryItem?> _createFileLibraryItemFromFile(File file, {String? originalName}) async {
    try {
      final fileName = originalName ?? p.basename(file.path);
      final extension = p.extension(fileName).toLowerCase();
      final stat = await file.stat();
      
      // 根据扩展名确定文件类型
      MediaFileTypePB fileType;
      switch (extension) {
        case '.pdf':
          fileType = MediaFileTypePB.Document;
          break;
        case '.jpg':
        case '.jpeg':
        case '.png':
        case '.gif':
        case '.bmp':
        case '.webp':
          fileType = MediaFileTypePB.Image;
          break;
        case '.mp4':
        case '.avi':
        case '.mov':
        case '.wmv':
        case '.flv':
          fileType = MediaFileTypePB.Video;
          break;
        case '.mp3':
        case '.wav':
        case '.aac':
        case '.flac':
          fileType = MediaFileTypePB.Audio;
          break;
        case '.zip':
        case '.rar':
        case '.7z':
        case '.tar':
        case '.gz':
          fileType = MediaFileTypePB.Archive;
          break;
        case '.txt':
        case '.md':
        case '.doc':
        case '.docx':
          fileType = MediaFileTypePB.Text;
          break;
        default:
          fileType = MediaFileTypePB.Other;
      }
      
      return FileLibraryItem(
        id: uuid(),
        name: fileName,
        url: file.path, // 使用本地文件路径
        fileType: fileType,
        uploadType: FileUploadTypePB.LocalFile,
        source: '文件库导入',
        createdAt: stat.changed,
        size: stat.size,
      );
    } catch (e) {
      return null; // 如果处理失败，返回null
    }
  }

  /// 获取模拟文件数据
  List<FileLibraryItem> _getMockFiles() {
    return [
      FileLibraryItem(
        id: '1',
        name: 'example-image.jpg',
        url: 'https://picsum.photos/200/300',
        fileType: MediaFileTypePB.Image,
        uploadType: FileUploadTypePB.NetworkFile,
        source: '示例数据库',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        size: 1024 * 1024, // 1MB
      ),
      FileLibraryItem(
        id: '2',
        name: 'document.pdf',
        url: 'https://example.com/document.pdf',
        fileType: MediaFileTypePB.Document,
        uploadType: FileUploadTypePB.CloudFile,
        source: '项目文档',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        size: 2048 * 1024, // 2MB
      ),
      FileLibraryItem(
        id: '3',
        name: 'audio-sample.mp3',
        url: 'https://example.com/audio.mp3',
        fileType: MediaFileTypePB.Audio,
        uploadType: FileUploadTypePB.LocalFile,
        source: '音频库',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        size: 5120 * 1024, // 5MB
      ),
      FileLibraryItem(
        id: '4',
        name: 'video-demo.mp4',
        url: 'https://example.com/video.mp4',
        fileType: MediaFileTypePB.Video,
        uploadType: FileUploadTypePB.CloudFile,
        source: '视频集合',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        size: 10240 * 1024, // 10MB
      ),
      FileLibraryItem(
        id: '5',
        name: 'archive.zip',
        url: 'https://example.com/archive.zip',
        fileType: MediaFileTypePB.Archive,
        uploadType: FileUploadTypePB.LocalFile,
        source: '备份文件',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        size: 15360 * 1024, // 15MB
      ),
      FileLibraryItem(
        id: '6',
        name: 'notes.txt',
        url: 'https://example.com/notes.txt',
        fileType: MediaFileTypePB.Text,
        uploadType: FileUploadTypePB.NetworkFile,
        source: '笔记本',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        size: 1024, // 1KB
      ),
    ];
  }
} 