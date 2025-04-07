import '../api/api_factory.dart';
import '../models/provider.dart';
import 'database_service.dart';

/// 提供商服务类
/// 负责管理AI服务提供商的配置
class ProviderService {
  final DatabaseService _databaseService = DatabaseService();
  
  /// 初始化默认提供商
  Future<void> initDefaultProviders() async {
    final providers = await _databaseService.getAllProviders();
    
    // 如果没有提供商，添加默认提供商
    if (providers.isEmpty) {
      final defaultProviders = ApiFactory.getSupportedProviders();
      for (final provider in defaultProviders) {
        await _databaseService.upsertProvider(provider);
      }
    }
  }
  
  /// 获取所有提供商
  Future<List<Provider>> getAllProviders() async {
    return await _databaseService.getAllProviders();
  }
  
  /// 获取指定ID的提供商
  Future<Provider?> getProviderById(String id) async {
    return await _databaseService.getProviderById(id);
  }
  
  /// 更新提供商
  Future<void> updateProvider(Provider provider) async {
    await _databaseService.upsertProvider(provider);
  }
  
  /// 删除提供商
  Future<void> deleteProvider(String id) async {
    await _databaseService.deleteProvider(id);
  }
  
  /// 验证提供商API密钥
  Future<bool> validateProviderApiKey(Provider provider) async {
    try {
      final api = ApiFactory.createApi(provider);
      return await api.validateApiKey();
    } catch (e) {
      return false;
    }
  }
}