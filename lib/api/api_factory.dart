import '../models/provider.dart';
import 'base_api.dart';
import 'providers/openai_api.dart';
import 'providers/baidu_wenxin_api.dart';
import 'providers/xunfei_spark_api.dart';

/// API工厂类
/// 负责根据提供商类型创建对应的API实例
class ApiFactory {
  /// 创建API实例
  static BaseApi createApi(Provider provider) {
    switch (provider.name) {
      case 'OpenAI':
        return OpenAIApi(provider);
      case '百度文心一言':
        return BaiduWenxinApi(provider);
      case '讯飞星火':
        return XunfeiSparkApi(provider);
      default:
        throw Exception('不支持的API提供商: ${provider.name}');
    }
  }
  
  /// 获取所有支持的提供商
  static List<Provider> getSupportedProviders() {
    return [
      Provider.openAI(),
      Provider.baiduWenxin(),
      Provider.xunfeiSpark(),
    ];
  }
}