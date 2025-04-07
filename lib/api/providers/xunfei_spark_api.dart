import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../models/message.dart';
import '../../models/provider.dart';
import '../base_api.dart';

/// 讯飞星火API实现
class XunfeiSparkApi extends BaseApi {
  Provider _provider;
  
  XunfeiSparkApi(this._provider);
  
  @override
  String get providerName => '讯飞星火';
  
  @override
  String get apiKey => _provider.apiKey;
  
  @override
  set apiKey(String value) {
    _provider = _provider.copyWith(apiKey: value);
  }
  
  @override
  String get baseUrl => _provider.baseUrl;
  
  /// 生成认证URL
  String _generateAuthUrl() {
    final apiKey = this.apiKey;
    final apiSecret = _provider.config['api_secret'] as String? ?? '';
    final appId = _provider.config['app_id'] as String? ?? '';
    
    if (apiKey.isEmpty || apiSecret.isEmpty || appId.isEmpty) {
      throw Exception('API Key、API Secret或App ID未设置');
    }
    
    final host = Uri.parse(baseUrl).host;
    final path = Uri.parse(baseUrl).path;
    final date = DateTime.now().toUtc().toString().split(' ')[0];
    final uuid = const Uuid().v4().replaceAll('-', '');
    
    // 生成认证字符串
    final signatureOrigin = "host: $host\ndate: $date\nGET $path HTTP/1.1";
    final signatureSha = Hmac(sha256, utf8.encode(apiSecret)).convert(utf8.encode(signatureOrigin));
    final signatureStr = base64.encode(signatureSha.bytes);
    
    // 生成认证头
    final authorizationOrigin = "api_key=\"$apiKey\", algorithm=\"hmac-sha256\", headers=\"host date request-line\", signature=\"$signatureStr\"";
    final authorization = base64.encode(utf8.encode(authorizationOrigin));
    
    // 拼接URL
    return "$baseUrl?authorization=$authorization&date=$date&host=$host";
  }
  
  @override
  Future<Message> sendMessage(List<Message> messages, Map<String, dynamic> options) async {
    final url = _generateAuthUrl();
    final temperature = options['temperature'] ?? _provider.config['temperature'] ?? 0.5;
    
    // 转换消息格式为讯飞星火格式
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
      'header': {
        'app_id': _provider.config['app_id'],
        'uid': const Uuid().v4(),
      },
      'parameter': {
        'chat': {
          'domain': 'general',
          'temperature': temperature,
          'max_tokens': 2048,
        }
      },
      'payload': {
        'message': {
          'text': formattedMessages,
        }
      }
    };
    
    final responseData;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: createHeaders(),
        body: json.encode(requestBody),
      );
      
      responseData = handleResponse(response);
      final content = responseData['payload']['text'][0]['content'];
    } catch (e) {
      throw Exception('请求讯飞星火API失败: ${e.toString()}');
    }
    
    // 创建AI回复消息
    return Message.text(
      content: content,
      sender: MessageSender.ai,
      chatId: messages.first.chatId,
      metadata: {
        'provider': providerName,
        'usage': responseData['payload']['usage'],
      },
    );
  }
  
  @override
  Future<bool> validateApiKey() async {
    try {
      final testUrl = _generateAuthUrl();
      final response = await http.get(Uri.parse(testUrl));
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('验证讯飞星火API密钥失败: ${e.toString()}');
    }
  }
  
  @override
  Map<String, dynamic> getConfigOptions() {
    return {
      'model': {
        'type': 'select',
        'label': '模型版本',
        'options': [
          {'label': 'Spark Lite', 'value': 'v1.5'},
          {'label': 'Spark Pro', 'value': 'v2.0'},
          {'label': 'Spark Ultra', 'value': 'v3.0'},
        ],
        'default': 'v2.0',
      },
      'app_id': {
        'type': 'text',
        'label': 'App ID',
        'required': true,
      },
      'api_secret': {
        'type': 'password',
        'label': 'API Secret',
        'required': true,
      },
      'temperature': {
        'type': 'slider',
        'label': '温度',
        'min': 0.0,
        'max': 1.0,
        'step': 0.1,
        'default': 0.5,
      },
      'max_tokens': {
        'type': 'number',
        'label': '最大Token数',
        'min': 100,
        'max': 4000,
        'default': 2000,
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