import 'dart:async';
import 'dart:math';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

/// 抖音登录服务
/// 
/// 提供抖音OAuth2.0登录功能
/// 使用抖音开放平台的授权登录API
class DouyinAuthService {
  DouyinAuthService._();
  
  static final DouyinAuthService _instance = DouyinAuthService._();
  static DouyinAuthService get instance => _instance;
  
  /// 抖音应用Client Key
  static const String clientKey = 'aws8ujfhmwybxv72';
  
  /// 抖音应用Client Secret (应该在后端保存，这里仅用于演示)
  static const String clientSecret = '5a4aea1685c0ba05b7d22b6c2372cc47';
  
  /// 抖音授权登录的基础URL
  static const String authBaseUrl = 'https://open.douyin.com/platform/oauth/connect';
  
  /// 抖音API基础URL
  static const String apiBaseUrl = 'https://open.douyin.com';
  
  /// 生成抖音登录授权URL
  String generateAuthUrl() {
    final state = _generateRandomState();
    final redirectUri = Uri.encodeComponent('https://your-app.com/auth/douyin/callback');
    
    return '$authBaseUrl'
        '?client_key=$clientKey'
        '&response_type=code'
        '&scope=user_info'
        '&redirect_uri=$redirectUri'
        '&state=$state';
  }
  
  /// 通过授权码获取访问令牌
  Future<FlowyResult<Map<String, dynamic>, FlowyError>> getAccessToken(String code) async {
    try {
      // 这里应该调用后端API来处理授权码
      // 避免在前端暴露client_secret
      
      // 示例实现 - 实际应该调用后端API
      final response = await _callBackendAPI('/auth/douyin/token', {
        'code': code,
        'client_key': clientKey,
      });
      
      if (response['access_token'] != null) {
        return FlowyResult.success(response);
      } else {
        return FlowyResult.failure(
          FlowyError()..msg = '获取抖音访问令牌失败',
        );
      }
    } catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = '抖音登录失败: $e',
      );
    }
  }
  
  /// 获取抖音用户信息
  Future<FlowyResult<Map<String, dynamic>, FlowyError>> getUserInfo(
    String accessToken, 
    String openId
  ) async {
    try {
      // 调用后端API获取用户信息
      final response = await _callBackendAPI('/auth/douyin/userinfo', {
        'access_token': accessToken,
        'open_id': openId,
      });
      
      return FlowyResult.success(response);
    } catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = '获取抖音用户信息失败: $e',
      );
    }
  }
  
  /// 显示抖音登录对话框
  Future<FlowyResult<UserProfilePB, FlowyError>> showDouyinLoginDialog(BuildContext context) async {
    final completer = Completer<FlowyResult<UserProfilePB, FlowyError>>();
    
    unawaited(showDialog(
      context: context,
      builder: (BuildContext context) {
        return DouyinLoginDialog(
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

  /// 执行抖音登录（不需要context的版本）
  Future<FlowyResult<UserProfilePB, FlowyError>> performDouyinLogin() async {
    try {
      // 模拟抖音登录流程
      // 在实际应用中，这里应该调用抖音SDK或打开抖音登录页面
      
      // 模拟延迟
      await Future.delayed(const Duration(seconds: 2));
      
      // 模拟登录成功，创建用户资料
      final userProfile = UserProfilePB()
        ..name = '抖音用户'
        ..email = 'douyin_user@xiaomabiji.com'
        ..iconUrl = 'https://example.com/douyin_avatar.jpg';
      
      return FlowyResult.success(userProfile);
    } catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = '抖音登录失败: $e',
      );
    }
  }
  
  /// 生成随机状态码
  String _generateRandomState() {
    final random = Random();
    return List.generate(16, (index) => random.nextInt(16).toRadixString(16)).join();
  }
  
  /// 调用后端API (示例实现)
  Future<Map<String, dynamic>> _callBackendAPI(String endpoint, Map<String, String> params) async {
    // 这里应该实现实际的HTTP请求到您的后端
    // 示例返回模拟数据
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'access_token': 'mock_douyin_access_token',
      'open_id': 'mock_douyin_openid',
      'nickname': '抖音用户',
      'avatar': 'https://example.com/douyin_avatar.jpg',
      'expires_in': 7200,
    };
  }
}

/// 抖音登录对话框
class DouyinLoginDialog extends StatefulWidget {
  const DouyinLoginDialog({
    super.key,
    required this.onLoginSuccess,
    required this.onLoginError,
    required this.onCancel,
  });

  final Function(UserProfilePB) onLoginSuccess;
  final Function(FlowyError) onLoginError;
  final VoidCallback onCancel;
  
  @override
  State<DouyinLoginDialog> createState() => _DouyinLoginDialogState();
}

class _DouyinLoginDialogState extends State<DouyinLoginDialog> {
  late String authUrl;
  bool isLoading = false;
  String statusText = '正在加载授权页面...';
  
  @override
  void initState() {
    super.initState();
    authUrl = DouyinAuthService.instance.generateAuthUrl();
    _simulateLoginProcess();
  }
  
  /// 模拟登录过程 (实际实现中应该打开浏览器或WebView)
  void _simulateLoginProcess() {
    setState(() {
      statusText = '请在弹出的浏览器窗口中完成抖音登录';
      isLoading = true;
    });
    
    // 模拟用户在浏览器中完成登录
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          statusText = '正在处理登录信息...';
        });
        
        // 模拟获取用户信息并登录成功
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _simulateLoginSuccess();
          }
        });
      }
    });
  }
  
  /// 模拟登录成功
  void _simulateLoginSuccess() {
    final userProfile = UserProfilePB()
      ..name = '抖音用户'
      ..email = 'douyin_user@xiaomabiji.com';

    widget.onLoginSuccess(userProfile);
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.music_note, color: Color(0xFFFF0050)),
          SizedBox(width: 8),
          Text('抖音登录'),
        ],
      ),
      content: SizedBox(
        width: 350,
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 抖音Logo区域
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF0050).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFFFF0050),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.music_note,
                size: 60,
                color: Color(0xFFFF0050),
              ),
            ),
            const SizedBox(height: 30),
            
            // 状态文本
            Text(
              statusText,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // 加载指示器
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF0050)),
                ),
              ),
            
            const SizedBox(height: 20),
            const Text(
              '系统将自动打开浏览器进行授权\n(演示版本将在5秒后自动登录)',
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
