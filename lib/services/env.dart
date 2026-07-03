import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
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
}
