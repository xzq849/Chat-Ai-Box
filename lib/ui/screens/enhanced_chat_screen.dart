import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../models/provider.dart';
import '../../services/chat_service.dart';
import '../../services/provider_service.dart';
import '../../utils/app_utils.dart';
import '../../utils/logger_util.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

/// 增强版聊天界面
/// 提供更好的用户体验和多服务商支持
class EnhancedChatScreen extends StatefulWidget {
  final String chatId;
  
  const EnhancedChatScreen({Key? key, required this.chatId}) : super(key: key);
  
  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final ChatService _chatService = ChatService();
  final ProviderService _providerService = ProviderService();
  final ScrollController _scrollController = ScrollController();
  
  Chat? _chat;
  Provider? _provider;
  bool _isLoading = false;
  bool _isSending = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadChat();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // 加载聊天会话
      final chat = await _chatService.getChatById(widget.chatId);
      if (chat != null) {
        // 加载提供商信息
        final provider = await _providerService.getProviderById(chat.providerId);
        
        setState(() {
          _chat = chat;
          _provider = provider;
        });
        
        // 滚动到最新消息
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        setState(() {
          _errorMessage = '找不到聊天记录';
        });
      }
    } catch (e) {
      LoggerUtil.e('加载聊天失败', e);
      setState(() {
        _errorMessage = '加载聊天失败: $e';
      });
      AppUtils.showSnackBar(context, '加载聊天失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _sendMessage(String content) async {
    if (content.isEmpty || _chat == null || _provider == null) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // 发送消息并获取AI回复
      await _chatService.sendMessage(_chat!, content);
      
      // 重新加载聊天以获取最新消息
      await _loadChat();
      
      // 滚动到最新消息
      _scrollToBottom();
    } catch (e) {
      LoggerUtil.e('发送消息失败', e);
      AppUtils.showSnackBar(context, '发送消息失败: $e', isError: true);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _showChatOptions() async {
    if (_chat == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑标题'),
              onTap: () {
                Navigator.pop(context);
                _showEditTitleDialog();
              },
            ),
            ListTile(
              leading: Icon(
                _chat!.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(_chat!.isPinned ? '取消置顶' : '置顶聊天'),
              onTap: () async {
                Navigator.pop(context);
                final updatedChat = _chat!.copyWith(isPinned: !_chat!.isPinned);
                await _chatService.updateChat(updatedChat);
                await _loadChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('聊天设置'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现聊天设置功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('删除聊天', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await AppUtils.showConfirmDialog(
                  context: context,
                  title: '删除聊天',
                  content: '确定要删除这个聊天吗？此操作不可撤销。',
                );
                
                if (confirm) {
                  await _chatService.deleteChat(_chat!.id);
                  if (mounted) {
                    Navigator.pop(context); // 返回聊天列表
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showEditTitleDialog() async {
    if (_chat == null) return;
    
    final controller = TextEditingController(text: _chat!.title);
    
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '聊天标题',
            hintText: '输入新的聊天标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (newTitle != null && newTitle.isNotEmpty && newTitle != _chat!.title) {
      final updatedChat = _chat!.copyWith(title: newTitle);
      await _chatService.updateChat(updatedChat);
      await _loadChat();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _chat != null
            ? Text(_chat!.title)
            : const Text('聊天'),
        actions: [
          if (_provider != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text(
                  _provider!.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                backgroundColor: AppUtils.getProviderColor(_provider!.name),
                avatar: Icon(
                  AppUtils.getProviderIcon(_provider!.name),
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 16,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _buildChatContent(),
    );
  }
  
  Widget _buildChatContent() {
    if (_chat == null) {
      return const Center(child: Text('无法加载聊天内容'));
    }
    
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: _chat!.messages.isEmpty
              ? _buildEmptyChat()
              : _buildMessageList(),
        ),
        // 消息输入框
        MessageInput(
          onSend: _sendMessage,
          isLoading: _isSending,
          hintText: '输入消息...',
        ),
      ],
    );
  }
  
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '开始新的对话',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '发送消息开始与AI对话',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      itemCount: _chat!.messages.length,
      itemBuilder: (context, index) {
        final message = _chat!.messages[index];
        final isLastMessage = index == _chat!.messages.length - 1;
        
        return MessageBubble(
          message: message,
          isLastMessage: isLastMessage,
        );
      },
    );
  }
}