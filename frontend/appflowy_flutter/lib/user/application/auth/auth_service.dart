import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class AuthServiceMapKeys {
  const AuthServiceMapKeys._();

  static const String email = 'email';
  static const String deviceId = 'device_id';
  static const String signInURL = 'sign_in_url';
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

/// `AuthService` is an abstract class that defines methods related to user authentication.
///
/// This service provides various methods for user sign-in, sign-up,
/// OAuth-based registration, and other related functionalities.
abstract class AuthService {
  /// Authenticates a user with their email and password.
  ///
  /// - `email`: The email address of the user.
  /// - `password`: The password of the user.
  /// - `params`: Additional parameters for authentication (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].

  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>>
      signInWithEmailPassword({
    required String email,
    required String password,
    Map<String, String> params,
  });

  /// Checks if a user exists by email
  ///
  /// - `email`: The email address to check
  ///
  /// Returns true if user exists (has account), false if new user
  Future<FlowyResult<bool, FlowyError>> checkUserExists({
    required String email,
  });

  /// Gets complete user authentication information
  ///
  /// - `email`: The email address to check
  ///
  /// Returns UserAuthInfo containing exists, email, and hasCustomPassword
  Future<FlowyResult<UserAuthInfo, FlowyError>> getUserAuthInfo({
    required String email,
  });

  /// Registers a new user with their name, email, and password.
  ///
  /// - `name`: The name of the user.
  /// - `email`: The email address of the user.
  /// - `password`: The password of the user.
  /// - `params`: Additional parameters for registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUp({
    required String name,
    required String email,
    required String password,
    Map<String, String> params,
  });

  /// Registers a new user with an OAuth platform.
  ///
  /// - `platform`: The OAuth platform name.
  /// - `params`: Additional parameters for OAuth registration (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpWithOAuth({
    required String platform,
    Map<String, String> params,
  });

  /// Registers a user as a guest.
  ///
  /// - `params`: Additional parameters for guest registration (optional).
  ///
  /// Returns a default [UserProfilePB].
  Future<FlowyResult<UserProfilePB, FlowyError>> signUpAsGuest({
    Map<String, String> params,
  });

  /// Authenticates a user with a magic link sent to their email.
  ///
  /// - `email`: The email address of the user.
  /// - `params`: Additional parameters for authentication with magic link (optional).
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<void, FlowyError>> signInWithMagicLink({
    required String email,
    Map<String, String> params,
  });

  /// Authenticates a user with a passcode sent to their email.
  ///
  /// - `email`: The email address of the user.
  /// - `passcode`: The passcode of the user.
  ///
  /// Returns [UserProfilePB] if the user is authenticated, otherwise returns [FlowyError].
  Future<FlowyResult<GotrueTokenResponsePB, FlowyError>> signInWithPasscode({
    required String email,
    required String passcode,
  });

  /// Signs out the currently authenticated user.
  Future<void> signOut();

  /// Retrieves the currently authenticated user's profile.
  ///
  /// Returns [UserProfilePB] if the user has signed in, otherwise returns [FlowyError].
  Future<FlowyResult<UserProfilePB, FlowyError>> getUser();
}
