import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';

enum FileLibraryCategory {
  all,
  image,
  document,
  audio,
  video,
  archive,
  text,
  other,
}

extension FileLibraryCategoryExtension on FileLibraryCategory {
  String get displayName {
    switch (this) {
      case FileLibraryCategory.all:
        return '全部文件';
      case FileLibraryCategory.image:
        return '图片文件';
      case FileLibraryCategory.document:
        return '文档文件';
      case FileLibraryCategory.audio:
        return '音频文件';
      case FileLibraryCategory.video:
        return '视频文件';
      case FileLibraryCategory.archive:
        return '压缩文件';
      case FileLibraryCategory.text:
        return '文本文件';
      case FileLibraryCategory.other:
        return '其他文件';
    }
  }

  bool matchesFileType(MediaFileTypePB fileType) {
    switch (this) {
      case FileLibraryCategory.all:
        return true;
      case FileLibraryCategory.image:
        return fileType == MediaFileTypePB.Image;
      case FileLibraryCategory.document:
        return fileType == MediaFileTypePB.Document;
      case FileLibraryCategory.audio:
        return fileType == MediaFileTypePB.Audio;
      case FileLibraryCategory.video:
        return fileType == MediaFileTypePB.Video;
      case FileLibraryCategory.archive:
        return fileType == MediaFileTypePB.Archive;
      case FileLibraryCategory.text:
        return fileType == MediaFileTypePB.Text;
      case FileLibraryCategory.other:
        return fileType == MediaFileTypePB.Other;
    }
  }
}

class FileLibraryItem {
  final String id;
  final String name;
  final String url;
  final MediaFileTypePB fileType;
  final FileUploadTypePB uploadType;
  final String source; // 来源：哪个数据库或文档
  final DateTime? createdAt;
  final int? size;

  const FileLibraryItem({
    required this.id,
    required this.name,
    required this.url,
    required this.fileType,
    required this.uploadType,
    required this.source,
    this.createdAt,
    this.size,
  });

  factory FileLibraryItem.fromMediaFile(
    MediaFilePB mediaFile,
    String source,
  ) {
    return FileLibraryItem(
      id: mediaFile.id,
      name: mediaFile.name,
      url: mediaFile.url,
      fileType: mediaFile.fileType,
      uploadType: mediaFile.uploadType,
      source: source,
    );
  }
} 