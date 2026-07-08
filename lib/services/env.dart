import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // Test override for Marketstack key. Use `setMarketstackApiKeyForTest` in tests.
  static String? _overrideMarketstackApiKey;

  static void setMarketstackApiKeyForTest(String? key) {
    _overrideMarketstackApiKey = key;
  }

  static String get finnhubApiKey {
    final apiKey = dotenv.env['FINNHUB_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw StateError('FINNHUB_API_KEY is not set. Add it to finnhub.env.');
    }
    return apiKey;
  }

  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw StateError('SUPABASE_URL is not set. Add it to finnhub.env.');
    }
    return url;
  }

  static String get supabaseKey {
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY is not set. Add it to finnhub.env.',
      );
    }
    return key;
  }

  /// Marketstack API key (optional). Add `MARKETSTACK_API_KEY` to finnhub.env
  /// when you want to enable Marketstack-backed historical data.
  static String? get marketstackApiKey {
    if (_overrideMarketstackApiKey != null) return _overrideMarketstackApiKey;
    final key = dotenv.env['MARKETSTACK_API_KEY'];
    if (key == null || key.isEmpty) return null;
    return key;
  }
}
