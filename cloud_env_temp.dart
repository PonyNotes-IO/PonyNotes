// 临时测试配置 - 使用IP地址直接访问
// 将此配置复制到 cloud_env.dart 中进行测试

// PonyNotes 云服务的临时API URL（使用IP地址直接访问）
const String kAppflowyCloudUrl = "http://8.152.101.166:8081";

/// 获取AppFlowy Cloud URL
Future<String> getAppFlowyCloudUrl() async {
  final result = await getIt<KeyValueStorage>().get(KVKeys.kAppflowyCloudBaseURL);
  return result ?? kAppflowyCloudUrl;
}

/// 获取AppFlowy Cloud WebSocket URL
Future<String> _getAppFlowyCloudWSUrl(String baseURL) async {
  try {
    final uri = Uri.parse(baseURL);
    final wsScheme = uri.isScheme('HTTPS') ? 'wss' : 'ws';
    final wsUrl = Uri(scheme: wsScheme, host: uri.host, port: uri.port, path: '/ws/v1');
    return wsUrl.toString();
  } catch (e) {
    Log.error("Failed to get WebSocket URL: $e");
    return "";
  }
}

/// 获取AppFlowy Cloud GoTrue URL
Future<String> _getAppFlowyCloudGotrueUrl(String baseURL) async {
  return "$baseURL/gotrue";
}

/// 配置AppFlowy Cloud开发环境
Future<AppFlowyCloudConfiguration> configurationFromUri(
  Uri baseUri,
  String baseUrl,
  AuthenticatorType authenticatorType,
  String baseShareDomain,
) async {
  // 临时测试配置
  return AppFlowyCloudConfiguration(
    base_url: baseUrl,
    ws_base_url: await _getAppFlowyCloudWSUrl(baseUrl),
    gotrue_url: await _getAppFlowyCloudGotrueUrl(baseUrl),
    enable_sync_trace: true,
    base_web_domain: ShareConstants.testBaseWebDomain,
  );
}

/// 使用临时配置
Future<void> useTempAppFlowyCloud() async {
  await _setAuthenticatorType(AuthenticatorType.appflowyCloudDevelop);
  await _setAppFlowyCloudUrl("http://8.152.101.166:8081");
}

// 测试步骤：
// 1. 将此配置复制到 cloud_env.dart
// 2. 在PonyNotes客户端中测试注册/登录
// 3. 检查是否能成功连接和认证
// 4. 如果成功，再修复域名访问问题 