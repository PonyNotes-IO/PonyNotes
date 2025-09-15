import 'package:flutter/material.dart';
import 'package:appflowy/plugins/inbox/domain/models/inbox_item.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra/size.dart';

class InboxDocumentView extends StatelessWidget {
  const InboxDocumentView({
    super.key,
    required this.item,
  });

  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文档头部
          _buildDocumentHeader(context),
          const SizedBox(height: 24),
          // 文档内容
          Expanded(
            child: _buildDocumentContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        FlowyText(
          item.title,
          fontSize: FontSizes.s24,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(height: 8),
        // 元信息
        Wrap(
          spacing: 16,
          children: [
            _buildMetaInfo(
              context,
              '来源',
              item.source.isNotEmpty ? item.source : '未知',
            ),
            _buildMetaInfo(
              context,
              '创建时间',
              _formatDateTime(item.createdAt),
            ),
            _buildMetaInfo(
              context,
              '更新时间',
              _formatDateTime(item.updatedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 标签
        if (item.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: item.tags.map((tag) => _buildTag(context, tag)).toList(),
          ),
      ],
    );
  }

  Widget _buildMetaInfo(BuildContext context, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyText(
          '$label: ',
          fontSize: FontSizes.s12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        FlowyText(
          value,
          fontSize: FontSizes.s12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: FlowyText(
        tag,
        fontSize: FontSizes.s11,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildDocumentContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述
            if (item.description.isNotEmpty) ...[
              FlowyText(
                '摘要',
                fontSize: FontSizes.s16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              FlowyText(
                item.description,
                fontSize: FontSizes.s14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                maxLines: null,
              ),
              const SizedBox(height: 24),
            ],
            // 内容
            FlowyText(
              '内容',
              fontSize: FontSizes.s16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            FlowyText(
              item.content,
              fontSize: FontSizes.s14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              maxLines: null,
              lineHeight: 1.6,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
} 