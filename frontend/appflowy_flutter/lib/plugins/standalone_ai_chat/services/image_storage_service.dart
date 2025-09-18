import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:appflowy_backend/log.dart';
import '../models/chat_image.dart';

/// 图片存储服务
/// 管理AI聊天中的图片存储、检索和清理
class ImageStorageService {
  static ImageStorageService? _instance;
  static ImageStorageService get instance => _instance ??= ImageStorageService._();
  ImageStorageService._();

  // 存储目录名
  static const String _storageDir = 'ai_chat_images';
  // 图片元数据文件名
  static const String _metadataFileName = 'images_metadata.json';

  // 内存缓存
  final Map<String, ChatImage> _imageCache = {};
  final Map<String, String> _imageMetadata = {};

  Directory? _storageDirectory;

  /// 初始化服务
  Future<void> initialize() async {
    try {
      _storageDirectory = await _getStorageDirectory();
      await _loadImageMetadata();
      Log.info('图片存储服务初始化完成，存储目录: ${_storageDirectory?.path}');
    } catch (e) {
      Log.error('图片存储服务初始化失败: $e');
    }
  }

  /// 保存图片并返回图片ID
  Future<String?> saveImage(ChatImage image) async {
    try {
      if (_storageDirectory == null) {
        await initialize();
      }
      
      if (_storageDirectory == null || !image.hasValidData) {
        return null;
      }

      // 生成文件名
      final fileName = _generateFileName(image);
      final filePath = path.join(_storageDirectory!.path, fileName);

      // 保存图片文件
      Uint8List? imageBytes;
      if (image.bytes != null) {
        imageBytes = image.bytes!;
      } else if (image.filePath != null) {
        final file = File(image.filePath!);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      }

      if (imageBytes == null) {
        Log.error('无法获取图片数据');
        return null;
      }

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // 更新元数据
      _imageMetadata[image.id] = fileName;
      await _saveImageMetadata();

      // 更新缓存
      final savedImage = image.copyWith(
        filePath: filePath,
        bytes: imageBytes,
      );
      _imageCache[image.id] = savedImage;

      Log.info('图片已保存: ${image.id} -> $fileName');
      return image.id;
    } catch (e) {
      Log.error('保存图片失败: $e');
      return null;
    }
  }

  /// 根据ID获取图片
  Future<ChatImage?> getImage(String imageId) async {
    try {
      // 先从缓存获取
      if (_imageCache.containsKey(imageId)) {
        return _imageCache[imageId];
      }

      // 从存储获取
      final fileName = _imageMetadata[imageId];
      if (fileName == null || _storageDirectory == null) {
        return null;
      }

      final filePath = path.join(_storageDirectory!.path, fileName);
      final file = File(filePath);
      
      if (!await file.exists()) {
        // 文件不存在，清除元数据
        _imageMetadata.remove(imageId);
        await _saveImageMetadata();
        return null;
      }

      // 读取文件数据
      final bytes = await file.readAsBytes();
      final image = ChatImage(
        id: imageId,
        filePath: filePath,
        bytes: bytes,
        name: _extractNameFromFileName(fileName),
        fileSize: bytes.length,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(imageId) ?? DateTime.now().millisecondsSinceEpoch,
        ),
        type: ChatImageType.local,
        mimeType: _getMimeTypeFromFileName(fileName),
      );

      // 更新缓存
      _imageCache[imageId] = image;
      return image;
    } catch (e) {
      Log.error('获取图片失败: $e');
      return null;
    }
  }

  /// 删除图片
  Future<bool> deleteImage(String imageId) async {
    try {
      final fileName = _imageMetadata[imageId];
      if (fileName != null && _storageDirectory != null) {
        final filePath = path.join(_storageDirectory!.path, fileName);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 清除元数据和缓存
      _imageMetadata.remove(imageId);
      _imageCache.remove(imageId);
      await _saveImageMetadata();

      Log.info('图片已删除: $imageId');
      return true;
    } catch (e) {
      Log.error('删除图片失败: $e');
      return false;
    }
  }

  /// 获取多个图片
  Future<List<ChatImage>> getImages(List<String> imageIds) async {
    final images = <ChatImage>[];
    for (final imageId in imageIds) {
      final image = await getImage(imageId);
      if (image != null) {
        images.add(image);
      }
    }
    return images;
  }

  /// 清理所有图片
  Future<void> clearAllImages() async {
    try {
      if (_storageDirectory != null && await _storageDirectory!.exists()) {
        // 删除存储目录中的所有文件
        await for (final entity in _storageDirectory!.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      // 清除元数据和缓存
      _imageMetadata.clear();
      _imageCache.clear();
      await _saveImageMetadata();

      Log.info('所有图片已清理');
    } catch (e) {
      Log.error('清理图片失败: $e');
    }
  }

  /// 获取存储统计信息
  Future<ImageStorageStats> getStorageStats() async {
    try {
      int totalImages = _imageMetadata.length;
      int totalSize = 0;
      
      if (_storageDirectory != null && await _storageDirectory!.exists()) {
        await for (final entity in _storageDirectory!.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            totalSize += stat.size;
          }
        }
      }

      return ImageStorageStats(
        totalImages: totalImages,
        totalSizeBytes: totalSize,
      );
    } catch (e) {
      Log.error('获取存储统计失败: $e');
      return const ImageStorageStats(totalImages: 0, totalSizeBytes: 0);
    }
  }

  /// 获取存储目录
  Future<Directory> _getStorageDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storageDir = Directory(path.join(appDir.path, _storageDir));
    
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }
    
    return storageDir;
  }

  /// 生成文件名
  String _generateFileName(ChatImage image) {
    final extension = _getFileExtension(image);
    return '${image.id}$extension';
  }

  /// 获取文件扩展名
  String _getFileExtension(ChatImage image) {
    if (image.name != null && image.name!.contains('.')) {
      return path.extension(image.name!);
    }
    
    if (image.mimeType != null) {
      switch (image.mimeType!) {
        case 'image/jpeg':
          return '.jpg';
        case 'image/png':
          return '.png';
        case 'image/gif':
          return '.gif';
        case 'image/webp':
          return '.webp';
        case 'image/bmp':
          return '.bmp';
        default:
          return '.jpg';
      }
    }
    
    return '.jpg'; // 默认
  }

  /// 从文件名提取原始名称
  String _extractNameFromFileName(String fileName) {
    final nameWithExt = path.basename(fileName);
    final dotIndex = nameWithExt.indexOf('.');
    if (dotIndex > 0) {
      return nameWithExt.substring(0, dotIndex);
    }
    return nameWithExt;
  }

  /// 从文件名获取MIME类型
  String? _getMimeTypeFromFileName(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  /// 加载图片元数据
  Future<void> _loadImageMetadata() async {
    try {
      if (_storageDirectory == null) return;
      
      final metadataFile = File(path.join(_storageDirectory!.path, _metadataFileName));
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _imageMetadata.clear();
        data.forEach((key, value) {
          _imageMetadata[key] = value.toString();
        });
      }
    } catch (e) {
      Log.error('加载图片元数据失败: $e');
    }
  }

  /// 保存图片元数据
  Future<void> _saveImageMetadata() async {
    try {
      if (_storageDirectory == null) return;
      
      final metadataFile = File(path.join(_storageDirectory!.path, _metadataFileName));
      final content = jsonEncode(_imageMetadata);
      await metadataFile.writeAsString(content);
    } catch (e) {
      Log.error('保存图片元数据失败: $e');
    }
  }
}

/// 存储统计信息
class ImageStorageStats {
  final int totalImages;
  final int totalSizeBytes;

  const ImageStorageStats({
    required this.totalImages,
    required this.totalSizeBytes,
  });

  /// 获取友好的大小显示格式
  String get totalSizeFormatted {
    if (totalSizeBytes < 1024) return '${totalSizeBytes}B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)}KB';
    if (totalSizeBytes < 1024 * 1024 * 1024) return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
