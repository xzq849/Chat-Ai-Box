import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// AI服务提供商模型类
class Provider extends Equatable {
  final String id;           // 提供商唯一ID
  final String name;         // 提供商名称
  final String apiKey;       // API密钥
  final String baseUrl;      // 基础URL
  final bool isActive;       // 是否激活
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 最后更新时间
  final Map<String, dynamic> config; // 额外配置选项
  
  /// 构造函数
  Provider({
    String? id,
    required this.name,
    required this.apiKey,
    required this.baseUrl,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? config,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now(),
    config = config ?? {};
  
  /// 复制并修改提供商的方法
  Provider copyWith({
    String? name,
    String? apiKey,
    String? baseUrl,
    bool? isActive,
    DateTime? updatedAt,
    Map<String, dynamic>? config,
  }) {
    return Provider(
      id: this.id,
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isActive: isActive ?? this.isActive,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      config: config ?? this.config,
    );
  }
  
  /// 将提供商转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'config': config,
    };
  }
  
  /// 从Map创建提供商
  factory Provider.fromMap(Map<String, dynamic> map) {
    return Provider(
      id: map['id'],
      name: map['name'],
      apiKey: map['apiKey'],
      baseUrl: map['baseUrl'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      config: Map<String, dynamic>.from(map['config'] ?? {}),
    );
  }
  
  /// 预定义的提供商类型
  static Provider openAI() {
    return Provider(
      name: 'OpenAI',
      apiKey: '',
      baseUrl: 'https://api.openai.com/v1',
      config: {
        'model': 'gpt-3.5-turbo',
        'temperature': 0.7,
        'max_tokens': 2000,
      },
    );
  }
  
  static Provider baiduWenxin() {
    return Provider(
      name: '百度文心一言',
      apiKey: '',
      baseUrl: 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat',
      config: {
        'model': 'ERNIE-Bot-4',
        'temperature': 0.7,
        'top_p': 0.8,
      },
    );
  }
  
  static Provider xunfeiSpark() {
    return Provider(
      name: '讯飞星火',
      apiKey: '',
      baseUrl: 'https://spark-api.xf-yun.com/v1.1/chat',
      config: {
        'app_id': '',
        'api_secret': '',
        'temperature': 0.5,
      },
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    apiKey,
    baseUrl,
    isActive,
    createdAt,
    updatedAt,
    config,
  ];
}