import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// 消息类型枚举
enum MessageType {
  text,     // 文本消息
  image,    // 图片消息
  file,     // 文件消息
  system,   // 系统消息
}

/// 消息发送者类型
enum MessageSender {
  user,     // 用户发送
  ai,       // AI回复
  system,   // 系统消息
}

/// 消息模型类
class Message extends Equatable {
  final String id;           // 消息唯一ID
  final String content;      // 消息内容
  final MessageType type;    // 消息类型
  final MessageSender sender; // 消息发送者
  final DateTime timestamp;  // 消息时间戳
  final String? imageUrl;    // 图片URL（仅当type为image时有效）
  final String? fileUrl;     // 文件URL（仅当type为file时有效）
  final Map<String, dynamic>? metadata; // 额外元数据
  final String chatId;       // 所属对话ID
  final String? replyToId;   // 回复消息ID（如果是回复消息）
  
  /// 构造函数
  Message({
    String? id,
    required this.content,
    required this.type,
    required this.sender,
    DateTime? timestamp,
    this.imageUrl,
    this.fileUrl,
    this.metadata,
    required this.chatId,
    this.replyToId,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
  
  /// 创建文本消息的工厂方法
  factory Message.text({
    required String content,
    required MessageSender sender,
    required String chatId,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      content: content,
      type: MessageType.text,
      sender: sender,
      chatId: chatId,
      replyToId: replyToId,
      metadata: metadata,
    );
  }
  
  /// 创建图片消息的工厂方法
  factory Message.image({
    required String imageUrl,
    required MessageSender sender,
    required String chatId,
    String? caption,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      content: caption ?? '',
      type: MessageType.image,
      sender: sender,
      imageUrl: imageUrl,
      chatId: chatId,
      replyToId: replyToId,
      metadata: metadata,
    );
  }
  
  /// 创建系统消息的工厂方法
  factory Message.system({
    required String content,
    required String chatId,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      content: content,
      type: MessageType.system,
      sender: MessageSender.system,
      chatId: chatId,
      metadata: metadata,
    );
  }
  
  /// 复制并修改消息的方法
  Message copyWith({
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    String? imageUrl,
    String? fileUrl,
    Map<String, dynamic>? metadata,
    String? chatId,
    String? replyToId,
  }) {
    return Message(
      id: this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      metadata: metadata ?? this.metadata,
      chatId: chatId ?? this.chatId,
      replyToId: replyToId ?? this.replyToId,
    );
  }
  
  /// 将消息转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'metadata': metadata,
      'chatId': chatId,
      'replyToId': replyToId,
    };
  }
  
  /// 从Map创建消息
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.toString().split('.').last == map['sender'],
        orElse: () => MessageSender.system,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      metadata: map['metadata'],
      chatId: map['chatId'],
      replyToId: map['replyToId'],
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    content,
    type,
    sender,
    timestamp,
    imageUrl,
    fileUrl,
    metadata,
    chatId,
    replyToId,
  ];
}