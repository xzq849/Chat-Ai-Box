import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../models/provider.dart';
import '../../services/chat_service.dart';
import '../../services/provider_service.dart';
import 'chat_screen.dart';
import 'provider_settings_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final ProviderService _providerService = ProviderService();
  List<Chat> _chats = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadChats();
  }
  
  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chats = await _chatService.getAllChats();
      setState(() {
        _chats = chats;
      });
    } catch (e) {
      _showErrorSnackBar('加载聊天列表失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createNewChat() async {
    // 获取所有提供商
    final providers = await _providerService.getAllProviders();
    if (providers.isEmpty) {
      _showErrorSnackBar('没有可用的AI服务提供商，请先添加提供商');
      return;
    }
    
    // 显示提供商选择对话框
    final Provider? selectedProvider = await showDialog<Provider>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择AI服务提供商'),
        children: providers.map((provider) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, provider),
          child: Text(provider.name),
        )).toList(),
      ),
    );
    
    if (selectedProvider == null) return;
    
    // 显示标题输入对话框
    final String? title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建聊天'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '聊天标题',
            hintText: '输入聊天标题',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final controller = (context.findRenderObject() as RenderBox)
                  .findDescendant((child) => child is RenderEditable) as RenderEditable;
              final text = controller.text?.text ?? '新聊天';
              Navigator.pop(context, text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (title == null || title.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 创建新聊天
      final chat = await _chatService.createChat(title, selectedProvider);
      
      // 刷新聊天列表
      await _loadChats();
      
      // 打开新聊天
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chat.id),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('创建聊天失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('聊天列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProviderSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('没有聊天记录'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createNewChat,
                        child: const Text('新建聊天'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    return ListTile(
                      title: Text(chat.title),
                      subtitle: Text(
                        '最后更新: ${chat.updatedAt.toString().split('.')[0]}',
                      ),
                      leading: const CircleAvatar(
                        child: Icon(Icons.chat),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('删除聊天'),
                              content: const Text('确定要删除这个聊天吗？此操作不可撤销。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await _chatService.deleteChat(chat.id);
                            await _loadChats();
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(chatId: chat.id),
                          ),
                        ).then((_) => _loadChats());
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        child: const Icon(Icons.add),
      ),
    );
  }
}