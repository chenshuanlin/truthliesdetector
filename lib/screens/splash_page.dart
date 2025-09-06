import 'dart:async';

import 'package:flutter/material.dart';

// 📌 螢幕頁面
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';

// 📌 主題與元件
import 'package:truthliesdetector/themes/app_colors.dart';

class SplashPage extends StatefulWidget {
  static const route = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 3), () {
      // 導航到登入頁或首頁
      // todo: 檢查用戶是否已登入
      // 如果已登入，跳轉到 HomePage
      // 如果未登入，跳轉到 LoginPage
      Navigator.of(context).pushReplacementNamed(LoginPage.route); // ✅ 導航到登入頁面
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo2.png', // ✅ 修正圖片路徑
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
