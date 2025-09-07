import 'dart:async';
import 'package:flutter/material.dart';

// 📌 螢幕頁面
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/themes/app_colors.dart';

class SplashPage extends StatefulWidget {
  static const route = '/';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // 設定動畫控制器，讓動畫無限循環
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // 動畫持續時間為1秒
    );

    // 創建一個縮放動畫，使標誌有「脈動」效果
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 啟動動畫並使其重複播放，同時反向播放以創建來回效果
    _controller.repeat(reverse: true);

    // 設定定時器，3秒後導航到登入頁面
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(LoginPage.route);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientGreenStart,
              AppColors.gradientGreenEnd,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 使用縮放動畫讓圖片產生「脈動」效果
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'lib/assets/logo2.png',
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 40), // 在圖片和指示器之間增加一些間距
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
