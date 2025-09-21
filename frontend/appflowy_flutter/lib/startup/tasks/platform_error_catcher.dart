import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../startup.dart';

class PlatformErrorCatcherTask extends LaunchTask {
  const PlatformErrorCatcherTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    await super.initialize(context);

    // Handle platform errors not caught by Flutter.
    // Reduces the likelihood of the app crashing, and logs the error.
    // only active in non debug mode.
    if (!kDebugMode) {
      PlatformDispatcher.instance.onError = (error, stack) {
        Log.error('Uncaught platform error', error, stack);
        return true;
      };
    }

    ErrorWidget.builder = (details) {
      if (kDebugMode) {
        return Container(
          constraints: const BoxConstraints(
            minWidth: 100,
            maxWidth: 500,
            minHeight: 30,
            maxHeight: 60,
          ),
          color: Colors.red,
          padding: const EdgeInsets.all(4.0),
          child: Center(
            child: FlowyText(
              'ERROR: ${details.exceptionAsString()}',
              color: Colors.white,
              fontSize: 12,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      // hide the error widget in release mode
      return const SizedBox.shrink();
    };
  }
}
