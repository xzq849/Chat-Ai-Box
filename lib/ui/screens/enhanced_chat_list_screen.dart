import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../models/provider.dart';
import '../../services/chat_service.dart';
import '../../services/provider_service.dart';
import '../../utils/app_utils.dart';
import '../../utils/logger_util.dart';
import '../widgets/chat_item.dart';
import 'enhanced_chat_screen.dart';
import 'provider_settings_screen.dart';

/// 增强版聊天列表界面
/// 提供更好的用户体验和多服务商支持
class EnhancedChatListScreen extends StatefulWidget {
  const EnhancedChatListScreen({Key? key}) : super(key: key);
  
  @override
  State<EnhancedChatListScreen> createState() => _EnhancedChatListScreenState();
}

class _EnhancedChatListScreenState extends State<EnhancedChatListScreen> {
  final ChatService _chatService = ChatService();
  final ProviderService _providerService = ProviderService();
  List<Chat> _chats = [];
  List<Provider> _providers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 加载聊天列表
      final chats = await _chatService.getAllChats();
      // 加载提供商列表
      final providers = await _providerService.getAllProviders();
      
      setState(() {
        _chats = chats;
        _providers = providers;
      });
    } catch (e) {
      LoggerUtil.e('加载数据失败', e);
      AppUtils.showSnackBar(context, '加载数据失败: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<Chat> get _filteredChats {
    if (_searchQuery.isEmpty) {
      // 先显示置顶的聊天，再按更新时间排序
      final pinnedChats = _chats.where((chat) => chat.isPinned).toList();
      final unpinnedChats = _chats.where((chat) => !chat.isPinned).toList();
      
      // 按更新时间排序
      pinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      unpinnedChats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return [...pinnedChats, ...unpinnedChats];
    } else {
      // 搜索标题
      return _chats
          .where((chat) => chat.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }
  
  Future<void> _createNewChat() async {
    // 获取活跃的提供商
    final activeProviders = _providers.where((p) => p.isActive).toList();
    
    if (activeProviders.isEmpty) {
      AppUtils.showSnackBar(
        context, 
        '没有可用的AI服务提供商，请先添加并激活提供商', 
        isError: true
      );
      return;
    }
    
    // 显示提供商选择对话框
    final Provider? selectedProvider = await showDialog<Provider>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择AI服务提供商'),
        children: activeProviders.map((provider) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, provider),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppUtils.getProviderColor(provider.name),
              child: Icon(
                AppUtils.getProviderIcon(provider.name),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(provider.name),
            subtitle: Text(
              provider.apiKey.isEmpty ? '未配置' : '已配置',
              style: TextStyle(
                color: provider.apiKey.isEmpty
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
          ),
        )).toList(),
      ),
    );
    
    if (selectedProvider == null) return;
    
    // 如果API密钥未配置，提示用户
    if (selectedProvider.apiKey.isEmpty) {
      if (!mounted) return;
      
      final bool goToSettings = await AppUtils.showConfirmDialog(
        context: context,
        title: '提供商未配置',
        content: '${selectedProvider.name}的API密钥尚未配置，是否前往设置？',
        confirmText: '前往设置',
        cancelText: '取消',
      );
      
      if (goToSettings) {
        if (!mounted) return;
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProviderSettingsScreen(),
          ),
        );
        
        // 重新加载数据
        await _loadData();
        return;
      } else {
        return;
      }
    }
    
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
              final controller = ModalRoute.of(context)!.focusNode?.enclosingScope;
              final text = controller != null ? controller.toString() : '新聊天';
              Navigator.pop(context, text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (title == null || title.isEmpty) return;
    
    try {
      // 创建新聊天
      final chat = await _chatService.createChat(title, selectedProvider);
      
      // 重新加载聊天列表
      await _loadData();
      
      // 打开新聊天
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedChatScreen(chatId: chat.id),
          ),
        );
      }
    } catch (e) {
      LoggerUtil.e('创建聊天失败', e);
      AppUtils.showSnackBar(context, '创建聊天失败: $e', isError: true);
    }
  }
  
  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatScreen(chatId: chat.id),
      ),
    ).then((_) => _loadData()); // 返回时重新加载数据
  }
  
  Future<void> _showChatOptions(Chat chat) async {
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
                _showEditTitleDialog(chat);
              },
            ),
            ListTile(
              leading: Icon(
                chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              title: Text(chat.isPinned ? '取消置顶' : '置顶聊天'),
              onTap: () async {
                Navigator.pop(context);
                final updatedChat = chat.copyWith(isPinned: !chat.isPinned);
                await _chatService.updateChat(updatedChat);
                await _loadData();
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
                  await _chatService.deleteChat(chat.id);
                  await _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showEditTitleDialog(Chat chat) async {
    final controller = TextEditingController(text: chat.title);
    
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
    
    if (newTitle != null && newTitle.isNotEmpty && newTitle != chat.title) {
      final updatedChat = chat.copyWith(title: newTitle);
      await _chatService.updateChat(updatedChat);
      await _loadData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchQuery.isEmpty
            ? const Text('AI聊天助手')
            : TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索聊天...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_searchQuery.isEmpty ? Icons.search : Icons.clear),
            onPressed: () {
              setState(() {
                _searchQuery = _searchQuery.isEmpty ? '' : '';
              });
            },
          ),
          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProviderSettingsScreen(),
                ),
              ).then((_) => _loadData()); // 返回时重新加载数据
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildChatList() {
    if (_filteredChats.isEmpty) {
      return _searchQuery.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '没有找到匹配的聊天',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '尝试使用其他关键词搜索',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '没有聊天记录',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角的按钮创建新聊天',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _filteredChats.length,
        itemBuilder: (context, index) {
          final chat = _filteredChats[index];
          return ChatItem(
            chat: chat,
            onTap: () => _openChat(chat),
            onLongPress: () => _showChatOptions(chat),
          );
        },
      ),
    );
  }
}