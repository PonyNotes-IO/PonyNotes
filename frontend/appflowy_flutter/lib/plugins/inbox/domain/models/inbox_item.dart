class InboxItem {
  final String id;
  final String title;
  final String description;
  final String date; // 显示日期（兼容现有代码）
  final DateTime createdAt; // 创建日期
  final DateTime updatedAt; // 更新日期
  final bool hasImage;
  final String? imageUrl;
  final bool isRead;
  final bool isClipped;
  final bool isStarred;

  const InboxItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.hasImage = false,
    this.imageUrl,
    this.isRead = false,
    this.isClipped = false,
    this.isStarred = false,
  });

  InboxItem copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? hasImage,
    String? imageUrl,
    bool? isRead,
    bool? isClipped,
    bool? isStarred,
  }) {
    return InboxItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      hasImage: hasImage ?? this.hasImage,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      isClipped: isClipped ?? this.isClipped,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
