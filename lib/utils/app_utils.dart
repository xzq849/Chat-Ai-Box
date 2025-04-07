import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// 应用工具类
/// 提供各种实用工具方法
class AppUtils {
  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm'}) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }
  
  /// 格式化相对时间（如：刚刚、5分钟前、1小时前等）
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return formatDateTime(dateTime, format: 'MM-dd');
    }
  }
  
  /// 显示提示消息
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// 显示确认对话框
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// 验证API密钥格式
  static bool isValidApiKey(String apiKey, String providerName) {
    if (apiKey.isEmpty) return false;
    
    switch (providerName) {
      case 'OpenAI':
        // OpenAI API密钥通常以sk-开头
        return apiKey.startsWith('sk-') && apiKey.length > 20;
      case '百度文心一言':
        // 百度API密钥通常是一串字母数字
        return apiKey.length > 8;
      case '讯飞星火':
        // 讯飞API密钥通常是一串字母数字
        return apiKey.length > 8;
      default:
        return apiKey.length > 8;
    }
  }
  
  /// 获取提供商图标
  static IconData getProviderIcon(String providerName) {
    switch (providerName) {
      case 'OpenAI':
        return Icons.auto_awesome;
      case '百度文心一言':
        return Icons.psychology;
      case '讯飞星火':
        return Icons.record_voice_over;
      default:
        return Icons.smart_toy;
    }
  }
  
  /// 获取提供商颜色
  static Color getProviderColor(String providerName) {
    switch (providerName) {
      case 'OpenAI':
        return Colors.green;
      case '百度文心一言':
        return Colors.blue;
      case '讯飞星火':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
  
  /// 截断文本
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}