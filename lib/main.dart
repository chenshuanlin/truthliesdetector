import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/splash_page.dart';
import 'package:truthliesdetector/screens/login_page.dart';
import 'package:truthliesdetector/screens/register_page.dart';
import 'package:truthliesdetector/screens/home_page.dart';
import 'package:truthliesdetector/screens/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
