#!/bin/bash

# 正确的验证码测试脚本
echo "=== 验证码问题修复测试 ==="
echo ""

# 测试邮箱
TEST_EMAIL="87103978@qq.com"

echo "1. 检查当前验证流程..."
echo ""

# 首先发送魔法链接获取验证码
echo "发送魔法链接到: $TEST_EMAIL"
MAGICLINK_RESPONSE=$(curl -s -X POST "https://api.xiaomabiji.com/gotrue/magiclink" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\"}")

echo "魔法链接响应: $MAGICLINK_RESPONSE"
echo ""

echo "2. 正确的验证方式..."
echo ""

echo "⚠️  重要发现:"
echo "GoTrue 的验证接口需要同时提供邮箱地址和验证码"
echo ""
echo "正确的验证请求格式:"
echo "POST /gotrue/verify"
echo "{"
echo "  \"email\": \"$TEST_EMAIL\","
echo "  \"token\": \"YOUR_VERIFICATION_CODE\","
echo "  \"type\": \"signup\""
echo "}"
echo ""

echo "3. 客户端修复建议..."
echo ""

cat << 'EOF'
## 🔧 客户端修复方案

### 问题原因
客户端在调用验证接口时，只发送了验证码，没有发送邮箱地址。

### 修复方法

#### 1. 修改验证请求
```dart
// 错误的调用方式
Future<void> verifyCode(String code) async {
  final response = await http.post(
    Uri.parse('$kAppflowyCloudUrl/gotrue/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'token': code,  // ❌ 只发送验证码
    }),
  );
}

// 正确的调用方式
Future<void> verifyCode(String email, String code) async {
  final response = await http.post(
    Uri.parse('$kAppflowyCloudUrl/gotrue/verify'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,     // ✅ 添加邮箱地址
      'token': code,      // ✅ 验证码
      'type': 'signup',   // ✅ 验证类型
    }),
  );
}
```

#### 2. 更新验证页面
```dart
class VerificationPage extends StatefulWidget {
  final String email;  // 添加邮箱参数
  
  const VerificationPage({Key? key, required this.email}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('邮箱验证')),
      body: Column(
        children: [
          Text('验证码已发送到: ${widget.email}'),
          // 验证码输入框
          TextField(
            controller: _codeController,
            decoration: InputDecoration(labelText: '验证码'),
          ),
          ElevatedButton(
            onPressed: () => verifyCode(widget.email, _codeController.text),
            child: Text('验证'),
          ),
        ],
      ),
    );
  }
}
```

#### 3. 错误处理
```dart
void handleVerificationError(Map<String, dynamic> error) {
  switch (error['error_code']) {
    case 'validation_failed':
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('验证失败'),
          content: Text('请确保输入了正确的邮箱地址和验证码'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
      break;
    case 'token_expired':
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('验证码已过期'),
          content: Text('请重新发送验证码'),
          actions: [
            TextButton(
              onPressed: () => resendVerificationCode(),
              child: Text('重新发送'),
            ),
          ],
        ),
      );
      break;
  }
}
```

### 4. 完整的验证流程
```dart
class EmailVerificationService {
  static Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$kAppflowyCloudUrl/gotrue/verify'),
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
        handleVerificationError(error);
        return false;
      }
    } catch (e) {
      handleNetworkError(e);
      return false;
    }
  }
}
```

EOF

echo ""
echo "4. 测试验证..."
echo ""

echo "请按照以下步骤测试:"
echo "1. 在客户端修改验证请求，添加邮箱地址"
echo "2. 重新发送验证码"
echo "3. 使用正确的格式提交验证"
echo ""

echo "✅ 问题已定位，请按照上述方案修复客户端代码！" 