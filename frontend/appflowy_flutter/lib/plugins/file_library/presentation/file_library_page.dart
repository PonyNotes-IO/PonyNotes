import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:intl/intl.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pbenum.dart';

import '../application/file_library_bloc.dart';
import '../application/file_library_models.dart';

class FileLibraryPage extends StatefulWidget {
  const FileLibraryPage({super.key});

  @override
  State<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends State<FileLibraryPage> {
  late FileLibraryBloc _bloc;
  FileLibraryCategory _selectedCategory = FileLibraryCategory.all;
  String _sortBy = '添加日期';

  @override
  void initState() {
    super.initState();
    _bloc = FileLibraryBloc();
    _bloc.add(const FileLibraryEvent.started());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<FileLibraryBloc, FileLibraryState>(
        listener: (context, state) {
          // 显示消息提示
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.infoMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.infoMessage!),
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Row(
            children: [
              // 左侧文件分类侧边栏
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  children: [
                    // 顶部标题
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '文件库',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          BlocBuilder<FileLibraryBloc, FileLibraryState>(
                            builder: (context, state) {
                              return FlowyIconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: state.isImporting
                                    ? null
                                    : () {
                                        _bloc.add(const FileLibraryEvent.importPdfFile());
                                      },
                                tooltipText: '导入PDF文件',
                                hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // 分类列表
                    Expanded(
                      child: _buildCategoryList(),
                    ),
                  ],
                ),
              ),
              // 右侧文件列表区域
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return BlocBuilder<FileLibraryBloc, FileLibraryState>(
      builder: (context, state) {
        final categories = [
          {'category': FileLibraryCategory.all, 'name': '全部文件', 'icon': FlowySvgs.dl_folder_s},
          {'category': FileLibraryCategory.image, 'name': '图片文件', 'icon': FlowySvgs.dl_image_s},
          {'category': FileLibraryCategory.document, 'name': '文档文件', 'icon': FlowySvgs.dl_document_s},
          {'category': FileLibraryCategory.audio, 'name': '音频文件', 'icon': FlowySvgs.dl_audio_s},
          {'category': FileLibraryCategory.video, 'name': '视频文件', 'icon': FlowySvgs.dl_video_s},
          {'category': FileLibraryCategory.archive, 'name': '压缩文件', 'icon': FlowySvgs.dl_folder_s},
          {'category': FileLibraryCategory.text, 'name': '文本文件', 'icon': FlowySvgs.icon_document_s},
          {'category': FileLibraryCategory.other, 'name': '其他文件', 'icon': FlowySvgs.dl_folder_s},
        ];

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // 本地文件分类
            ...categories.map((categoryData) {
              final category = categoryData['category'] as FileLibraryCategory;
              final count = state.files.where((file) => category.matchesFileType(file.fileType)).length;
              return _buildCategoryItem(
                category,
                categoryData['name'] as String,
                categoryData['icon'] as FlowySvgData,
                count,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(FileLibraryCategory category, String name, FlowySvgData icon, int count) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              )
            : null,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
          _bloc.add(FileLibraryEvent.categoryChanged(category));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              FlowySvg(
                icon,
                size: const Size.square(16),
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 工具栏
        _buildToolbar(),
        // 文件列表
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            _selectedCategory.displayName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // 排序下拉菜单
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '添加日期', child: Text('添加日期')),
              const PopupMenuItem(value: '修改日期', child: Text('修改日期')),
              const PopupMenuItem(value: '文件名', child: Text('文件名')),
              const PopupMenuItem(value: '文件大小', child: Text('文件大小')),
            ],
            child: Row(
              children: [
                Text(
                  _sortBy,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(width: 4),
                const FlowySvg(
                  FlowySvgs.arrow_down_s,
                  size: Size.square(16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return BlocBuilder<FileLibraryBloc, FileLibraryState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.filteredFiles.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '暂无文件',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '点击左上角的 + 按钮导入PDF文件',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: state.filteredFiles.length,
          itemBuilder: (context, index) {
            final file = state.filteredFiles[index];
            return _buildFileItem(file);
          },
        );
      },
    );
  }

  Widget _buildFileItem(FileLibraryItem file) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          // 双击打开文件
          _bloc.add(FileLibraryEvent.openFile(file));
        },
        child: Row(
          children: [
            // 文件缩略图/图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getFileTypeColor(file.fileType).withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getFileTypeIcon(file.fileType),
                color: _getFileTypeColor(file.fileType),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // 文件信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDate(file.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatFileSize(file.size),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        file.source,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 操作按钮
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'open':
                    _bloc.add(FileLibraryEvent.openFile(file));
                    break;
                  case 'delete':
                    _bloc.add(FileLibraryEvent.deleteFile(file.id));
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'open', child: Text('打开')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
              child: const Icon(
                Icons.more_horiz,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 辅助方法
  IconData _getFileTypeIcon(MediaFileTypePB fileType) {
    switch (fileType) {
      case MediaFileTypePB.Document:
        return Icons.picture_as_pdf;
      case MediaFileTypePB.Image:
        return Icons.image;
      case MediaFileTypePB.Video:
        return Icons.play_arrow;
      case MediaFileTypePB.Audio:
        return Icons.audiotrack;
      case MediaFileTypePB.Archive:
        return Icons.archive;
      case MediaFileTypePB.Text:
        return Icons.description;
      case MediaFileTypePB.Other:
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(MediaFileTypePB fileType) {
    switch (fileType) {
      case MediaFileTypePB.Document:
        return Colors.red;
      case MediaFileTypePB.Image:
        return Colors.blue;
      case MediaFileTypePB.Video:
        return Colors.purple;
      case MediaFileTypePB.Audio:
        return Colors.orange;
      case MediaFileTypePB.Archive:
        return Colors.brown;
      case MediaFileTypePB.Text:
        return Colors.green;
      case MediaFileTypePB.Other:
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _formatFileSize(int? size) {
    if (size == null) return '未知';
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
} 