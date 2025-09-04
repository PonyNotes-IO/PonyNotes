import 'package:flutter/material.dart';

class InboxClipSection extends StatefulWidget {
  const InboxClipSection({super.key});

  @override
  State<InboxClipSection> createState() => _InboxClipSectionState();
}

class _InboxClipSectionState extends State<InboxClipSection> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0xFFEBEBEB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 剪藏标题
          const Text(
            '剪藏链接为笔记',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 输入框和按钮
          Row(
            children: [
              // URL输入框
              Expanded(
                child: Container(
                  height: 33,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: const Color(0xFFE9E9E9),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAAAAAA),
                    ),
                    decoration: const InputDecoration(
                      hintText: '在此处输入或粘贴网址链接后，点击剪藏',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFAAAAAA),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // 剪藏按钮
              GestureDetector(
                onTap: _handleClip,
                child: Container(
                  height: 33,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF89575),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Center(
                    child: Text(
                      '剪藏',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleClip() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    
    // TODO: 实现剪藏功能
    debugPrint('剪藏链接: $url');
    
    // 清空输入框
    _urlController.clear();
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已剪藏'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
