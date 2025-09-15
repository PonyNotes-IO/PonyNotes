import 'package:flutter/material.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_ui/appflowy_ui.dart';

class InboxSearchBar extends StatefulWidget {
  const InboxSearchBar({
    super.key,
    required this.onChanged,
  });

  final Function(String) onChanged;

  @override
  State<InboxSearchBar> createState() => _InboxSearchBarState();
}

class _InboxSearchBarState extends State<InboxSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.backgroundColorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.borderColorScheme.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 搜索图标
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: FlowySvg(
              FlowySvgs.search_s,
              size: const Size.square(16),
              color: theme.iconColorScheme.secondary,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
              decoration: InputDecoration(
                hintText: '在收件箱搜索',
                hintStyle: theme.textStyle.body.standard(
                  color: theme.textColorScheme.tertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {});
                widget.onChanged(value);
              },
            ),
          ),
          // 清除按钮
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FlowyIconButton(
                icon: FlowySvg(
                  FlowySvgs.m_app_bar_close_s,
                  size: const Size.square(16),
                  color: theme.iconColorScheme.tertiary,
                ),
                width: 24,
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
            ),
        ],
      ),
    );
  }
} 