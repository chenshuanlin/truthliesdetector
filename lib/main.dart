import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/splash_page.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/register_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';

const _sage = Color(0xFF9EB79E);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        chipTheme: ChipThemeData(
          selectedColor: _sage, // 選中 chip 綠底
          backgroundColor: Colors.white, // 未選中 chip 白底
          labelStyle: const TextStyle(
            color: Colors.black,
            fontSize: 14, // 避免中文字被裁切
            overflow: TextOverflow.visible,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          side: const BorderSide(color: _sage),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
      initialRoute: SplashPage.route,
      routes: {
        SplashPage.route: (context) => const SplashPage(),
        LoginPage.route: (context) => const LoginPage(),
        RegisterPage.route: (context) => const RegisterPage(),
        HomePage.route: (context) => const HomePage(),
        ProfilePage.route: (context) => const ProfilePage(),
      },
    );
  }
}
