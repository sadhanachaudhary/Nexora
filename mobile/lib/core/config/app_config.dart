import 'package:flutter/foundation.dart';

class AppConfig {
  /// Live Render backend URL
  static const String _productionUrl = 'https://nexora-mtwu.onrender.com';

  /// Toggle between production and local development automatically
  static bool get isProduction => _productionUrl.isNotEmpty;

  /// Base API URL for Dio HTTP requests
  static String get baseUrl {
    if (isProduction) {
      return '$_productionUrl/api';
    }
    // Local dev: 10.0.2.2 for Android Emulator, 127.0.0.1 for Web, iOS, Windows, macOS
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001/api';
    }
    return 'http://127.0.0.1:3001/api';
  }

  /// Socket.io server connection URL
  static String get socketUrl {
    if (isProduction) {
      return _productionUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3001';
    }
    return 'http://127.0.0.1:3001';
  }
}
