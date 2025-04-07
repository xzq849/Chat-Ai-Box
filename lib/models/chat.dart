import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'message.dart';

/// 对话模型类
class Chat extends Equatable {
  final String id;           // 对话唯一ID
  final String title;        // 对话标题
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 最后更新时间
  final String providerId;   // 使用的AI服务提供商ID
  final Map<String, dynamic>? settings; // 对话特定设置
  final List<Message> messages; // 消息列表
  final bool isPinned;       // 是否置顶
  final bool isArchived;     // 是否归档
  
  /// 构造函数
  Chat({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.providerId,
    this.settings,
    List<Message>? messages,
    this.isPinned = false,
    this.isArchived = false,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    messages = messages ?? [];
  
  /// 创建新对话的工厂方法
  factory Chat.create({
    required String title,
    required String providerId,
    Map<String, dynamic>? settings,
  }) {
    return Chat(
      title: title,
      providerId: providerId,
      settings: settings,
    );
  }
  
  /// 添加消息到对话
  Chat addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 获取最后一条消息
  Message? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }
  
  /// 获取消息数量
  int get messageCount => messages.length;
  
  /// 复制并修改对话的方法
  Chat copyWith({
    String? title,
    DateTime? updatedAt,
    String? providerId,
    Map<String, dynamic>? settings,
    List<Message>? messages,
    bool? isPinned,
    bool? isArchived,
  }) {
    return Chat(
      id: this.id,
      title: title ?? this.title,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      providerId: providerId ?? this.providerId,
      settings: settings ?? this.settings,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }
  
  /// 将对话转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'providerId': providerId,
      'settings': settings,
      'isPinned': isPinned ? 1 : 0,
      'isArchived': isArchived ? 1 : 0,
    };
  }
  
  /// 从Map创建对话
  factory Chat.fromMap(Map<String, dynamic> map, {List<Message>? messages}) {
    return Chat(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      providerId: map['providerId'],
      settings: map['settings'],
      messages: messages ?? [],
      isPinned: map['isPinned'] == 1,
      isArchived: map['isArchived'] == 1,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    updatedAt,
    providerId,
    settings,
    messages,
    isPinned,
    isArchived,
  ];
}