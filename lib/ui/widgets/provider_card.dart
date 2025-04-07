import 'package:flutter/material.dart';
import '../../models/provider.dart';
import '../themes/app_theme.dart';

/// 提供商卡片组件
/// 用于在设置界面中显示AI服务提供商
class ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onTest;
  
  const ProviderCard({
    Key? key,
    required this.provider,
    required this.onEdit,
    required this.onActiveChanged,
    this.onDelete,
    this.onTest,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasApiKey = provider.apiKey.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 提供商图标
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    provider.name[0],
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                // 提供商名称和状态
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasApiKey ? '已配置' : '未配置',
                        style: TextStyle(
                          color: hasApiKey
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 激活开关
                Switch(
                  value: provider.isActive,
                  onChanged: onActiveChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 提供商配置信息
            if (hasApiKey) ...[              
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '配置信息',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildConfigItem(context, '基础URL', provider.baseUrl),
              if (provider.config.isNotEmpty) ...
                provider.config.entries.map(
                  (entry) => _buildConfigItem(
                    context,
                    _formatConfigKey(entry.key),
                    _formatConfigValue(entry.value),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onTest != null && hasApiKey)
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('测试'),
                    onPressed: onTest,
                  ),
                const SizedBox(width: 8),
                if (onDelete != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    onPressed: onDelete,
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                  onPressed: onEdit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfigItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              label.toLowerCase().contains('key') || 
              label.toLowerCase().contains('secret') ? 
              '******' : value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatConfigKey(String key) {
    // 将snake_case转换为Title Case
    return key.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  String _formatConfigValue(dynamic value) {
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? '是' : '否';
    return value.toString();
  }
}