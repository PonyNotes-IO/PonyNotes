# PonyNotes 客户端集成指南

## 📱 客户端配置

### 1. 更新 API 地址
确保客户端使用正确的服务器地址：

```dart
// frontend/appflowy_flutter/lib/env/cloud_env.dart
const String kAppflowyCloudUrl = "https://api.xiaomabiji.com";
```

### 2. 邮箱验证流程处理

#### 注册流程
```dart
// 用户注册
Future<void> registerUser(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$kAppflowyCloudUrl/gotrue/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      // 注册成功，显示邮箱验证提示
      showEmailVerificationDialog();
    } else {
      // 处理注册错误
      handleRegistrationError(response);
    }
  } catch (e) {
    // 处理网络错误
    handleNetworkError(e);
  }
}
```

#### 登录流程
```dart
// 用户登录
Future<void> loginUser(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$kAppflowyCloudUrl/gotrue/token?grant_type=password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      // 登录成功，保存 token
      final data = jsonDecode(response.body);
      await saveAuthToken(data['access_token']);
      navigateToMainScreen();
    } else {
      final error = jsonDecode(response.body);
      if (error['error_code'] == 'email_not_confirmed') {
        // 邮箱未验证，显示验证提示
        showEmailNotVerifiedDialog();
      } else {
        // 处理其他登录错误
        handleLoginError(error);
      }
    }
  } catch (e) {
    // 处理网络错误
    handleNetworkError(e);
  }
}
```

## 🎨 用户界面设计

### 1. 注册成功页面
```dart
Widget buildRegistrationSuccessPage() {
  return Scaffold(
    appBar: AppBar(title: Text('注册成功')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email, size: 64, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            '验证邮件已发送',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            '请检查您的邮箱并点击验证链接',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => openEmailApp(),
            child: Text('打开邮箱'),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () => resendVerificationEmail(),
            child: Text('重新发送验证邮件'),
          ),
        ],
      ),
    ),
  );
}
```

### 2. 邮箱未验证提示
```dart
Widget buildEmailNotVerifiedDialog() {
  return AlertDialog(
    title: Text('邮箱未验证'),
    content: Text('请先验证您的邮箱地址，然后重新登录。'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('取消'),
      ),
      ElevatedButton(
        onPressed: () => resendVerificationEmail(),
        child: Text('重新发送验证邮件'),
      ),
    ],
  );
}
```

## 🔧 错误处理

### 1. 常见错误码
```dart
class AuthErrorHandler {
  static void handleError(Map<String, dynamic> error) {
    switch (error['error_code']) {
      case 'email_not_confirmed':
        showEmailNotVerifiedDialog();
        break;
      case 'invalid_credentials':
        showInvalidCredentialsDialog();
        break;
      case 'user_not_found':
        showUserNotFoundDialog();
        break;
      case 'over_email_send_rate_limit':
        showRateLimitDialog();
        break;
      default:
        showGenericErrorDialog(error['msg']);
    }
  }
}
```

### 2. 网络错误处理
```dart
void handleNetworkError(dynamic error) {
  if (error is SocketException) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('网络连接错误'),
        content: Text('请检查网络连接后重试'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

## 📧 邮件相关功能

### 1. 重新发送验证邮件
```dart
Future<void> resendVerificationEmail(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$kAppflowyCloudUrl/gotrue/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': 'dummy_password', // 如果用户已存在，密码会被忽略
      }),
    );
    
    if (response.statusCode == 200) {
      showSnackBar('验证邮件已重新发送');
    } else {
      final error = jsonDecode(response.body);
      if (error['error_code'] == 'over_email_send_rate_limit') {
        showSnackBar('发送过于频繁，请稍后再试');
      }
    }
  } catch (e) {
    handleNetworkError(e);
  }
}
```

### 2. 魔法链接功能
```dart
Future<void> sendMagicLink(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$kAppflowyCloudUrl/gotrue/magiclink'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    
    if (response.statusCode == 200) {
      showSnackBar('魔法链接已发送到您的邮箱');
    } else {
      final error = jsonDecode(response.body);
      handleError(error);
    }
  } catch (e) {
    handleNetworkError(e);
  }
}
```

## 🔐 Token 管理

### 1. 保存认证 Token
```dart
class AuthTokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  static Future<void> saveAuthToken(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }
  
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }
}
```

### 2. API 请求拦截器
```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await AuthTokenManager.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token 过期，清除本地存储并跳转到登录页
      await AuthTokenManager.clearAuthToken();
      navigateToLoginScreen();
    }
    handler.next(err);
  }
}
```

## 📋 测试清单

### 客户端功能测试
- [ ] 用户注册流程
- [ ] 邮箱验证提示
- [ ] 未验证用户登录拒绝
- [ ] 验证后用户登录成功
- [ ] 重新发送验证邮件
- [ ] 魔法链接功能
- [ ] Token 管理
- [ ] 错误处理

### 用户体验测试
- [ ] 注册成功页面显示
- [ ] 邮箱验证提示清晰
- [ ] 错误信息友好
- [ ] 加载状态显示
- [ ] 网络错误处理

## 🚀 部署建议

### 1. 生产环境配置
- 使用 HTTPS 连接
- 配置正确的域名
- 设置适当的超时时间
- 实现错误监控

### 2. 用户体验优化
- 添加加载动画
- 实现离线模式
- 优化错误提示
- 支持多语言

## 📞 技术支持

如果遇到问题：
1. 检查网络连接
2. 验证 API 地址配置
3. 查看错误日志
4. 确认邮箱验证状态

**当前状态**: 邮箱验证功能已完全配置，客户端可以开始集成！🎉 