import 'dart:async';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

/// 微信登录工具类
/// 
/// 提供微信扫码登录的基本功能
/// 注意：这是一个示例实现，实际使用时需要：
/// 1. 在微信开放平台申请应用并获得AppID和AppSecret
/// 2. 配置服务器端接口处理微信OAuth回调
/// 3. 实现真正的二维码生成和扫码检测逻辑
class WeChatLoginUtil {
  /// 显示微信登录对话框
  static Future<FlowyResult<UserProfilePB, FlowyError>> showWeChatLogin(
    BuildContext context,
  ) async {
    // 显示微信登录对话框
    final result = await showDialog<FlowyResult<UserProfilePB, FlowyError>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const WeChatLoginDialog(),
    );
    
    return result ?? FlowyResult.failure(
      FlowyError()..msg = '用户取消登录',
    );
  }

  /// 生成微信二维码URL（示例）
  static String generateQRCodeUrl() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'https://open.weixin.qq.com/connect/qrconnect'
        '?appid=YOUR_WECHAT_APPID'
        '&redirect_uri=YOUR_CALLBACK_URL'
        '&response_type=code'
        '&scope=snsapi_login'
        '&state=login_$timestamp'
        '#wechat_redirect';
  }
}

/// 微信登录对话框
class WeChatLoginDialog extends StatefulWidget {
  const WeChatLoginDialog({super.key});

  @override
  State<WeChatLoginDialog> createState() => _WeChatLoginDialogState();
}

class _WeChatLoginDialogState extends State<WeChatLoginDialog> {
  final String statusText = '请使用微信扫描二维码登录';

  @override
  void initState() {
    super.initState();
    _simulateLoginAfterDelay();
  }

  void _simulateLoginAfterDelay() {
    // 模拟3秒后自动登录成功
    _simulateLoginSuccess();
  }

  void _simulateLoginSuccess() {
    // 模拟登录成功
    final userProfile = UserProfilePB()
      ..name = '微信用户'
      ..email = 'wechat_user@xiaomabiji.com';

    Navigator.of(context).pop(
      FlowyResult.success(userProfile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.chat, color: Color(0xFF07C160)),
          SizedBox(width: 8),
          Text('微信扫码登录'),
        ],
      ),
      content: SizedBox(
        width: 300,
        height: 350,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 二维码区域
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 80,
                    color: Color(0xFF07C160),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '微信二维码',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '扫码后请在手机上确认登录\n(演示版本将在3秒后自动登录)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              FlowyResult.failure(
                FlowyError()..msg = '用户取消登录',
              ),
            );
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
} 