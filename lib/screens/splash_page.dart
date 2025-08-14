import 'package:flutter/material.dart';

const _sage = Color(0xFF9EB79E); // 改成 #9EB79E
const _sageDeep = Color(0xFF8EAA98);

class SplashPage extends StatelessWidget {
  static const route = '/';
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _sage,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 中間 Logo 圖片
              Image.asset(
                'lib/assets/logo.png', // 你的圖片路徑
                width: 160,
                height: 160,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 160,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _sageDeep,
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('登入'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('註冊'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
