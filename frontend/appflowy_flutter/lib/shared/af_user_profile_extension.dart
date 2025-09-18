import 'dart:convert';

import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';

extension UserProfilePBExtension on UserProfilePB {
  String? get authToken {
    // Check if token is empty or null before attempting to decode
    if (token.isEmpty) {
      Log.debug('Auth token is empty, returning null');
      return null;
    }
    
    try {
      final map = jsonDecode(token) as Map<String, dynamic>;
      return map['access_token'] as String?;
    } catch (e) {
      Log.error('Failed to decode auth token: $e');
      return null;
    }
  }
}
