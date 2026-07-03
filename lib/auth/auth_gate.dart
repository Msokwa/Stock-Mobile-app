/*
Auth page will listen for auth state changes 
unauthenticated  -> login page
authenticated -> profile page
*/
import 'package:flutter/material.dart';
import 'package:stock_app/account.dart';
import 'package:stock_app/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;
        if (session != null) {
          return const Account();
        } else {
          return const Login();
        }
      },
    );
  }
}
