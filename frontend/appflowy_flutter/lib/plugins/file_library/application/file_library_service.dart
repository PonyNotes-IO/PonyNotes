import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';

import 'file_library_models.dart';

class FileLibraryService {
  /// 获取所有文件（目前返回模拟数据）
  Future<List<FileLibraryItem>> getAllFiles() async {
    // TODO: 实现真实的文件获取逻辑
    // 这里应该查询所有数据库和文档中的媒体文件
    
    await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
    
    return _getMockFiles();
  }

  /// 删除文件
  Future<void> deleteFile(String fileId) async {
    // TODO: 实现真实的文件删除逻辑
    await Future.delayed(const Duration(milliseconds: 200));
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