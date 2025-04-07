import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/message.dart';
import '../../models/provider.dart';
import '../base_api.dart';

/// 百度文心一言API实现
class BaiduWenxinApi extends BaseApi {
  Provider _provider;
  String? _accessToken;
  DateTime? _tokenExpireTime;
  
  BaiduWenxinApi(this._provider);
  
  @override
  String get providerName => '百度文心一言';
  
  @override
  String get apiKey => _provider.apiKey;
  
  @override
  set apiKey(String value) {
    _provider = _provider.copyWith(apiKey: value);
    _accessToken = null; // 重置访问令牌
  }
  
  @override
  String get baseUrl => _provider.baseUrl;
  
  /// 获取访问令牌
  Future<String> _getAccessToken() async {
    // 如果已有有效的访问令牌，直接返回
    if (_accessToken != null && _tokenExpireTime != null && 
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return _accessToken!;
    }
    
    // 从配置中获取API Key和Secret Key
    final apiKey = this.apiKey;
    final secretKey = _provider.config['api_secret'] as String? ?? '';
    
    if (apiKey.isEmpty || secretKey.isEmpty) {
      throw Exception('API Key或Secret Key未设置');
    }
    
    // 请求新的访问令牌
    final url = 'https://aip.baidubce.com/oauth/2.0/token';
    final response = await http.post(
      Uri.parse(url),
      body: {
        'grant_type': 'client_credentials',
        'client_id': apiKey,
        'client_secret': secretKey,
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('获取访问令牌失败: ${response.body}');
    }
    
    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    
    // 设置令牌过期时间（提前5分钟过期，以确保安全）
    final expiresIn = data['expires_in'] as int;
    _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 300));
    
    return _accessToken!;
  }
  
  @override
  Future<Message> sendMessage(List<Message> messages, Map<String, dynamic> options) async {
    final accessToken = await _getAccessToken();
    final model = options['model'] ?? _provider.config['model'] ?? 'ERNIE-Bot-4';
    final temperature = options['temperature'] ?? _provider.config['temperature'] ?? 0.7;
    final topP = options['top_p'] ?? _provider.config['top_p'] ?? 0.8;
    
    // 构建API URL
    String url;
    if (model == 'ERNIE-Bot-4') {
      url = 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions_pro';
    } else if (model == 'ERNIE-Bot') {
      url = 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions';
    } else if (model == 'ERNIE-Bot-turbo') {
      url = 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/eb-instant';
    } else {
      throw Exception('不支持的模型: $model');
    }
    
    url += '?access_token=$accessToken';
    
    // 转换消息格式为百度文心一言格式
    final formattedMessages = messages.map((msg) {
      String role;
      switch (msg.sender) {
        case MessageSender.user:
          role = 'user';
          break;
        case MessageSender.ai:
          role = 'assistant';
          break;
        case MessageSender.system:
        default:
          role = 'system';
          break;
      }
      
      return {
        'role': role,
        'content': msg.content,
      };
    }).toList();
    
    final requestBody = {
      'messages': formattedMessages,
      'temperature': temperature,
      'top_p': topP,
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );
    
    if (response.statusCode != 200) {
      throw Exception('API请求失败: ${response.statusCode}, ${response.body}');
    }
    
    final responseData = jsonDecode(response.body);
    final content = responseData['result'];
    
    // 创建AI回复消息
    return Message.text(
      content: content,
      sender: MessageSender.ai,
      chatId: messages.first.chatId,
      metadata: {
        'model': model,
        'provider': providerName,
        'usage': responseData['usage'],
      },
    );
  }
  
  @override
  Future<bool> validateApiKey() async {
    try {
      await _getAccessToken();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Map<String, dynamic> getConfigOptions() {
    return {
      'api_secret': {
        'type': 'password',
        'label': 'API Secret Key',
        'required': true,
      },
      'model': {
        'type': 'select',
        'label': '模型',
        'options': [
          {'label': 'ERNIE-Bot-4', 'value': 'ERNIE-Bot-4'},
          {'label': 'ERNIE-Bot', 'value': 'ERNIE-Bot'},
          {'label': 'ERNIE-Bot-turbo', 'value': 'ERNIE-Bot-turbo'},
        ],
        'default': 'ERNIE-Bot-4',
      },
      'temperature': {
        'type': 'slider',
        'label': '温度',
        'min': 0.0,
        'max': 1.0,
        'step': 0.1,
        'default': 0.7,
      },
      'top_p': {
        'type': 'slider',
        'label': 'Top P',
        'min': 0.0,
        'max': 1.0,
        'step': 0.1,
        'default': 0.8,
      },
    };
  }
  
  @override
  Map<String, String> createHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}