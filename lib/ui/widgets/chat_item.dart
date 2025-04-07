import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../themes/app_theme.dart';

/// 聊天项组件
/// 用于在聊天列表中显示聊天会话
class ChatItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  const ChatItem({
    Key? key,
    required this.chat,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessage = chat.messages.isNotEmpty
        ? chat.messages.last
        : null;
    
    // 格式化时间
    final formatter = DateFormat('MM-dd HH:mm');
    final timeString = lastMessage != null
        ? formatter.format(lastMessage.timestamp)
        : formatter.format(chat.updatedAt);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 聊天图标
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // 聊天信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 最后一条消息预览
                    Text(
                      _getLastMessagePreview(lastMessage),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 状态图标
              if (chat.isPinned)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 获取最后一条消息的预览文本
  String _getLastMessagePreview(Message? message) {
    if (message == null) {
      return '开始新的对话';
    }
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return message.content.isNotEmpty
            ? '${message.content} [图片]'
            : '[图片]';
      case MessageType.file:
        return '[文件] ${message.content}';
      case MessageType.system:
        return '[系统消息] ${message.content}';
      default:
        return message.content;
    }
  }
}