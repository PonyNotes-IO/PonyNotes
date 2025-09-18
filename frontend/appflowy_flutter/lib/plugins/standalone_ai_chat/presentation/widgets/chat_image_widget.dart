import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/chat_image.dart';

/// 聊天中的图片显示组件
class ChatImageWidget extends StatelessWidget {
  const ChatImageWidget({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.onTap,
    this.onRemove,
    this.showRemoveButton = false,
  });

  final ChatImage image;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 图片容器
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            constraints: const BoxConstraints(
              maxWidth: 200,
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildImageContent(),
          ),
        ),
        
        // 删除按钮
        if (showRemoveButton && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

        // 图片信息标签
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
            ),
            child: Row(
              children: [
                _buildTypeIcon(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    image.name ?? '未知图片',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (image.fileSize != null)
                  Text(
                    image.fileSizeFormatted,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建图片内容
  Widget _buildImageContent() {
    Widget imageWidget;

    try {
      if (image.bytes != null) {
        // 从字节数据显示图片
        imageWidget = Image.memory(
          image.bytes!,
          fit: BoxFit.cover,
          errorBuilder: _buildErrorWidget,
        );
      } else if (image.filePath != null) {
        // 从文件路径显示图片
        imageWidget = Image.file(
          File(image.filePath!),
          fit: BoxFit.cover,
          errorBuilder: _buildErrorWidget,
        );
      } else if (image.url != null) {
        // 从网络URL显示图片
        imageWidget = Image.network(
          image.url!,
          fit: BoxFit.cover,
          errorBuilder: _buildErrorWidget,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingWidget(loadingProgress);
          },
        );
      } else {
        // 没有有效数据
        return _buildPlaceholderWidget();
      }

      return imageWidget;
    } catch (e) {
      return _buildPlaceholderWidget();
    }
  }

  /// 构建类型图标
  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor = Colors.white;

    switch (image.type) {
      case ChatImageType.local:
        iconData = Icons.photo;
        break;
      case ChatImageType.clipboard:
        iconData = Icons.content_paste;
        break;
      case ChatImageType.network:
        iconData = Icons.cloud;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 12,
    );
  }

  /// 构建错误组件
  Widget _buildErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return _buildPlaceholderWidget(
      icon: Icons.broken_image,
      text: '图片加载失败',
    );
  }

  /// 构建加载组件
  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
            const SizedBox(height: 8),
            const Text(
              '加载中...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建占位符组件
  Widget _buildPlaceholderWidget({
    IconData icon = Icons.image,
    String text = '无图片数据',
  }) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片预览组件（用于显示选中的图片）
class ChatImagePreview extends StatelessWidget {
  const ChatImagePreview({
    super.key,
    required this.images,
    this.onRemove,
    this.maxDisplayCount = 3,
  });

  final List<ChatImage> images;
  final Function(ChatImage image)? onRemove;
  final int maxDisplayCount;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '已选择的图片：',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 显示图片
              ...images.take(maxDisplayCount).map((image) => ChatImageWidget(
                image: image,
                width: 80,
                height: 80,
                showRemoveButton: true,
                onRemove: onRemove != null ? () => onRemove!(image) : null,
              )),
              
              // 如果还有更多图片，显示计数
              if (images.length > maxDisplayCount)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.more_horiz,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '+${images.length - maxDisplayCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
