import 'package:flutter/material.dart';
import '../../models/message.dart';
import '../themes/app_theme.dart';

/// 消息气泡组件
/// 用于在聊天界面中显示消息
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLastMessage;
  
  const MessageBubble({
    Key? key,
    required this.message,
    this.isLastMessage = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == MessageSender.user;
    final theme = Theme.of(context);
    
    // 根据消息发送者设置不同的颜色和对齐方式
    final backgroundColor = isUserMessage
        ? theme.colorScheme.primary.withOpacity(0.8)
        : theme.colorScheme.surfaceVariant;
    
    final textColor = isUserMessage
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;
    
    final alignment = isUserMessage
        ? Alignment.centerRight
        : Alignment.centerLeft;
    
    final borderRadius = isUserMessage
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );
    
    // 根据消息类型构建不同的内容
    Widget content;
    switch (message.type) {
      case MessageType.text:
        content = Text(
          message.content,
          style: TextStyle(color: textColor),
        );
        break;
      case MessageType.image:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  message.content,
                  style: TextStyle(color: textColor),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.imageUrl ?? '',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            ),
          ],
        );
        break;
      case MessageType.file:
        content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.attach_file),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        );
        break;
      case MessageType.system:
        // 系统消息使用特殊样式
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
    }
    
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: content,
        ),
      ),
    );
  }
}