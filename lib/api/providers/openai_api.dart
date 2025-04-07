import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/message.dart';
import '../../models/provider.dart';
import '../base_api.dart';

/// OpenAI API实现
class OpenAIApi extends BaseApi {
  Provider _provider;
  
  OpenAIApi(this._provider);
  
  @override
  String get providerName => 'OpenAI';
  
  @override
  String get apiKey => _provider.apiKey;
  
  @override
  set apiKey(String value) {
    _provider = _provider.copyWith(apiKey: value);
  }
  
  @override
  String get baseUrl => _provider.baseUrl;
  
  @override
  Future<Message> sendMessage(List<Message> messages, Map<String, dynamic> options) async {
    final url = '$baseUrl/chat/completions';
    final model = options['model'] ?? _provider.config['model'] ?? 'gpt-3.5-turbo';
    final temperature = options['temperature'] ?? _provider.config['temperature'] ?? 0.7;
    final maxTokens = options['max_tokens'] ?? _provider.config['max_tokens'] ?? 2000;
    
    // 转换消息格式为OpenAI格式
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
      'model': model,
      'messages': formattedMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: createHeaders(),
      body: json.encode(requestBody),
    );
    
    final responseData = handleResponse(response);
    final content = responseData['choices'][0]['message']['content'];
    
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
    if (apiKey.isEmpty) return false;
    
    try {
      final url = '$baseUrl/models';
      final response = await http.get(
        Uri.parse(url),
        headers: createHeaders(),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Map<String, dynamic> getConfigOptions() {
    return {
      'model': {
        'type': 'select',
        'label': '模型',
        'options': [
          {'label': 'GPT-3.5 Turbo', 'value': 'gpt-3.5-turbo'},
          {'label': 'GPT-4', 'value': 'gpt-4'},
          {'label': 'GPT-4 Turbo', 'value': 'gpt-4-turbo-preview'},
        ],
        'default': 'gpt-3.5-turbo',
      },
      'temperature': {
        'type': 'slider',
        'label': '温度',
        'min': 0.0,
        'max': 2.0,
        'step': 0.1,
        'default': 0.7,
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
}