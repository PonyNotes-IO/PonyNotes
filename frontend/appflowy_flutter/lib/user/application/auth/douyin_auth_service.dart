import 'dart:async';
import 'dart:convert';

import 'dart:math';

import 'package:appflowy/generated/locale_keys.g.dart';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:fixnum/fixnum.dart';

/// 抖音OAuth登录服务
/// 
/// 提供抖音OAuth2.0登录功能
/// 使用抖音开放平台的授权登录API
class DouyinAuthService {
  static const String _baseUrl = 'https://open.douyin.com';
  static const String clientKey = 'aws8ujfhmwybxv72';
  static const String clientSecret = '5a4aea1685c0ba05b7d22b6c2372cc47'; // 需要从抖音开放平台获取
  
  // 根据环境选择回调地址
  static const String redirectUri = 'ponynotes://auth/douyin/callback';
  
  // 开发环境可以使用localhost
  static const String devRedirectUri = 'http://localhost:3000/auth/douyin/callback';
  
  static const String scope = 'user_info';
  
  static DouyinAuthService? _instance;
  
  static DouyinAuthService get instance {
    _instance ??= DouyinAuthService._internal();
    return _instance!;
  }
  
  DouyinAuthService._internal();
  
  /// 获取当前使用的回调地址
  static String getCurrentRedirectUri() {
    // 在生产环境中使用自定义URL scheme
    // 在开发环境中可以使用localhost
    return kDebugMode ? devRedirectUri : redirectUri;
  }
  
  /// 生成授权URL
  String generateAuthUrl() {
    final state = _generateState();
    final uri = Uri.parse('$_baseUrl/platform/oauth/connect/').replace(
      queryParameters: {
        'client_key': clientKey,
        'response_type': 'code',
        'scope': scope,
        'redirect_uri': getCurrentRedirectUri(),
        'state': state,
      },
    );
    
    return uri.toString();
  }
  
  /// 打开抖音授权页面
  Future<FlowyResult<void, FlowyError>> openAuthUrl() async {
    try {
      final authUrl = generateAuthUrl();
      final uri = Uri.parse(authUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return FlowyResult.success(null);
      } else {
        return FlowyResult.failure(
          FlowyError(
            msg: LocaleKeys.signIn_generalError.tr(),
          ),
        );
      }
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Failed to open auth URL: $e',
        ),
      );
    }
  }
  
  /// 处理授权回调
  Future<FlowyResult<UserProfilePB, FlowyError>> handleAuthCallback({
    required String code,
    required String state,
  }) async {
    try {
      // 1. 用授权码换取访问令牌
      final tokenResult = await _exchangeCodeForToken(code);
      if (tokenResult.isFailure) {
        return FlowyResult.failure(tokenResult.getFailure());
      }
      
      final tokenData = tokenResult.fold((success) => success, (error) => throw error);
      final accessToken = tokenData['access_token'] as String;
      final openId = tokenData['open_id'] as String;
      
      // 2. 获取用户信息
      final userInfoResult = await _getUserInfo(accessToken, openId);
      if (userInfoResult.isFailure) {
        return FlowyResult.failure(userInfoResult.getFailure());
      }
      
      final userInfo = userInfoResult.fold((success) => success, (error) => throw error);
      
      // 3. 构建用户资料
      final profile = UserProfilePB()
        ..id = Int64.parseInt(openId)
        ..email = userInfo['email'] ?? ''
        ..name = userInfo['nickname'] ?? 'Douyin User'
        ..iconUrl = userInfo['avatar'] ?? ''
        ..phoneNumber = '';
      
      return FlowyResult.success(profile);
      
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Auth callback failed: $e',
        ),
      );
    }
  }
  
  /// 用授权码换取访问令牌
  Future<FlowyResult<Map<String, dynamic>, FlowyError>> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/oauth/access_token/'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_key': clientKey,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['error_code'] == 0) {
          return FlowyResult.success(data['data'] as Map<String, dynamic>);
        } else {
          return FlowyResult.failure(
            FlowyError(
              msg: data['description'] ?? 'Token exchange failed',
            ),
          );
        }
      } else {
        return FlowyResult.failure(
          FlowyError(
            msg: 'HTTP ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Token exchange error: $e',
        ),
      );
    }
  }
  
  /// 获取用户信息
  Future<FlowyResult<Map<String, dynamic>, FlowyError>> _getUserInfo(String accessToken, String openId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/userinfo/').replace(
          queryParameters: {
            'access_token': accessToken,
            'open_id': openId,
          },
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['error_code'] == 0) {
          return FlowyResult.success(data['data'] as Map<String, dynamic>);
        } else {
          return FlowyResult.failure(
            FlowyError(
              msg: data['description'] ?? 'Get user info failed',
            ),
          );
        }
      } else {
        return FlowyResult.failure(
          FlowyError(
            msg: 'HTTP ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Get user info error: $e',
        ),
      );
    }
  }
  
  /// 生成随机状态字符串
  String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  /// 验证状态字符串
  bool validateState(String state) {
    // 这里可以实现更复杂的状态验证逻辑
    // 比如检查状态是否在有效期内等
    return state.isNotEmpty && state.length >= 16;
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
  
  /// 清理资源
  void dispose() {
    // 清理相关资源
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
