import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Splash1 extends StatelessWidget {
  const Splash1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF191625),
      body: Center(
        child: Container(
          color: const Color(0xFF191625),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 30, right: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: 'Scope',
                          style: const TextStyle(
                            color: Color(0xFF2BAB4A),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Track.',
                    style: TextStyle(
                      color: Color(0xFF9ECB9E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Analyze.',
                    style: TextStyle(
                      color: Color(0xFF9ECB9E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Grow.',
                    style: TextStyle(
                      color: Color(0xFF9ECB9E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Lottie.asset(
                    'assets/logo/Digital Finance Animation.json',
                    height: 220,
                    animate: true,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
