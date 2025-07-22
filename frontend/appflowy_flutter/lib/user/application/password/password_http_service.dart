import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:http/http.dart' as http;

enum PasswordEndpoint {
  changePassword,
  forgotPassword,
  setupPassword,
  verifyResetPasswordToken;

  String get path {
    switch (this) {
      case PasswordEndpoint.changePassword:
        return '/gotrue/user/change-password';
      case PasswordEndpoint.forgotPassword:
        return '/gotrue/recover';
      case PasswordEndpoint.setupPassword:
        return '/gotrue/user/change-password';
      case PasswordEndpoint.verifyResetPasswordToken:
        return '/gotrue/verify';
    }
  }

  String get method {
    switch (this) {
      case PasswordEndpoint.changePassword:
      case PasswordEndpoint.setupPassword:
      case PasswordEndpoint.forgotPassword:
      case PasswordEndpoint.verifyResetPasswordToken:
        return 'POST';
    }
  }

  Uri uri(String baseUrl) => Uri.parse('$baseUrl$path');
}

class PasswordHttpService {
  PasswordHttpService({
    required this.baseUrl,
    required this.authToken,
  });

  final String baseUrl;

  String authToken;

  final http.Client client = http.Client();

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  /// Changes the user's password
  ///
  /// [currentPassword] - The user's current password
  /// [newPassword] - The new password to set
  Future<FlowyResult<bool, FlowyError>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.changePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
      },
      errorMessage: 'Failed to change password',
    );

    if (result.isSuccess) {
      // 标记用户设置了自定义密码
      await _markUserHasCustomPassword();
      return FlowyResult.success(true);
    } else {
      return result.fold(
        (data) => FlowyResult.success(true),
        (error) => FlowyResult.failure(error),
      );
    }
  }

  /// Sends a password reset email to the user
  ///
  /// [email] - The email address of the user
  Future<FlowyResult<bool, FlowyError>> forgotPassword({
    required String email,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.forgotPassword,
      body: {'email': email},
      errorMessage: 'Failed to send password reset email',
    );

    return result.fold(
      (data) => FlowyResult.success(true),
      (error) => FlowyResult.failure(error),
    );
  }

  /// Sets up a password for a user that doesn't have one
  ///
  /// [newPassword] - The new password to set
  Future<FlowyResult<bool, FlowyError>> setupPassword({
    required String newPassword,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.setupPassword,
      body: {'password': newPassword},
      errorMessage: 'Failed to setup password',
    );

    if (result.isSuccess) {
      // 标记用户设置了自定义密码
      await _markUserHasCustomPassword();
      return FlowyResult.success(true);
    } else {
      return result.fold(
        (data) => FlowyResult.success(true),
        (error) => FlowyResult.failure(error),
      );
    }
  }

  // Verify the reset password token
  Future<FlowyResult<String, FlowyError>> verifyResetPasswordToken({
    required String email,
    required String token,
  }) async {
    final result = await _makeRequest(
      endpoint: PasswordEndpoint.verifyResetPasswordToken,
      body: {
        'type': 'recovery',
        'email': email,
        'token': token,
      },
      errorMessage: 'Failed to verify reset password token',
    );

    try {
      return result.fold(
        (data) {
          final authToken = data['access_token'];
          return FlowyResult.success(authToken);
        },
        (error) => FlowyResult.failure(error),
      );
    } catch (e) {
      return FlowyResult.failure(
        FlowyError(msg: 'Failed to verify reset password token: $e'),
      );
    }
  }

  /// Makes a request to the specified endpoint with the given body
  Future<FlowyResult<dynamic, FlowyError>> _makeRequest({
    required PasswordEndpoint endpoint,
    Map<String, dynamic>? body,
    String errorMessage = 'Request failed',
  }) async {
    try {
      final uri = endpoint.uri(baseUrl);
      http.Response response;

      if (endpoint.method == 'POST') {
        response = await client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (endpoint.method == 'GET') {
        response = await client.get(
          uri,
          headers: headers,
        );
      } else {
        return FlowyResult.failure(
          FlowyError(msg: 'Invalid request method: ${endpoint.method}'),
        );
      }

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return FlowyResult.success(jsonDecode(response.body));
        }
        return FlowyResult.success(true);
      } else {
        final errorBody =
            response.body.isNotEmpty ? jsonDecode(response.body) : {};

        ErrorCode errorCode = ErrorCode.Internal;

        if (response.statusCode == 422) {
          errorCode = ErrorCode.NewPasswordTooWeak;
        }

        return FlowyResult.failure(
          FlowyError(
            code: errorCode,
            msg: errorBody['msg'] ?? errorMessage,
          ),
        );
      }
    } catch (e) {
      Log.error('${endpoint.name} request failed: error: $e');

      return FlowyResult.failure(
        FlowyError(msg: 'Network error: ${e.toString()}'),
      );
    }
  }

  /// 标记用户设置了自定义密码
  Future<void> _markUserHasCustomPassword() async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/mark-custom-password');
      final response = await client.post(
        uri,
        headers: headers,
      );

      if (response.statusCode != 200) {
        // 记录错误但不阻断流程
        Log.error(
            'Failed to mark user has custom password: ${response.statusCode}');
      }
    } catch (e) {
      // 记录错误但不阻断流程
      Log.error('Error marking user has custom password: $e');
    }
  }
}
