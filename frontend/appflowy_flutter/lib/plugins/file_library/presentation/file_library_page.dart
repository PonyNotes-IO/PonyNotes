import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:intl/intl.dart';

class FileLibraryPage extends StatefulWidget {
  const FileLibraryPage({super.key});

  @override
  State<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends State<FileLibraryPage> {
  String _selectedCategory = '全部文件';
  String _sortBy = '添加日期';

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  child: const Row(
                    children: [
                      Text(
                        '文件库',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
    );
  }

  Widget _buildCategoryList() {
    final categories = [
      {'name': '全部文件', 'icon': FlowySvgs.dl_folder_s, 'count': 0},
      {'name': '图片文件', 'icon': FlowySvgs.dl_image_s, 'count': 0},
      {'name': '文档文件', 'icon': FlowySvgs.dl_document_s, 'count': 0},
      {'name': '音频文件', 'icon': FlowySvgs.dl_audio_s, 'count': 0},
      {'name': '视频文件', 'icon': FlowySvgs.dl_video_s, 'count': 0},
    ];

    final cloudCategories = [
      {'name': '百度云盘', 'icon': FlowySvgs.icon_document_s, 'count': 0},
      {'name': '百度云盘', 'icon': FlowySvgs.icon_document_s, 'count': 0},
      {'name': '坚果云云盘', 'icon': FlowySvgs.icon_document_s, 'count': 0},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 本地文件分类
        ...categories.map((category) => _buildCategoryItem(
          category['name'] as String,
          category['icon'] as FlowySvgData,
          category['count'] as int,
        )),
        // 分隔线
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(height: 1),
        ),
        // 云盘分类
        ...cloudCategories.map((category) => _buildCategoryItem(
          category['name'] as String,
          category['icon'] as FlowySvgData,
          category['count'] as int,
        )),
      ],
    );
  }

  Widget _buildCategoryItem(String name, FlowySvgData icon, int count) {
    final isSelected = _selectedCategory == name;
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
            _selectedCategory = name;
          });
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
            _selectedCategory,
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
    // 模拟文件数据
    final files = [
      {
        'name': '7728322438 BA7AA195-323F-4AC9-B9CC-13D702D7DE04.mov',
        'date': '2025/06/29',
        'size': '8.4MB',
        'duration': '00:04',
        'type': 'video',
      },
      {
        'name': '7728322438 BA7AA195-323F-4AC9-B9CC-13D702D7DE04.mov',
        'date': '2025/06/29',
        'size': '8.4MB',
        'duration': '00:04',
        'type': 'video',
      },
      {
        'name': '7728322438 BA7AA195-323F-4AC9-B9CC-13D702D7DE04.mov',
        'date': '2025/06/29',
        'size': '8.4MB',
        'duration': '00:04',
        'type': 'video',
      },
      {
        'name': '7728322438 BA7AA195-323F-4AC9-B9CC-13D702D7DE04.mov',
        'date': '2025/06/29',
        'size': '8.4MB',
        'duration': '00:04',
        'type': 'video',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileItem(file);
      },
    );
  }

  Widget _buildFileItem(Map<String, String> file) {
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
      child: Row(
        children: [
          // 文件缩略图/图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
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
                  file['name']!,
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
                      file['date']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      file['size']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      file['duration']!,
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
              // TODO: 处理文件操作
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('打开')),
              const PopupMenuItem(value: 'download', child: Text('下载')),
              const PopupMenuItem(value: 'rename', child: Text('重命名')),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
            child: const Icon(
              Icons.more_horiz,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
} 