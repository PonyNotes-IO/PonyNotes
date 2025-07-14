import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/password/password_check_service.dart'
    as password_check;
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show SignInPayloadPB, SignUpPayloadPB, UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:appflowy/env/cloud_env.dart';
import 'dart:async';

import '../../../generated/locale_keys.g.dart';
import 'device_id.dart';

class BackendAuthService implements AuthService {
  BackendAuthService(this.authType);

  final AuthTypePB authType;

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>>
      signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignInPayloadPB.create()
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();

    // 如果参数中包含手机号，则设置手机号字段
    if (params.containsKey('phone_number')) {
      request.phoneNumber = params['phone_number']!;
    }

    return UserEventSignInWithEmailPassword(request).send();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params = const {},
  }) async {
    final request = SignUpPayloadPB.create()
      ..name = name
      ..email = email
      ..password = password
      ..authType = authType
      ..deviceId = await getDeviceId();
    final response = await UserEventSignUp(request).send().then(
          (value) => value,
        );
    return response;
  }

  @override
  Future<void> signOut({
    Map<String, String> params = const {},
  }) async {
    await UserEventSignOut().send();
    return;
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpAsGuest({
    Map<String, String> params = const {},
  }) async {
    const password = "Guest!@123456";
    final userEmail = "anon@appflowy.io";

    final request = SignUpPayloadPB.create()
      ..name = LocaleKeys.defaultUsername.tr()
      ..email = userEmail
      ..password = password
      // When sign up as guest, the auth type is always local.
      ..authType = AuthTypePB.Local
      ..deviceId = await getDeviceId();
    final response = await UserEventSignUp(request).send().then(
          (value) => value,
        );
    return response;
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    AuthTypePB authType = AuthTypePB.Local,
    Map<String, String> params = const {},
  }) async {
    return FlowyResult.failure(
      FlowyError.create()
        ..code = ErrorCode.Internal
        ..msg = "Unsupported sign up action",
    );
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser() async {
    return UserBackendService.getCurrentUserProfile();
  }

  @override
  Future<FlowyResult<UserProfilePB, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params = const {},
  }) async {
    // No need to pass the redirect URL.
    return UserBackendService.signInWithMagicLink(email, '');
  }

  @override
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>> signInWithPasscode({
    required String email,
    required String passcode,
  }) async {
    return UserBackendService.signInWithPasscode(email, passcode);
  }

  @override
  Future<FlowyResult<bool, FlowyError>> checkUserExists({
    required String email,
  }) async {
    try {
      // 使用AppFlowy Cloud的API检查用户是否存在
      final client = http.Client();

      // 获取cloud服务的基础URL
      final baseUrl = await getAppFlowyCloudUrl();

      // 向 /api/user/auth-info 发送请求检查用户状态
      final uri = Uri.parse('$baseUrl/api/user/auth-info?email=$email');

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Request timeout while checking user status',
          const Duration(seconds: 10),
        ),
      );

      client.close();

      // 统一处理200状态码，通过响应数据判断用户是否有密码
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 正确访问嵌套的data字段中的has_custom_password
        final responseData = data['data'] as Map<String, dynamic>?;
        final hasPassword = responseData?['has_custom_password'] == true;

        return FlowyResult.success(hasPassword);
      }

      // 处理非200状态码（网络错误、服务器错误等）
      switch (response.statusCode) {
        case 400:
          // 请求参数错误
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final errorMsg =
                data['message'] ?? data['error'] ?? 'Invalid request';

            return FlowyResult.failure(
              FlowyError()..msg = 'Invalid email format or request: $errorMsg',
            );
          } catch (_) {
            return FlowyResult.failure(
              FlowyError()..msg = 'Invalid email format or request parameters',
            );
          }

        case 401:
        case 403:
          // 权限问题
          return FlowyResult.failure(
            FlowyError()..msg = 'Authentication required or access denied',
          );

        case 429:
          // 请求频率限制
          return FlowyResult.failure(
            FlowyError()..msg = 'Too many requests. Please try again later.',
          );

        case 500:
        case 502:
        case 503:
        case 504:
          // 服务器错误
          return FlowyResult.failure(
            FlowyError()..msg = 'Server error. Please try again later.',
          );

        default:
          // 其他未知状态码
          String errorMsg = 'Unknown error occurred';
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            errorMsg = data['message'] ?? data['error'] ?? errorMsg;
          } catch (_) {
            // 忽略JSON解析错误，使用默认错误消息
          }

          return FlowyResult.failure(
            FlowyError()
              ..msg =
                  'Failed to check user status (${response.statusCode}): $errorMsg',
          );
      }
    } on TimeoutException catch (e) {
      return FlowyResult.failure(
        FlowyError()
          ..msg = 'Request timeout. Please check your network connection.',
      );
    } on http.ClientException catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = 'Network connection error: ${e.message}',
      );
    } on FormatException catch (e) {
      return FlowyResult.failure(
        FlowyError()..msg = 'Invalid server response format: ${e.message}',
      );
    } catch (e) {
      // 捕获所有其他异常
      return FlowyResult.failure(
        FlowyError()..msg = 'Unexpected error while checking user: $e',
      );
    }
  }

  @override
  Future<FlowyResult<UserAuthInfo, FlowyError>> getUserAuthInfo({
    required String email,
  }) async {
    // 使用通用的密码检查服务
    final result =
        await password_check.PasswordCheckService.getUserAuthInfo(email: email);

    // 转换类型
    return result.fold(
      (passwordAuthInfo) => FlowyResult.success(UserAuthInfo(
        exists: passwordAuthInfo.exists,
        email: passwordAuthInfo.email,
        hasCustomPassword: passwordAuthInfo.hasCustomPassword,
      )),
      (error) => FlowyResult.failure(error),
    );
  }
}
