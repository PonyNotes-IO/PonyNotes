import 'package:flutter/foundation.dart';

/// Error handler for AI chat related issues
class AIChatErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors that might cause mouse tracker issues
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is a mouse tracker assertion error
      if (details.exception.toString().contains('_debugDuringDeviceUpdate') ||
          details.exception.toString().contains('mouse_tracker.dart')) {
        // Log the error but don't crash the app
        debugPrint('Mouse tracker error caught and handled: ${details.exception}');
        return;
      }
      
      // For other errors, use the default handler
      FlutterError.presentError(details);
    };
  }
  
  static void handleMouseTrackerError(Object error, StackTrace stackTrace) {
    debugPrint('Mouse tracker error handled: $error');
    // Don't rethrow - just log and continue
  }
}

