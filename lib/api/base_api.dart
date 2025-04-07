import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

/// 基础API接口类
/// 所有服务商的API实现都应该继承这个类
abstract class BaseApi {
  /// API提供商名称
  String get providerName;
  
  /// API密钥
  String get apiKey;
  
  /// 设置API密钥
  set apiKey(String value);
  
  /// 基础URL
  String get baseUrl;
  
  /// 发送消息并获取回复
  /// 
  /// [messages] 历史消息列表
  /// [options] 请求选项，如温度、最大token等
  Future<Message> sendMessage(List<Message> messages, Map<String, dynamic> options);
  
  /// 检查API密钥是否有效
  Future<bool> validateApiKey();
  
  /// 获取API配置选项
  Map<String, dynamic> getConfigOptions();
  
  /// 创建HTTP请求头
  Map<String, String> createHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }
  
  /// 处理HTTP响应
  dynamic handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = utf8.decode(response.bodyBytes);
    
    if (statusCode >= 200 && statusCode < 300) {
      return json.decode(responseBody);
    } else {
      throw Exception('API请求失败: $statusCode, $responseBody');
    }
  }
}