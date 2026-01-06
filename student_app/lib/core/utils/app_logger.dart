import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// App-wide logger utility for consistent error and debug logging
class AppLogger {
  static const String _tag = 'StudentApp';

  /// Log debug information (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 500, // Fine level
      );
    }
  }

  /// Log info messages
  static void info(String message, {String? tag}) {
    developer.log(
      '✅ $message',
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    developer.log(
      '⚠️ $message',
      name: tag ?? _tag,
      level: 900, // Warning level
    );
  }

  /// Log error messages with optional exception and stack trace
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      '❌ $message',
      name: tag ?? _tag,
      level: 1000, // Severe level
      error: error,
      stackTrace: stackTrace,
    );
    
    // Also print to console for easier debugging
    if (kDebugMode) {
      print('[$_tag] ERROR: $message');
      if (error != null) print('  Exception: $error');
      if (stackTrace != null) print('  StackTrace: $stackTrace');
    }
  }

  /// Log API/Supabase errors with detailed information
  static void apiError(
    String operation,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final contextStr = context != null ? '\n  Context: $context' : '';
    AppLogger.error(
      'API Error in $operation$contextStr',
      error: error,
      stackTrace: stackTrace,
      tag: 'API',
    );
  }
}
