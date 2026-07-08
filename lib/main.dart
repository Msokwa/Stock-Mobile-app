import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stock_app/services/env.dart';
import 'package:stock_app/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'finnhub.env');

  // Supabase setup
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseKey,
  );

  // final api = FinnhubService();
  // final quote = await api.getQuote("AAPL");
  // debugPrint("Apple price: \\${quote.currentPrice}");

  runApp(const StockScope());
}
  
final supabase = Supabase.instance.client;

class StockScope extends StatelessWidget {
  const StockScope({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF091625),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Splash(),
      theme: ThemeData(
        colorScheme: colorScheme,
        brightness: colorScheme.brightness,
        primaryColor: const Color(0xff091625),
        scaffoldBackgroundColor: const Color(0xFF091625),
        cardColor: const Color(0xFF091624),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFFD9D9D9),
            fontWeight: FontWeight.w500,
          ),
        ),
        useMaterial3: true,
      ),
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}
