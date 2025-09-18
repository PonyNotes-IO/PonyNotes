import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy_backend/log.dart';
import '../models/chat_image.dart';

/// AI聊天图片服务
/// 处理图片选择、粘贴、上传等功能
class ChatImageService {
  static ChatImageService? _instance;
  static ChatImageService get instance => _instance ??= ChatImageService._();
  ChatImageService._();

  final ImagePicker _imagePicker = ImagePicker();

  /// 支持的图片扩展名
  static const List<String> supportedExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'
  ];

  /// 最大文件大小 (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// 从相册选择图片
  Future<ChatImage?> pickImageFromGallery(BuildContext context) async {
    try {
      // 检查权限
      final hasPermission = await PermissionChecker.checkPhotoPermission(context);
      if (!hasPermission) {
        Log.error('没有相册访问权限');
        return null;
      }

      // 选择图片
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return null;

      // 检查文件大小
      final fileSize = await image.length();
      if (fileSize > maxFileSize) {
        Log.error('图片文件过大: ${fileSize}字节，最大支持${maxFileSize}字节');
        return null;
      }

      // 创建ChatImage对象
      final file = File(image.path);
      return await ChatImage.fromFile(file);
    } catch (e) {
      Log.error('从相册选择图片失败: $e');
      return null;
    }
  }

  /// 从相机拍照
  Future<ChatImage?> takePhoto(BuildContext context) async {
    try {
      // 检查权限
      final hasPermission = await PermissionChecker.checkCameraPermission(context);
      if (!hasPermission) {
        Log.error('没有相机访问权限');
        return null;
      }

      // 拍照
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return null;

      // 检查文件大小
      final fileSize = await image.length();
      if (fileSize > maxFileSize) {
        Log.error('图片文件过大: ${fileSize}字节，最大支持${maxFileSize}字节');
        return null;
      }

      // 创建ChatImage对象
      final file = File(image.path);
      return await ChatImage.fromFile(file);
    } catch (e) {
      Log.error('拍照失败: $e');
      return null;
    }
  }

  /// 从文件系统选择图片
  Future<ChatImage?> pickImageFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false, // 大文件不直接加载到内存
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFile = result.files.first;
      
      // 检查文件大小
      if (pickedFile.size > maxFileSize) {
        Log.error('图片文件过大: ${pickedFile.size}字节，最大支持${maxFileSize}字节');
        return null;
      }

      // 检查文件扩展名
      final extension = pickedFile.extension?.toLowerCase();
      if (extension == null || !supportedExtensions.contains(extension)) {
        Log.error('不支持的图片格式: $extension');
        return null;
      }

      // 创建ChatImage对象
      if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        return await ChatImage.fromFile(file);
      } else if (pickedFile.bytes != null) {
        return ChatImage.fromBytes(
          pickedFile.bytes!,
          name: pickedFile.name,
        );
      }

      return null;
    } catch (e) {
      Log.error('从文件选择图片失败: $e');
      return null;
    }
  }

  /// 从剪贴板粘贴图片
  Future<ChatImage?> pasteImageFromClipboard() async {
    try {
      final clipboardService = ClipboardService();
      final data = await clipboardService.getData();
      
      // 检查是否有图片数据
      if (data.image != null) {
        final (filename, imageBytes) = data.image!;
        if (imageBytes != null) {
          // 检查文件大小
          if (imageBytes.length > maxFileSize) {
            Log.error('剪贴板图片过大: ${imageBytes.length}字节，最大支持${maxFileSize}字节');
            return null;
          }

          return ChatImage.fromBytes(imageBytes);
        }
      }

      // 检查是否是图片URL
      final plainText = data.plainText;
      if (plainText != null && _isImageUrl(plainText)) {
        return ChatImage.fromUrl(plainText);
      }

      return null;
    } catch (e) {
      Log.error('从剪贴板粘贴图片失败: $e');
      return null;
    }
  }

  /// 检查URL是否是图片
  bool _isImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      return supportedExtensions.any((ext) => path.endsWith('.$ext'));
    } catch (e) {
      return false;
    }
  }

  /// 显示图片选择对话框
  Future<ChatImage?> showImagePickerDialog(BuildContext context) async {
    Log.info('显示图片选择对话框');
    final completer = Completer<ChatImage?>();
    
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择图片'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                Log.info('用户点击：从相册选择');
                Navigator.of(dialogContext).pop();
                try {
                  final image = await pickImageFromGallery(context);
                  Log.info('相册选择结果: $image');
                  completer.complete(image);
                } catch (e) {
                  Log.error('相册选择失败: $e');
                  completer.complete(null);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () async {
                Log.info('用户点击：拍照');
                Navigator.of(dialogContext).pop();
                try {
                  final image = await takePhoto(context);
                  Log.info('拍照结果: $image');
                  completer.complete(image);
                } catch (e) {
                  Log.error('拍照失败: $e');
                  completer.complete(null);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('从文件选择'),
              onTap: () async {
                Log.info('用户点击：从文件选择');
                Navigator.of(dialogContext).pop();
                try {
                  final image = await pickImageFromFile();
                  Log.info('文件选择结果: $image');
                  completer.complete(image);
                } catch (e) {
                  Log.error('文件选择失败: $e');
                  completer.complete(null);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('从剪贴板粘贴'),
              onTap: () async {
                Navigator.of(dialogContext).pop();
                try {
                  final image = await pasteImageFromClipboard();
                  completer.complete(image);
                } catch (e) {
                  completer.complete(null);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              completer.complete(null);
            },
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }

  /// 获取图片的base64编码（用于发送给AI）
  Future<String?> getImageBase64(ChatImage image) async {
    try {
      Uint8List? bytes;

      if (image.bytes != null) {
        bytes = image.bytes!;
      } else if (image.filePath != null) {
        final file = File(image.filePath!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes != null) {
        // 将字节数据转换为base64
        final base64String = base64Encode(bytes);
        final mimeType = image.mimeType ?? 'image/jpeg';
        return 'data:$mimeType;base64,$base64String';
      }

      return null;
    } catch (e) {
      Log.error('获取图片base64编码失败: $e');
      return null;
    }
  }

  /// 验证图片是否有效
  bool validateImage(ChatImage image) {
    // 检查是否有数据
    if (!image.hasValidData) return false;

    // 检查文件大小
    if (image.fileSize != null && image.fileSize! > maxFileSize) {
      return false;
    }

    // 检查MIME类型
    final mimeType = image.mimeType;
    if (mimeType != null && !mimeType.startsWith('image/')) {
      return false;
    }

    return true;
  }
}

