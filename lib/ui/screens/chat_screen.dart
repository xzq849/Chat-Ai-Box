import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

import '../../models/chat.dart';
import '../../models/message.dart' as app_models;
import '../../services/chat_service.dart';
import '../../api/api_factory.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  Chat? _chat;
  List<types.Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadChat();
  }
  
  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (chat != null) {
        setState(() {
          _chat = chat;
          _messages = _convertMessages(chat.messages);
        });
      } else {
        setState(() {
          _errorMessage = '找不到聊天记录';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载聊天失败: $e';
      });
      _showErrorSnackBar('加载聊天失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<types.Message> _convertMessages(List<app_models.Message> appMessages) {
    // 按时间戳排序，最新的消息在前面
    final sortedMessages = List<app_models.Message>.from(appMessages);
    sortedMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedMessages.map((msg) {
      types.User user;
      
      switch (msg.sender) {
        case app_models.MessageSender.user:
          user = const types.User(id: 'user', firstName: '用户');
          break;
        case app_models.MessageSender.ai:
          user = const types.User(id: 'ai', firstName: 'AI');
          break;
        case app_models.MessageSender.system:
        default:
          user = const types.User(id: 'system', firstName: '系统');
          break;
      }
      
      switch (msg.type) {
        case app_models.MessageType.text:
          return types.TextMessage(
            id: msg.id,
            text: msg.content,
            author: user,
            createdAt: msg.timestamp.millisecondsSinceEpoch,
          );
        case app_models.MessageType.image:
          return types.ImageMessage(
            id: msg.id,
            author: user,
            name: msg.content,
            size: 0,
            uri: msg.imageUrl ?? '',
            createdAt: msg.timestamp.millisecondsSinceEpoch,
          );
        default:
          return types.TextMessage(
            id: msg.id,
            text: msg.content,
            author: user,
            createdAt: msg.timestamp.millisecondsSinceEpoch,
          );
      }
    }).toList();
  }
  
  void _handleSendPressed(types.PartialText message) async {
    if (_chat == null || message.text.trim().isEmpty || _isSending) return;
    
    final userMessage = types.TextMessage(
      id: const Uuid().v4(),
      author: const types.User(id: 'user', firstName: '用户'),
      text: message.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    setState(() {
      _messages.insert(0, userMessage);
      _isSending = true;
      _errorMessage = '';
    });
    
    try {
      // 发送消息到服务
      final aiMessage = await _chatService.sendMessage(_chat!, message.text);
      
      // 添加AI回复到UI
      final aiTextMessage = types.TextMessage(
        id: aiMessage.id,
        author: const types.User(id: 'ai', firstName: 'AI'),
        text: aiMessage.content,
        createdAt: aiMessage.timestamp.millisecondsSinceEpoch,
      );
      
      setState(() {
        _messages.insert(0, aiTextMessage);
      });
    } catch (e) {
      setState(() {
        _errorMessage = '发送消息失败: $e';
      });
      _showErrorSnackBar('发送消息失败: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<void> _refreshChat() async {
    await _loadChat();
  }
  
  void _showChatSettings() {
    if (_chat == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
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
              leading: const Icon(Icons.delete),
              title: const Text('清空聊天记录'),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditTitleDialog() {
    if (_chat == null) return;
    
    final textController = TextEditingController(text: _chat!.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑标题'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '聊天标题',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty) {
                final updatedChat = _chat!.copyWith(title: newTitle);
                await _chatService.updateChat(updatedChat);
                setState(() {
                  _chat = updatedChat;
                });
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showClearChatDialog() {
    if (_chat == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录'),
        content: const Text('确定要清空所有聊天记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 创建一个新的空聊天，保留原来的ID和标题
              final clearedChat = _chat!.copyWith(
                messages: [],
                updatedAt: DateTime.now(),
              );
              await _chatService.updateChat(clearedChat);
              setState(() {
                _chat = clearedChat;
                _messages = [];
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chat?.title ?? '聊天'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showChatSettings,
          ),
        ],
      ),
      body: _isLoading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshChat,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Chat(
                        messages: _messages,
                        onSendPressed: _handleSendPressed,
                        user: const types.User(id: 'user'),
                        showUserAvatars: true,
                        showUserNames: true,
                        theme: DefaultChatTheme(
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          primaryColor: Theme.of(context).colorScheme.primary,
                          secondaryColor: Theme.of(context).colorScheme.secondary,
                          userAvatarNameColors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.tertiary,
                          ],
                        ),
                      ),
                    ),
                    if (_isSending)
                      const LinearProgressIndicator(),
                  ],
                ),
    );
  }
}