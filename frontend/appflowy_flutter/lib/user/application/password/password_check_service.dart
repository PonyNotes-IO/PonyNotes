import 'dart:convert';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

/// 通用的密码检查服务
/// 用于登录时和登录后修改密码时检查用户是否有密码
class PasswordCheckService {
  static final http.Client _client = http.Client();

  /// 检查用户是否有自定义密码
  ///
  /// [email] - 用户邮箱
  /// [authToken] - 认证令牌（可选，用于已登录用户）
  ///
  /// 返回 true 表示用户有自定义密码，false 表示用户没有自定义密码
  static Future<FlowyResult<bool, FlowyError>> checkUserHasCustomPassword({
    required String email,
    String? authToken,
  }) async {
    try {
      final baseUrl = await getAppFlowyCloudUrl();
      final uri = Uri.parse('$baseUrl/api/user/auth-info?email=$email');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // 如果提供了认证令牌，添加到请求头
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client
          .get(
            uri,
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] as Map<String, dynamic>?;

        if (responseData != null) {
          final hasCustomPassword = responseData['has_custom_password'] == true;
          return FlowyResult.success(hasCustomPassword);
        } else {
          return FlowyResult.failure(
            FlowyError(msg: 'Invalid response format from server'),
          );
        }
      } else {
        return FlowyResult.failure(
          FlowyError(
              msg: 'Failed to check password status: ${response.statusCode}'),
        );
      }
    } catch (e) {
      Log.error('PasswordCheckService: checkUserHasCustomPassword error: $e');
      return FlowyResult.failure(
        FlowyError(msg: 'Network error: ${e.toString()}'),
      );
    }
  }

  /// 获取完整的用户认证信息
  ///
  /// [email] - 用户邮箱
  /// [authToken] - 认证令牌（可选，用于已登录用户）
  ///
  /// 返回包含用户存在状态和密码状态的完整信息
  static Future<FlowyResult<UserAuthInfo, FlowyError>> getUserAuthInfo({
    required String email,
    String? authToken,
  }) async {
    try {
      final baseUrl = await getAppFlowyCloudUrl();
      final uri = Uri.parse('$baseUrl/api/user/auth-info?email=$email');

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // 如果提供了认证令牌，添加到请求头
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _client
          .get(
            uri,
            headers: headers,
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] as Map<String, dynamic>?;

        if (responseData != null) {
          final userAuthInfo = UserAuthInfo(
            exists: responseData['exists'] == true,
            email: responseData['email'] ?? email,
            hasCustomPassword: responseData['has_custom_password'] == true,
          );
          return FlowyResult.success(userAuthInfo);
        } else {
          return FlowyResult.failure(
            FlowyError(msg: 'Invalid response format from server'),
          );
        }
      } else {
        return FlowyResult.failure(
          FlowyError(
              msg: 'Failed to get user auth info: ${response.statusCode}'),
        );
      }
    } catch (e) {
      Log.error('PasswordCheckService: getUserAuthInfo error: $e');
      return FlowyResult.failure(
        FlowyError(msg: 'Network error: ${e.toString()}'),
      );
    }
  }
}

/// 用户认证信息
class UserAuthInfo {
  final bool exists;
  final String email;
  final bool hasCustomPassword;

  const UserAuthInfo({
    required this.exists,
    required this.email,
    required this.hasCustomPassword,
  });

  @override
  String toString() {
    return 'UserAuthInfo(exists: $exists, email: $email, hasCustomPassword: $hasCustomPassword)';
  }
}
