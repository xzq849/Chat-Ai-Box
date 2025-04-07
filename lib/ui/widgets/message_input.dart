import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// 消息输入组件的回调函数类型
typedef MessageInputCallback = void Function(String message);

/// 消息输入组件
/// 用于在聊天界面中输入消息
class MessageInput extends StatefulWidget {
  final MessageInputCallback onSend;
  final bool isLoading;
  final String hintText;
  
  const MessageInput({
    Key? key,
    required this.onSend,
    this.isLoading = false,
    this.hintText = '输入消息...',
  }) : super(key: key);
  
  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;
  
  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }
  
  void _handleSend() {
    if (_controller.text.isEmpty) return;
    
    widget.onSend(_controller.text);
    _controller.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 附加功能按钮（如图片、文件等）
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // 显示附加功能菜单
              _showAttachmentOptions(context);
            },
          ),
          // 消息输入框
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _hasText
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  onPressed: _hasText ? _handleSend : null,
                ),
        ],
      ),
    );
  }
  
  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现图片选择功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('文件'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现文件选择功能
              },
            ),
          ],
        ),
      ),
    );
  }
}