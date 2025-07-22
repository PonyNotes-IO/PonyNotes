import 'dart:async';
import 'dart:math';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

/// 微信登录服务
/// 
/// 提供微信扫码登录功能
/// 注意：这是一个示例实现，需要根据实际的微信开放平台配置进行调整
class WeChatAuthService {
  WeChatAuthService._();
  
  static final WeChatAuthService _instance = WeChatAuthService._();
  static WeChatAuthService get instance => _instance;
  
  /// 微信应用ID (需要在微信开放平台申请)
  static const String appId = 'your_wechat_app_id';
  
  /// 微信应用密钥 (需要在微信开放平台申请)
  static const String appSecret = 'your_wechat_app_secret';
  
  /// 生成微信登录二维码URL
  String generateWeChatQRCodeUrl() {
    final state = _generateRandomState();
    final redirectUri = Uri.encodeComponent('https://your-app.com/auth/wechat/callback');
    
    return 'https://open.weixin.qq.com/connect/qrconnect'
        '?appid=$appId'
        '&redirect_uri=$redirectUri'
        '&response_type=code'
        '&scope=snsapi_login'
        '&state=$state'
        '#wechat_redirect';
  }
  
  /// 通过授权码获取访问令牌
  Future<FlowyResult<String, FlowyError>> getAccessToken(String code) async {
    try {
      // 这里应该调用您的后端API来处理微信授权码
      // 避免在前端暴露app_secret
      
      // 示例实现 - 实际应该调用后端API
      final response = await _callBackendAPI('/auth/wechat/token', {
        'code': code,
        'app_id': appId,
      });
      
      if (response['access_token'] != null) {
        return FlowyResult.success(response['access_token']);
      } else {
        return FlowyResult.failure(
          FlowyError()..msg = '获取微信访问令牌失败',
        );
      }
    } catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = '微信登录失败: $e',
      );
    }
  }
  
  /// 获取微信用户信息
  Future<FlowyResult<Map<String, dynamic>, FlowyError>> getUserInfo(String accessToken, String openId) async {
    try {
      // 调用后端API获取用户信息
      final response = await _callBackendAPI('/auth/wechat/userinfo', {
        'access_token': accessToken,
        'openid': openId,
      });
      
      return FlowyResult.success(response);
    } catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = '获取微信用户信息失败: $e',
      );
    }
  }
  
  /// 显示微信扫码登录对话框
  Future<FlowyResult<UserProfilePB, FlowyError>> showWeChatQRCodeDialog(BuildContext context) async {
    final completer = Completer<FlowyResult<UserProfilePB, FlowyError>>();
    
    unawaited(showDialog(
      context: context,
      builder: (BuildContext context) {
        return WeChatQRCodeDialog(
          onLoginSuccess: (userProfile) {
            Navigator.of(context).pop();
            completer.complete(FlowyResult.success(userProfile));
          },
          onLoginError: (error) {
            Navigator.of(context).pop();
            completer.complete(FlowyResult.failure(error));
          },
          onCancel: () {
            Navigator.of(context).pop();
            completer.complete(FlowyResult.failure(
              FlowyError()..msg = '用户取消登录',
            ));
          },
        );
      },
    ));
    
    return completer.future;
  }
  
  /// 生成随机状态码
  String _generateRandomState() {
    final random = Random();
    return List.generate(16, (index) => random.nextInt(16).toRadixString(16)).join();
  }
  
  /// 调用后端API (示例实现)
  Future<Map<String, dynamic>> _callBackendAPI(String endpoint, Map<String, String> params) async {
    // 这里应该实现实际的HTTP请求
    // 示例返回
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'access_token': 'mock_access_token',
      'openid': 'mock_openid',
      'nickname': '微信用户',
      'headimgurl': 'https://example.com/avatar.jpg',
    };
  }
}

/// 微信扫码登录对话框
class WeChatQRCodeDialog extends StatefulWidget {
  const WeChatQRCodeDialog({
    super.key,
    required this.onLoginSuccess,
    required this.onLoginError,
    required this.onCancel,
  });

  final Function(UserProfilePB) onLoginSuccess;
  final Function(FlowyError) onLoginError;
  final VoidCallback onCancel;
  
  @override
  State<WeChatQRCodeDialog> createState() => _WeChatQRCodeDialogState();
}

class _WeChatQRCodeDialogState extends State<WeChatQRCodeDialog> {
  late String qrCodeUrl;
  final bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    qrCodeUrl = WeChatAuthService.instance.generateWeChatQRCodeUrl();
    _startPollingForAuthResult();
  }
  
  /// 轮询检查登录状态
  void _startPollingForAuthResult() {
    // 实际实现中，您可能需要通过WebSocket或轮询来检查登录状态
    // 这里是一个简化的示例
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // 检查是否有登录回调
      _checkLoginStatus().then((result) {
        if (result.isSuccess) {
          timer.cancel();
          widget.onLoginSuccess(result.fold((s) => s, (f) => throw f));
        } else if (result.isFailure && result.fold((s) => '', (f) => f.msg) != '等待用户扫码') {
          timer.cancel();
          widget.onLoginError(result.fold((s) => FlowyError(), (f) => f));
        }
      });
    });
  }
  
  /// 检查登录状态 (示例实现)
  Future<FlowyResult<UserProfilePB, FlowyError>> _checkLoginStatus() async {
    // 这里应该检查实际的登录状态
    // 示例：总是返回等待状态
    return FlowyResult.failure(FlowyError()..msg = '等待用户扫码');
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('微信扫码登录'),
      content: SizedBox(
        width: 300,
        height: 400,
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
            const Text(
              '请使用微信扫描二维码登录',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
              const Text(
              '扫码后请在手机上确认登录\n(演示版本)',
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
          onPressed: widget.onCancel,
          child: const Text('取消'),
        ),
      ],
    );
  }
} 