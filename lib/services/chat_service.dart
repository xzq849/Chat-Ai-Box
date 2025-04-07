import '../api/api_factory.dart';
import '../api/base_api.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/provider.dart';
import 'database_service.dart';

/// 聊天服务类
/// 负责管理聊天会话和消息
class ChatService {
  final DatabaseService _databaseService = DatabaseService();
  
  /// 创建新的聊天会话
  Future<Chat> createChat(String title, Provider provider) async {
    final chat = Chat.create(
      title: title,
      providerId: provider.id,
    );
    
    await _databaseService.upsertChat(chat);
    return chat;
  }
  
  /// 获取所有聊天会话
  Future<List<Chat>> getAllChats() async {
    return await _databaseService.getAllChats();
  }
  
  /// 获取指定ID的聊天会话，包括其所有消息
  Future<Chat?> getChatById(String id) async {
    return await _databaseService.getChatWithMessages(id);
  }
  
  /// 更新聊天会话
  Future<void> updateChat(Chat chat) async {
    await _databaseService.upsertChat(chat);
  }
  
  /// 删除聊天会话
  Future<void> deleteChat(String id) async {
    await _databaseService.deleteChat(id);
  }
  
  /// 发送消息并获取AI回复
  Future<Message> sendMessage(Chat chat, String content) async {
    // 获取提供商
    final provider = await _databaseService.getProviderById(chat.providerId);
    if (provider == null) {
      throw Exception('找不到提供商: ${chat.providerId}');
    }
    
    // 创建用户消息
    final userMessage = Message.text(
      content: content,
      sender: MessageSender.user,
      chatId: chat.id,
    );
    
    // 保存用户消息
    await _databaseService.upsertMessage(userMessage);
    
    // 更新聊天会话
    Chat updatedChat = chat.addMessage(userMessage);
    await _databaseService.upsertChat(updatedChat);
    
    try {
      // 创建API实例
      final api = ApiFactory.createApi(provider);
      
      // 获取聊天历史消息
      final messages = await _databaseService.getMessagesByChatId(chat.id);
      
      // 发送消息到API并获取回复
      final aiMessage = await api.sendMessage(
        messages,
        provider.config,
      );
      
      // 保存AI回复消息
      await _databaseService.upsertMessage(aiMessage);
      
      // 再次更新聊天会话
      updatedChat = updatedChat.addMessage(aiMessage);
      await _databaseService.upsertChat(updatedChat);
      
      return aiMessage;
    } catch (e) {
      // 创建错误消息
      final errorMessage = Message.system(
        content: '发送消息失败: $e',
        chatId: chat.id,
      );
      
      // 保存错误消息
      await _databaseService.upsertMessage(errorMessage);
      
      // 更新聊天会话
      updatedChat = updatedChat.addMessage(errorMessage);
      await _databaseService.upsertChat(updatedChat);
      
      throw Exception('发送消息失败: $e');
    }
  }
}