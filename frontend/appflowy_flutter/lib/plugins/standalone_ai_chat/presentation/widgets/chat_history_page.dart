import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/plugins/standalone_ai_chat/application/standalone_chat_bloc.dart';

/// 聊天历史页面
/// 显示用户的历史聊天记录，支持搜索、删除等操作
class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载聊天历史
  void _loadChatHistory() {
    context.read<StandaloneChatBloc>().add(
      const StandaloneChatEvent.loadChatHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          // 聊天历史列表
          Expanded(
            child: BlocBuilder<StandaloneChatBloc, StandaloneChatState>(
              builder: (context, state) {
                return _buildChatHistoryList(state);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : _buildNewChatFab(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        title: Text('已选择 ${_selectedChatIds.length} 个对话'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedChatIds.clear();
            });
          },
        ),
        actions: [
          if (_selectedChatIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedChats,
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('聊天历史'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // 聚焦搜索框
            FocusScope.of(context).requestFocus(FocusNode());
          },
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('清空所有记录'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('导出聊天记录'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索聊天记录...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  /// 构建聊天历史列表
  Widget _buildChatHistoryList(StandaloneChatState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final chatSessions = _filterChatSessions(state.chatSessions);

    if (chatSessions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: chatSessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = chatSessions[index];
        return _buildChatSessionItem(session);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关聊天记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用不同的关键词搜索',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有聊天记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '开始您的第一次AI对话吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建聊天会话项
  Widget _buildChatSessionItem(ChatSession session) {
    final isSelected = _selectedChatIds.contains(session.id);
    
    return InkWell(
      onTap: () => _handleSessionTap(session),
      onLongPress: () => _handleSessionLongPress(session),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 选择指示器
            if (_isSelectionMode)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue : Colors.grey[400],
                ),
              ),
            // 会话图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 12),
            // 会话信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 会话标题
                  Text(
                    session.title.isNotEmpty 
                        ? session.title 
                        : '新对话',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // 最后一条消息预览
                  if (session.lastMessage != null)
                    Text(
                      session.lastMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  // 时间和消息数量
                  Row(
                    children: [
                      Text(
                        _formatSessionTime(session.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${session.messageCount}条消息',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 更多操作按钮
            if (!_isSelectionMode)
              PopupMenuButton<String>(
                onSelected: (action) => _handleSessionAction(action, session),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('重命名'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建新建聊天按钮
  Widget _buildNewChatFab() {
    return FloatingActionButton(
      onPressed: _createNewChat,
      child: const Icon(Icons.add),
    );
  }

  /// 过滤聊天会话
  List<ChatSession> _filterChatSessions(List<ChatSession> sessions) {
    if (_searchQuery.isEmpty) {
      return sessions;
    }

    return sessions.where((session) {
      return session.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (session.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  /// 处理会话点击
  void _handleSessionTap(ChatSession session) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedChatIds.contains(session.id)) {
          _selectedChatIds.remove(session.id);
        } else {
          _selectedChatIds.add(session.id);
        }
      });
    } else {
      // 加载选中的聊天会话
      context.read<StandaloneChatBloc>().add(
        StandaloneChatEvent.loadChatSession(sessionId: session.id),
      );
      Navigator.of(context).pop();
    }
  }

  /// 处理会话长按
  void _handleSessionLongPress(ChatSession session) {
    setState(() {
      _isSelectionMode = true;
      _selectedChatIds.add(session.id);
    });
  }

  /// 处理会话操作
  void _handleSessionAction(String action, ChatSession session) {
    switch (action) {
      case 'rename':
        _showRenameDialog(session);
        break;
      case 'delete':
        _showDeleteConfirmDialog([session.id]);
        break;
    }
  }

  /// 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllConfirmDialog();
        break;
      case 'export':
        _exportChatHistory();
        break;
    }
  }

  /// 显示重命名对话框
  void _showRenameDialog(ChatSession session) {
    final controller = TextEditingController(text: session.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名对话'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入新的对话名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != session.title) {
                context.read<StandaloneChatBloc>().add(
                  StandaloneChatEvent.renameChatSession(
                    sessionId: session.id,
                    newTitle: newTitle,
                  ),
                );
              }
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(List<String> sessionIds) {
    final count = sessionIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除${count > 1 ? '$count个' : ''}对话'),
        content: Text('确定要删除${count > 1 ? '这些' : '这个'}对话吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StandaloneChatBloc>().add(
                StandaloneChatEvent.deleteChatSessions(sessionIds: sessionIds),
              );
              Navigator.of(context).pop();
              if (_isSelectionMode) {
                setState(() {
                  _isSelectionMode = false;
                  _selectedChatIds.clear();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示清空所有记录确认对话框
  void _showClearAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有记录'),
        content: const Text('确定要清空所有聊天记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StandaloneChatBloc>().add(
                const StandaloneChatEvent.clearAllChatHistory(),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  /// 删除选中的聊天
  void _deleteSelectedChats() {
    if (_selectedChatIds.isNotEmpty) {
      _showDeleteConfirmDialog(_selectedChatIds.toList());
    }
  }

  /// 创建新聊天
  void _createNewChat() {
    context.read<StandaloneChatBloc>().add(
      const StandaloneChatEvent.createNewChatSession(),
    );
    Navigator.of(context).pop();
  }

  /// 导出聊天历史
  void _exportChatHistory() {
    context.read<StandaloneChatBloc>().add(
      const StandaloneChatEvent.exportChatHistory(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('聊天记录导出功能开发中...'),
      ),
    );
  }

  /// 格式化会话时间
  String _formatSessionTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

