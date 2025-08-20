import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/auth/device_id.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 抖音OAuth登录服务
class DouyinAuthService {
  static const String _baseUrl = 'https://open.douyin.com';
  static const String clientKey = 'aws8ujfhmwybxv72';
  static const String clientSecret = 'your_client_secret_here'; // 需要从抖音开放平台获取
  
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
            msg: LocaleKeys.signIn_invalidUrl.tr(),
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
      
      final tokenData = tokenResult.getSuccess();
      final accessToken = tokenData['access_token'] as String;
      final openId = tokenData['open_id'] as String;
      
      // 2. 获取用户信息
      final userInfoResult = await _getUserInfo(accessToken, openId);
      if (userInfoResult.isFailure) {
        return FlowyResult.failure(userInfoResult.getFailure());
      }
      
      final userInfo = userInfoResult.getSuccess();
      
      // 3. 构建用户资料
      final profile = UserProfilePB()
        ..id = Int64.parseInt(openId)
        ..email = userInfo['email'] ?? ''
        ..name = userInfo['nickname'] ?? 'Douyin User'
        ..iconUrl = userInfo['avatar'] ?? ''
        ..openaiKey = ''
        ..stabilityAiKey = '';
      
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
  
  /// 清理资源
  void dispose() {
    // 清理相关资源
  }
}
