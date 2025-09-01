import 'package:flutter/material.dart';
import 'package:truthliesdetector/screens/search_page.dart';
import 'package:truthliesdetector/screens/settings_page.dart';
import 'package:truthliesdetector/screens/history_page.dart';
import 'package:truthliesdetector/screens/collect_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/collect', // 直接打開你想要的頁面
      routes: {
        '/search': (context) => const SearchPage(),
        '/settings': (context) => const SettingsPage(),
        '/history': (context) => const HistoryPage(),
        '/collect': (context) => const CollectPage(),
      },
    );
  }
}
