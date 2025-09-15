enum SortOption {
  updatedDate('更新日期'),
  createdDate('创建日期'),
  title('标题名称'),
  priority('重要性');

  const SortOption(this.displayName);
  
  final String displayName;
}
