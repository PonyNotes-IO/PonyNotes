# 🔧 验证码问题修复指南

## 🎯 问题描述
用户收到验证码后，正确填写但系统返回 "The code has expired or is invalid" 错误。

## 🔍 根本原因
通过分析 GoTrue 服务器日志发现：
```
{"component":"api","error":"400: Only an email address or phone number should be provided on verify"}
```

**问题**: 客户端在调用 `/gotrue/verify` 接口时，只发送了验证码，没有发送邮箱地址。

## ✅ 解决方案

### 1. 修改验证请求格式

#### ❌ 错误的调用方式
```dart
Future<void> verifyCode(String code) async {
  final response = await http.post(
    Uri.parse('$kAppflowyCloudUrl/gotrue/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'token': code,  // 只发送验证码
    }),
  );
}
```

#### ✅ 正确的调用方式
```dart
Future<void> verifyCode(String email, String code) async {
  final response = await http.post(
    Uri.parse('$kAppflowyCloudUrl/gotrue/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,     // 添加邮箱地址
      'token': code,      // 验证码
      'type': 'signup',   // 验证类型
    }),
  );
}
```

### 2. 更新验证页面

```dart
class VerificationPage extends StatefulWidget {
  final String email;  // 添加邮箱参数
  
  const VerificationPage({Key? key, required this.email}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('邮箱验证')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 64, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              '验证码已发送',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '请检查您的邮箱: ${widget.email}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '验证码',
                border: OutlineInputBorder(),
                hintText: '请输入6位验证码',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => verifyCode(widget.email, _codeController.text),
                child: Text('验证邮箱'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => resendVerificationCode(widget.email),
              child: Text('重新发送验证码'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. 完整的验证服务

```dart
class EmailVerificationService {
  static const String _baseUrl = "https://api.xiaomabiji.com";
  
  /// 验证邮箱
  static Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/gotrue/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': code,
          'type': 'signup',
        }),
      );
      
      if (response.statusCode == 200) {
        // 验证成功
        return true;
      } else {
        final error = jsonDecode(response.body);
        _handleVerificationError(error);
        return false;
      }
    } catch (e) {
      _handleNetworkError(e);
      return false;
    }
  }
  
  /// 重新发送验证码
  static Future<bool> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/gotrue/magiclink'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      _handleNetworkError(e);
      return false;
    }
  }
  
  /// 处理验证错误
  static void _handleVerificationError(Map<String, dynamic> error) {
    final errorCode = error['error_code'];
    final message = error['msg'] ?? '验证失败';
    
    switch (errorCode) {
      case 'validation_failed':
        _showErrorDialog('验证失败', '请确保输入了正确的邮箱地址和验证码');
        break;
      case 'token_expired':
        _showErrorDialog('验证码已过期', '请重新发送验证码');
        break;
      case 'invalid_token':
        _showErrorDialog('验证码错误', '请检查验证码是否正确');
        break;
      default:
        _showErrorDialog('验证失败', message);
    }
  }
  
  /// 处理网络错误
  static void _handleNetworkError(dynamic error) {
    _showErrorDialog('网络错误', '请检查网络连接后重试');
  }
  
  /// 显示错误对话框
  static void _showErrorDialog(String title, String message) {
    // 使用 GetX 或其他状态管理工具显示对话框
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }
}
```

### 4. 注册流程更新

```dart
class RegistrationService {
  static const String _baseUrl = "https://api.xiaomabiji.com";
  
  /// 用户注册
  static Future<Map<String, dynamic>?> registerUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/gotrue/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        _handleRegistrationError(error);
        return null;
      }
    } catch (e) {
      _handleNetworkError(e);
      return null;
    }
  }
  
  /// 处理注册错误
  static void _handleRegistrationError(Map<String, dynamic> error) {
    final errorCode = error['error_code'];
    final message = error['msg'] ?? '注册失败';
    
    switch (errorCode) {
      case 'user_exists':
        _showErrorDialog('用户已存在', '该邮箱已被注册，请直接登录');
        break;
      case 'weak_password':
        _showErrorDialog('密码强度不足', '请设置更强的密码');
        break;
      default:
        _showErrorDialog('注册失败', message);
    }
  }
}
```

### 5. 导航流程更新

```dart
class AuthNavigationService {
  /// 注册成功后跳转到验证页面
  static void navigateToVerification(String email) {
    Get.off(() => VerificationPage(email: email));
  }
  
  /// 验证成功后跳转到主页面
  static void navigateToMain() {
    Get.offAll(() => MainPage());
  }
  
  /// 返回登录页面
  static void navigateToLogin() {
    Get.offAll(() => LoginPage());
  }
}
```

## 🧪 测试步骤

### 1. 测试注册流程
```dart
// 测试注册
final result = await RegistrationService.registerUser(
  'test@example.com',
  'password123'
);

if (result != null) {
  // 注册成功，跳转到验证页面
  AuthNavigationService.navigateToVerification('test@example.com');
}
```

### 2. 测试验证流程
```dart
// 测试验证
final success = await EmailVerificationService.verifyEmail(
  'test@example.com',
  '123456'  // 从邮箱获取的验证码
);

if (success) {
  // 验证成功，跳转到主页面
  AuthNavigationService.navigateToMain();
}
```

## 📋 修复检查清单

- [ ] 修改验证请求，添加邮箱地址参数
- [ ] 更新验证页面，传递邮箱参数
- [ ] 实现完整的错误处理
- [ ] 测试注册 → 验证 → 登录完整流程
- [ ] 验证错误信息显示正确
- [ ] 测试重新发送验证码功能

## 🚀 部署建议

1. **测试环境**: 先在测试环境验证修复
2. **用户通知**: 通知用户重新注册或验证
3. **监控日志**: 监控验证成功率
4. **回滚计划**: 准备回滚方案

## 📞 技术支持

如果修复后仍有问题：
1. 检查网络连接
2. 查看服务器日志
3. 确认邮箱地址格式
4. 验证验证码时效性

**当前状态**: 问题已定位，按照上述方案修复客户端代码即可解决！🎯 