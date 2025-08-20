import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/register_page.dart';

class SplashPage extends StatelessWidget {
  static const route = '/';

  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF9EB79E), // 綠色背景
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'lib/assets/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 40),

            // 登入按鈕
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, LoginPage.route);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('登入'),
            ),

            const SizedBox(height: 12),

            // 註冊按鈕
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, RegisterPage.route);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('註冊'),
            ),
          ],
        ),
      ),
    );
  }
}
