import 'package:flutter/material.dart';
import '../../api/api_factory.dart';
import '../../models/provider.dart';
import '../../services/provider_service.dart';

class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({Key? key}) : super(key: key);
  
  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  final ProviderService _providerService = ProviderService();
  List<Provider> _providers = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadProviders();
  }
  
  Future<void> _loadProviders() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初始化默认提供商
      await _providerService.initDefaultProviders();
      
      // 加载所有提供商
      final providers = await _providerService.getAllProviders();
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      _showErrorSnackBar('加载提供商失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _editProvider(Provider provider) async {
    final result = await Navigator.push<Provider>(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderEditScreen(provider: provider),
      ),
    );
    
    if (result != null) {
      await _loadProviders();
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI服务提供商设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _providers.length,
              itemBuilder: (context, index) {
                final provider = _providers[index];
                return ListTile(
                  title: Text(provider.name),
                  subtitle: Text(provider.apiKey.isEmpty ? '未配置' : '已配置'),
                  leading: CircleAvatar(
                    child: Text(provider.name[0]),
                  ),
                  trailing: Switch(
                    value: provider.isActive,
                    onChanged: (value) async {
                      final updatedProvider = provider.copyWith(isActive: value);
                      await _providerService.updateProvider(updatedProvider);
                      await _loadProviders();
                    },
                  ),
                  onTap: () => _editProvider(provider),
                );
              },
            ),
    );
  }
}

class ProviderEditScreen extends StatefulWidget {
  final Provider provider;
  
  const ProviderEditScreen({Key? key, required this.provider}) : super(key: key);
  
  @override
  State<ProviderEditScreen> createState() => _ProviderEditScreenState();
}

class _ProviderEditScreenState extends State<ProviderEditScreen> {
  final ProviderService _providerService = ProviderService();
  final _formKey = GlobalKey<FormState>();
  late Provider _provider;
  bool _isLoading = false;
  bool _isValidating = false;
  
  @override
  void initState() {
    super.initState();
    _provider = widget.provider;
  }
  
  Future<void> _saveProvider() async {
    if (!_formKey.currentState!.validate()) return;
    
    _formKey.currentState!.save();
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _providerService.updateProvider(_provider);
      if (mounted) {
        Navigator.pop(context, _provider);
      }
    } catch (e) {
      _showErrorSnackBar('保存提供商失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _validateApiKey() async {
    setState(() {
      _isValidating = true;
    });
    
    try {
      final isValid = await _providerService.validateProviderApiKey(_provider);
      _showSnackBar(
        isValid ? '验证成功' : '验证失败，请检查API密钥和其他配置',
        isValid ? Colors.green : Colors.red,
      );
    } catch (e) {
      _showErrorSnackBar('验证API密钥失败: $e');
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
  
  Widget _buildConfigField(String key, Map<String, dynamic> config) {
    final type = config['type'] as String;
    final label = config['label'] as String;
    final required = config['required'] as bool? ?? false;
    
    switch (type) {
      case 'text':
      case 'password':
        return TextFormField(
          initialValue: _provider.config[key] as String? ?? '',
          decoration: InputDecoration(
            labelText: label,
            hintText: '请输入$label',
          ),
          obscureText: type == 'password',
          validator: required
              ? (value) => value == null || value.isEmpty ? '$label不能为空' : null
              : null,
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              _provider = _provider.copyWith(
                config: {..._provider.config, key: value},
              );
            }
          },
        );
      case 'select':
        final options = config['options'] as List<dynamic>;
        final defaultValue = config['default'];
        final currentValue = _provider.config[key] ?? defaultValue;
        
        return DropdownButtonFormField<String>(
          value: currentValue as String?,
          decoration: InputDecoration(
            labelText: label,
          ),
          items: options.map((option) {
            final label = option['label'] as String;
            final value = option['value'] as String;
            return DropdownMenuItem<String>(
              value: value,
              child: Text(label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _provider = _provider.copyWith(
                config: {..._provider.config, key: value},
              );
            });
          },
          validator: required
              ? (value) => value == null || value.isEmpty ? '$label不能为空' : null
              : null,
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              _provider = _provider.copyWith(
                config: {..._provider.config, key: value},
              );
            }
          },
        );
      case 'slider':
        final min = config['min'] as double;
        final max = config['max'] as double;
        final step = config['step'] as double;
        final defaultValue = config['default'] as double;
        final currentValue = (_provider.config[key] as num?)?.toDouble() ?? defaultValue;
        
        return FormField<double>(
          initialValue: currentValue,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: state.value!,
                        min: min,
                        max: max,
                        divisions: ((max - min) / step).round(),
                        label: state.value!.toStringAsFixed(1),
                        onChanged: (value) {
                          state.didChange(value);
                          setState(() {
                            _provider = _provider.copyWith(
                              config: {..._provider.config, key: value},
                            );
                          });
                        },
                      ),
                    ),
                    Text(state.value!.toStringAsFixed(1)),
                  ],
                ),
                if (state.hasError)
                  Text(
                    state.errorText!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            );
          },
          validator: required
              ? (value) => value == null ? '$label不能为空' : null
              : null,
          onSaved: (value) {
            if (value != null) {
              _provider = _provider.copyWith(
                config: {..._provider.config, key: value},
              );
            }
          },
        );
      case 'number':
        final min = config['min'] as int?;
        final max = config['max'] as int?;
        final defaultValue = config['default'] as int;
        final currentValue = (_provider.config[key] as int?) ?? defaultValue;
        
        return TextFormField(
          initialValue: currentValue.toString(),
          decoration: InputDecoration(
            labelText: label,
            hintText: '请输入$label',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return '$label不能为空';
            }
            if (value != null && value.isNotEmpty) {
              final intValue = int.tryParse(value);
              if (intValue == null) {
                return '$label必须是数字';
              }
              if (min != null && intValue < min) {
                return '$label不能小于$min';
              }
              if (max != null && intValue > max) {
                return '$label不能大于$max';
              }
            }
            return null;
          },
          onSaved: (value) {
            if (value != null && value.isNotEmpty) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                _provider = _provider.copyWith(
                  config: {..._provider.config, key: intValue},
                );
              }
            }
          },
        );
      default:
        return Container();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 获取API实例以获取配置选项
    final api = ApiFactory.createApi(_provider);
    final configOptions = api.getConfigOptions();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${_provider.name}设置'),
        actions: [
          if (_isValidating)
            const Center(child: CircularProgressIndicator()),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _validateApiKey,
            tooltip: '验证API密钥',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    initialValue: _provider.apiKey,
                    decoration: const InputDecoration(
                      labelText: 'API密钥',
                      hintText: '请输入API密钥',
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'API密钥不能为空' : null,
                    onSaved: (value) {
                      if (value != null) {
                        _provider = _provider.copyWith(apiKey: value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _provider.baseUrl,
                    decoration: const InputDecoration(
                      labelText: '基础URL',
                      hintText: '请输入基础URL',
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? '基础URL不能为空' : null,
                    onSaved: (value) {
                      if (value != null) {
                        _provider = _provider.copyWith(baseUrl: value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    '高级设置',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...configOptions.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildConfigField(entry.key, entry.value),
                    );
                  }).toList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProvider,
        child: const Icon(Icons.save),
      ),
    );
  }