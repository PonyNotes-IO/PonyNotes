import 'dart:io';
import 'dart:typed_data';

/// AI聊天中的图片消息模型
class ChatImage {
  final String id;
  final String? filePath;
  final Uint8List? bytes;
  final String? url;
  final String? name;
  final int? fileSize;
  final DateTime timestamp;
  final ChatImageType type;
  final String? mimeType;

  const ChatImage({
    required this.id,
    this.filePath,
    this.bytes,
    this.url,
    this.name,
    this.fileSize,
    required this.timestamp,
    required this.type,
    this.mimeType,
  });

  /// 从本地文件创建图片
  static Future<ChatImage> fromFile(File file) async {
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;
    
    return ChatImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: file.path,
      bytes: bytes,
      name: fileName,
      fileSize: bytes.length,
      timestamp: DateTime.now(),
      type: ChatImageType.local,
      mimeType: _getMimeType(fileName),
    );
  }

  /// 从字节数据创建图片
  static ChatImage fromBytes(Uint8List bytes, {String? name}) {
    return ChatImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bytes: bytes,
      name: name ?? 'pasted_image_${DateTime.now().millisecondsSinceEpoch}.png',
      fileSize: bytes.length,
      timestamp: DateTime.now(),
      type: ChatImageType.clipboard,
      mimeType: 'image/png',
    );
  }

  /// 从网络URL创建图片
  static ChatImage fromUrl(String url, {String? name}) {
    return ChatImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      name: name ?? url.split('/').last,
      timestamp: DateTime.now(),
      type: ChatImageType.network,
      mimeType: _getMimeType(url),
    );
  }

  /// 获取图片的显示数据
  /// 返回可用于Image.memory或Image.file的数据
  dynamic get imageData {
    if (bytes != null) return bytes!;
    if (filePath != null) return File(filePath!);
    if (url != null) return url!;
    return null;
  }

  /// 判断是否有有效的图片数据
  bool get hasValidData => 
      bytes != null || filePath != null || url != null;

  /// 获取文件大小的友好显示格式
  String get fileSizeFormatted {
    if (fileSize == null) return '未知';
    
    final size = fileSize!;
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// 复制图片对象
  ChatImage copyWith({
    String? id,
    String? filePath,
    Uint8List? bytes,
    String? url,
    String? name,
    int? fileSize,
    DateTime? timestamp,
    ChatImageType? type,
    String? mimeType,
  }) {
    return ChatImage(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      url: url ?? this.url,
      name: name ?? this.name,
      fileSize: fileSize ?? this.fileSize,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  /// 获取MIME类型
  static String? _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'image/jpeg'; // 默认为JPEG
    }
  }

  @override
  String toString() {
    return 'ChatImage(id: $id, name: $name, type: $type, fileSize: ${fileSizeFormatted})';
  }
}

/// 图片类型枚举
enum ChatImageType {
  local,     // 本地文件
  clipboard, // 剪贴板
  network,   // 网络图片
}

extension ChatImageTypeExtension on ChatImageType {
  String get displayName {
    switch (this) {
      case ChatImageType.local:
        return '本地文件';
      case ChatImageType.clipboard:
        return '剪贴板';
      case ChatImageType.network:
        return '网络图片';
    }
  }
}
